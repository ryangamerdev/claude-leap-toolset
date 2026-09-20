import Foundation
import SQLite3

/// Read-only evidence access. Captured JSON is authoritative; files are optional materializations.
public final class Evidence {
    private var db: OpaquePointer?
    public let root: String
    public init(project:String) throws {
        guard project.hasPrefix("/") else {throw LeapError.unsupported("Project must be absolute")}
        root=RecordingStore.git(project,["rev-parse","--show-toplevel"]) ?? URL(fileURLWithPath:project).standardizedFileURL.path
        guard sqlite3_open_v2(root+"/.leap/leap.db",&db,SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX,nil)==SQLITE_OK else {
            sqlite3_close(db);db=nil;throw LeapError.unsupported("No readable evidence for project; bind/record first")
        }
        sqlite3_busy_timeout(db,1000)
    }
    deinit {sqlite3_close(db)}
    func rows(_ sql:String,_ args:[String]=[]) throws -> [[String:Any]] {
        var stmt:OpaquePointer?
        guard sqlite3_prepare_v2(db,sql,-1,&stmt,nil)==SQLITE_OK else {throw LeapError.unsupported("Evidence query unavailable")}
        defer {sqlite3_finalize(stmt)}
        for (i,a) in args.enumerated(){sqlite3_bind_text(stmt,Int32(i+1),a,-1,unsafeBitCast(-1,to:sqlite3_destructor_type.self))}
        var out:[[String:Any]]=[]
        while true {
            let rc=sqlite3_step(stmt);if rc==SQLITE_DONE {break};guard rc==SQLITE_ROW else {throw LeapError.unsupported("Evidence read failed")}
            var row:[String:Any]=[:]
            for i in 0..<sqlite3_column_count(stmt) {if let v=sqlite3_column_text(stmt,i){row[String(cString:sqlite3_column_name(stmt,i))]=String(cString:v)}}
            out.append(row)
        };return out
    }
    func snapshot(_ id:Int) throws -> ([String:Any],[[String:Any]]) {
        guard let row=try rows("SELECT session,interaction,payload FROM records WHERE seq=? AND kind='snapshot'",[String(id)]).first,
              let raw=row["payload"] as? String,let payload=try JSONSerialization.jsonObject(with:Data(raw.utf8)) as? [String:Any],let nodes=payload["nodes"] as? [[String:Any]] else {throw LeapError.unsupported("Snapshot not found")}
        var meta=payload;meta.removeValue(forKey:"nodes");meta["session"]=row["session"];meta["interaction"]=row["interaction"];meta["snapshot"]=id
        return(meta,nodes)
    }
    static func assetRef(snapshot:Int,ordinal:Int,field:String,value:String) -> [String:Any] {
        ["leapAsset":["assetId":"s\(snapshot):n\(ordinal):\(field)","mediaType":"text/plain; charset=utf-8","bytes":value.utf8.count,"characters":value.count,"preview":String(value.prefix(100)),"available":true]]
    }
    static func page(_ items:[[String:Any]], budget:Int, after:Int, cursor:String="ordinal") throws -> ([ [String:Any] ],Bool,Int) {
        let cap=max(2048,min(32000,budget));var kept:[[String:Any]]=[];var used=0
        for item in items {
            let bytes=try RecordingStore.json(item).utf8.count
            if used+bytes>cap {return(kept,true,kept.last?[cursor] as? Int ?? after)}
            kept.append(item);used+=bytes
        };return(kept,false,kept.last?[cursor] as? Int ?? after)
    }
    public func ui(snapshot id:Int,types:[String],ids:[String],fields:[String],contains:String?,rootKey:String?,depth:Int?,enabled:Bool?,selected:Bool?,visible:Bool?,after:Int,limit:Int,maxBytes:Int) throws -> String {
        let (meta,nodes)=try snapshot(id)
        let rootDepth=rootKey.flatMap {key in nodes.first(where:{$0["key"] as? String==key})?["depth"] as? Int} ?? 0
        if let rootKey, !nodes.contains(where:{$0["key"] as? String==rootKey}) {throw LeapError.unsupported("Root key not found in this snapshot")}
        func role(_ s:String)->String {s.lowercased().replacingOccurrences(of:"ax",with:"").replacingOccurrences(of:"_",with:"")}
        let defaultFields=["key","parentKey","role","label","value","enabled","selected","focused","offscreen","screenFrame","index","valueLimited"]
        let wanted=Set(fields.isEmpty ? defaultFields:fields)
        var matches:[[String:Any]]=[]
        for (i,n) in nodes.enumerated() {
            let ordinal=i+1;let key=n["key"] as? String ?? ""
            guard types.isEmpty || types.map(role).contains(role(n["role"] as? String ?? "")) else {continue}
            guard ids.isEmpty || ids.contains(key) || ids.contains(String(ordinal)) else {continue}
            if let rootKey,key != rootKey && !(n["ancestorKeys"] as? [String] ?? []).contains(rootKey) {continue}
            if let depth,(n["depth"] as? Int ?? 0)-rootDepth>max(0,depth){continue}
            if let enabled,n["enabled"] as? Bool != enabled {continue}
            if let selected,n["selected"] as? Bool != selected {continue}
            if let visible {if n["screenFrame"] == nil || (n["offscreen"] as? Bool ?? false) == visible {continue}}
            if let contains,!((n["label"] as? String ?? "")+" "+(n["value"] as? String ?? "")).localizedCaseInsensitiveContains(contains) {continue}
            var item=n.filter {wanted.contains($0.key)};item["ordinal"]=ordinal
            for (field,value) in item {
                if let text=value as? String,text.utf8.count>256 {item[field]=Self.assetRef(snapshot:id,ordinal:ordinal,field:field,value:text)}
                else if JSONSerialization.isValidJSONObject(value),let encoded=try? RecordingStore.json(value),encoded.utf8.count>512 {item[field]=Self.assetRef(snapshot:id,ordinal:ordinal,field:field,value:encoded)}
            }
            matches.append(item)
        }
        let candidates=matches.filter {($0["ordinal"] as? Int ?? 0)>after}
        let count=max(1,min(100,limit));let proposed=Array(candidates.prefix(count))
        let (page,cut,next)=try Self.page(proposed,budget:maxBytes,after:after)
        guard !page.isEmpty || proposed.isEmpty else {throw LeapError.unsupported("One node exceeds response budget; request fewer fields or increase max_bytes")}
        return try RecordingStore.json(["snapshot":meta,"historical":true,"coordinateSpace":"screen points, top-left origin; visibility is frame-based, not occlusion","matched":matches.count,"items":page,"hasMore":cut || candidates.count>page.count,"nextCursor":next,"next":"ui_to_text with same snapshot and filters, after=nextCursor; leap_asset for references","liveTargetWarning":"Historical indices/keys require fresh target validation before input"])
    }
    public func asset(id:String,mode:String,offset:Int,limit:Int) throws -> String {
        let parts=id.split(separator:":").map(String.init)
        guard parts.count==3,parts[0].hasPrefix("s"),parts[1].hasPrefix("n"),let snap=Int(parts[0].dropFirst()),let ordinal=Int(parts[1].dropFirst()),ordinal>0 else {throw LeapError.unsupported("Invalid asset reference")}
        let (meta,nodes)=try snapshot(snap)
        guard ordinal<=nodes.count,let retained=nodes[ordinal-1][parts[2]] else {throw LeapError.unsupported("Captured asset unavailable")}
        let value:String
        if let text=retained as? String {value=text}
        else if JSONSerialization.isValidJSONObject(retained) {value=try RecordingStore.json(retained)}
        else {throw LeapError.unsupported("Not a retrievable text/object asset") }
        let bytes=value.utf8.count
        if mode=="info" {return try RecordingStore.json(["assetId":id,"bytes":bytes,"characters":value.count,"mediaType":"text/plain","session":meta["session"] ?? "","captureLimited":nodes[ordinal-1]["valueLimited"] ?? false])}
        if mode=="file" || (mode=="auto" && bytes>8000) {
            guard let session=meta["session"] as? String,UUID(uuidString:session) != nil else {throw LeapError.unsupported("Invalid stored session identity")}
            let interaction=(meta["interaction"] as? String).flatMap{UUID(uuidString:$0)?.uuidString} ?? "observation"
            let directory=root+"/.leap/sessions/"+session+"/content/"+interaction
            try FileManager.default.createDirectory(atPath:directory,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
            // File name derives only from parsed numbers and a fixed extension, never a caller path.
            let fieldTag=Data(parts[2].utf8).base64EncodedString().replacingOccurrences(of:"/",with:"_")
            let file=directory+"/s\(snap)-n\(ordinal)-\(fieldTag).txt"
            try value.write(toFile:file,atomically:true,encoding:.utf8)
            return try RecordingStore.json(["assetId":id,"file":file,"bytes":bytes,"mediaType":"text/plain"])
        }
        guard ["auto","text"].contains(mode) else {throw LeapError.unsupported("mode must be auto, info, text or file")}
        let start=max(0,offset);let count=max(1,min(4000,limit));let chunk=String(value.dropFirst(start).prefix(count))
        return "Asset \(id) — characters \(start)..<\(start+chunk.count) of \(value.count); nextOffset=\(start+chunk.count); hasMore=\(start+chunk.count<value.count)\n"+chunk
    }
    public func interaction(_ id:String) throws -> String {
        // Never load raw tree payloads just to explain an interaction.
        let facts=try rows("SELECT seq,kind,payload FROM records WHERE interaction=? AND kind IN ('action_intent','action_result','expectation_result','capture_gap') ORDER BY seq LIMIT 201",[id])
        var actions:[String:[String:Any]]=[:];var order:[String]=[];var checks:[[String:Any]]=[];var gaps=0
        for row in facts.prefix(200) {
            guard let raw=row["payload"] as? String,let p=try JSONSerialization.jsonObject(with:Data(raw.utf8)) as? [String:Any] else {continue}
            let kind=row["kind"] as? String ?? ""
            if kind=="capture_gap" {gaps+=1}
            if kind=="expectation_result" {checks.append(["record":row["seq"] ?? "","phase":p["phase"] ?? "","outcome":p["outcome"] ?? "unknown","label":String((p["label"] as? String ?? "").prefix(160)),"condition":p["condition"] ?? ""])}
            if let action=p["actionId"] as? String {
                if actions[action]==nil {actions[action]=["actionId":action,"tool":p["tool"] ?? "","acknowledgement":"not recorded; dispatch unknown"];order.append(action)}
                if kind=="action_intent" {actions[action]?["intentRecord"]=row["seq"]}
                if kind=="action_result" {actions[action]?["resultRecord"]=row["seq"];actions[action]?["acknowledgement"]=p["apiOutcome"];actions[action]?["detail"]=String((p["result"] as? String ?? "").prefix(300))}
            }
        }
        let snapshots=try rows("SELECT MIN(seq) AS first,MAX(seq) AS last,COUNT(*) AS count FROM records WHERE interaction=? AND kind='snapshot'",[id])
        let post=checks.filter{$0["phase"] as? String=="after"}
        let outcome=facts.count>200 ? "unknown: review clipped" : post.isEmpty ? "not verified" : post.allSatisfy{$0["outcome"] as? String=="met"} ? "requested current-state checks met" : "requested checks not established"
        let result:[String:Any]=["interaction":id,"outcome":outcome,"actions":order.prefix(20).compactMap{actions[$0]},"checks":Array(checks.prefix(20)),"snapshots":snapshots,"captureGapRecords":gaps,"omitted":facts.count>200 || order.count>20 || checks.count>20,"meaning":"Current-state checks do not prove persistence or causation. Preserve API uncertainty; never replay merely because acknowledgement failed.","next":"recording_review(view: actions, interaction_id: this interaction) for all records; ui_diff for snapshot changes"]
        return try RecordingStore.json(result)
    }
    public func diff(before:Int,after:Int,cursor:Int,limit:Int,maxBytes:Int) throws -> String {
        let (bm,bn)=try snapshot(before);let(am,an)=try snapshot(after)
        guard bm["session"] as? String == am["session"] as? String,bm["window"] as? String == am["window"] as? String else {throw LeapError.unsupported("Snapshots must belong to the same recorded app session/window title; cross-process identity is not inferred")}
        var old:[String:[String:Any]]=[:];for n in bn {if let k=n["key"] as? String {old[k]=n}}
        var changes:[[String:Any]]=[]
        for (i,n) in an.enumerated() {
            guard let k=n["key"] as? String else {continue}
            let prior=old.removeValue(forKey:k)
            let fields=["label","value","enabled","selected","focused","offscreen","screenFrame"]
            let changed=fields.filter { field in
                let left=prior?[field] ?? NSNull(), right=n[field] ?? NSNull()
                let a=try? JSONSerialization.data(withJSONObject:[left],options:[.sortedKeys])
                let b=try? JSONSerialization.data(withJSONObject:[right],options:[.sortedKeys])
                return a != b
            }
            if prior == nil || !changed.isEmpty {
                var item:[String:Any]=["change":prior == nil ? "added":"changed","key":k,"fields":changed,"afterOrdinal":i+1,"label":String((n["label"] as? String ?? "").prefix(160))]
                if k.utf8.count>256 {item["key"]=Self.assetRef(snapshot:after,ordinal:i+1,field:"key",value:k)}
                changes.append(item)
            }
        }
        for k in old.keys.sorted(){changes.append(["change":"removed","key":String(k.prefix(256)),"keyShortened":k.count>256])}
        for i in changes.indices {changes[i]["ordinal"]=i+1}
        let candidates=changes.filter {($0["ordinal"] as? Int ?? 0)>cursor};let proposed=Array(candidates.prefix(max(1,min(100,limit))))
        let(page,cut,next)=try Self.page(proposed,budget:maxBytes,after:cursor)
        let partial=(bm["truncated"] as? Bool ?? false)||(am["truncated"] as? Bool ?? false)||(bm["readFailures"] as? Int ?? 0)>0||(am["readFailures"] as? Int ?? 0)>0||(bm["deadlineExceeded"] as? Bool ?? false)||(am["deadlineExceeded"] as? Bool ?? false)
        return try RecordingStore.json(["before":before,"after":after,"changes":page,"total":changes.count,"hasMore":cut || candidates.count>page.count,"nextCursor":next,"incomplete":partial,"meaning":"Observed differences, not causal proof. Removal from a partial tree does not prove disappearance. Content-based keys can change when labels change."])
    }
}
