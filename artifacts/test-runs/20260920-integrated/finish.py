from pathlib import Path
p=Path('Sources/LeapCore/AXTree.swift');s=p.read_text();s=s.replace('guard prepare(el) else {return nil}\n','guard prepare(el) else {return nil}\n        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}\n',1);s=s.replace('guard prepare(el) else {return [:]}\n','guard prepare(el) else {return [:]}\n        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}\n',1);s=s.replace('guard prepare(el) else {return []}\n','guard prepare(el) else {return []}\n        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}\n',1);s=s.replace('        var settable: DarwinBoolean = false\n        return AXUIElementIsAttributeSettable(el, name as CFString, &settable) == .success && settable.boolValue','''        guard prepare(el) else {return false}
        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}
        var settable: DarwinBoolean = false
        let result=AXUIElementIsAttributeSettable(el,name as CFString,&settable);note(result)
        return result == .success && settable.boolValue''');p.write_text(s)
p=Path('Sources/LeapCore/Evidence.swift');s=p.read_text();s=s.replace('for (field,value) in item {if let text=value as? String,text.utf8.count>256 {item[field]=Self.assetRef(snapshot:id,ordinal:ordinal,field:field,value:text)}}','''for (field,value) in item {
                if let text=value as? String,text.utf8.count>256 {item[field]=Self.assetRef(snapshot:id,ordinal:ordinal,field:field,value:text)}
                else if JSONSerialization.isValidJSONObject(value),let encoded=try? RecordingStore.json(value),encoded.utf8.count>512 {item[field]=Self.assetRef(snapshot:id,ordinal:ordinal,field:field,value:encoded)}
            }''');s=s.replace('guard ordinal<=nodes.count,let value=nodes[ordinal-1][parts[2]] as? String else {throw LeapError.unsupported("Captured asset unavailable")}','''guard ordinal<=nodes.count,let retained=nodes[ordinal-1][parts[2]] else {throw LeapError.unsupported("Captured asset unavailable")}
        let value:String
        if let text=retained as? String {value=text}
        else if JSONSerialization.isValidJSONObject(retained) {value=try RecordingStore.json(retained)}
        else {throw LeapError.unsupported("Not a retrievable text/object asset") }''');s=s.replace('||(am["readFailures"] as? Int ?? 0)>0','||(am["readFailures"] as? Int ?? 0)>0||(bm["deadlineExceeded"] as? Bool ?? false)||(am["deadlineExceeded"] as? Bool ?? false)')
idx='    public func diff('
new='''    public func interaction(_ id:String) throws -> String {
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
''';assert idx in s;s=s.replace(idx,new+idx,1);p.write_text(s)
p=Path('Sources/claude-leap/Tools.swift');s=p.read_text();s=s.replace('        Tool(name:"bind_project",','''        Tool(name:"interaction_result",description:"Explain one recorded interaction: joined input intent/acknowledgement, before/after check outcomes, observation references and uncertainty. Does not imply a persisted save from a current-state check. Details remain available through recording_review.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"interaction_id":prop("string","Interaction ID returned by an action.")],required:["interaction_id"]),annotations:.init(readOnlyHint:true)),
        Tool(name:"bind_project",''',1)
s=s.replace('        case "bind_project":','''        case "interaction_result":
            guard let id=a.string("interaction_id") else {throw LeapError.unsupported("interaction_id required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).interaction(id).result
        case "bind_project":''',1)
s=s.replace('else {snapshot=try await engine.observeSnapshot(app:try a.app(),window:a.string("window"))}','''else {
                let bound=try await engine.recordingProject(nil)
                guard project==bound else {throw LeapError.unsupported("Fresh UI evidence must use the bound project")}
                snapshot=try await engine.observeSnapshot(app:try a.app(),window:a.string("window"))
            }''',1)
p.write_text(s)
