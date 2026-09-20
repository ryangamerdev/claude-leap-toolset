from pathlib import Path
p=Path('Sources/LeapCore/Engine+Recording.swift');s=p.read_text();s=s.replace('        let recorder=try AXRecording(store:store,app:s.displayName,pid:s.pid)','        boundProject=store.root\n        recordingSuppressed.remove(s.pid)\n        let recorder=try AXRecording(store:store,app:s.displayName,pid:s.pid)',1);s=s.replace('        r.stop()','        recordingSuppressed.insert(s.pid)\n        r.stop()',1);s=s.replace('if !recordings.values.contains(where:{$0.store.root==r.store.root}) {recordingStores[r.store.root]=nil}','if boundProject != r.store.root && !recordings.values.contains(where:{$0.store.root==r.store.root}) {recordingStores[r.store.root]=nil}')
s=s.replace('        let nodes:[[String:Any]]=snap.nodes.map { n in','        var ancestors:[(Int,String)]=[]\n        let nodes:[[String:Any]]=snap.nodes.map { n in\n            while let last=ancestors.last,last.0>=n.depth {ancestors.removeLast()}')
s=s.replace('d["label"]=n.title ?? n.description ?? n.placeholder ?? "";d["value"]=n.value;d["identifier"]=n.identifier','''d["label"]=n.title ?? n.description ?? n.placeholder ?? "";d["value"]=n.capturedValue ?? n.value;d["identifier"]=n.identifier
            d["index"]=s.indexByKey[n.key];d["valueLimited"]=n.valueLimited
            d["parentKey"]=ancestors.last?.1;d["ancestorKeys"]=ancestors.map{$0.1}
            ancestors.append((n.depth,n.key))''')
s=s.replace('"truncated":snap.truncated,"nodeCount"','"truncated":snap.truncated,"readFailures":snap.readFailures,"deadlineExceeded":snap.deadlineExceeded,"captureStarted":snap.captureStarted,"captureEnded":snap.captureEnded,"nodeCount"')
s=s.replace('        return "\\nRecording: session=', '        latestEvidence[s.pid]=Int(seq)\n        return "\\nRecording: session=',1)
s=s.replace('; query with recording_query(project: \\(r.store.root)).', '; inspect with ui_to_text(snapshot: \\(seq)) or recording_review(interaction_id: \\(recordingInteraction ?? "none")).')
s=s.replace('        if let explicit {return explicit}\n        guard', '        if let explicit {return explicit}\n        if let boundProject {return boundProject}\n        guard')
idx='    public func beginInteraction()'
new='''    public func bindProject(_ project:String) throws -> String {
        let root=RecordingStore.git(project,["rev-parse","--show-toplevel"]) ?? URL(fileURLWithPath:project).standardizedFileURL.path
        if let existing=boundProject,existing != root {throw LeapError.unsupported("Project already bound in this MCP session; restart to change binding without mixing evidence")}
        if recordingStores[root] == nil {recordingStores[root]=try RecordingStore(project:project)}
        boundProject=root
        return "Project bound. App observations/actions now retain evidence automatically. Query tools can omit project."
    }
    func autoRecord(_ s:AppSession) throws {
        guard let root=boundProject,recordings[s.pid]==nil,!recordingSuppressed.contains(s.pid),let store=recordingStores[root] else {return}
        let r=try AXRecording(store:store,app:s.displayName,pid:s.pid)
        r.setInteraction(recordingInteraction);recordings[s.pid]=r
        try store.append(session:r.id,interaction:recordingInteraction,kind:"session_start",payload:["app":s.displayName,"pid":s.pid,"automatic":true,"coverage":"supported AX notifications only"])
    }
    func compactObservation(_ text:String) -> String {
        var out:[String]=[];var used=0;var omitted=0
        for line in text.components(separatedBy:"\\n") {
            if line.contains("[disabled]") && !line.hasPrefix("~") {omitted+=1;continue}
            if used+line.utf8.count>10000 {omitted+=1;continue}
            out.append(line);used+=line.utf8.count+1
        }
        if omitted>0 {out.append("\\(omitted) lines omitted from this response; retained snapshot contains the captured controls. Use ui_to_text for filtered detail.")}
        return out.joined(separator:"\\n")
    }
    public func observeSnapshot(app:String,window:String?) async throws -> Int {
        _ = try await state(app:app,StateOptions(),window:window)
        let s=try await session(for:app)
        guard let id=latestEvidence[s.pid] else {throw LeapError.unsupported("Bind a project first to retain queryable UI evidence")}
        if let failure=recordings[s.pid]?.store.health(){throw LeapError.unsupported("Observation storage unavailable: \\(failure)")}
        return id
    }
'''
assert idx in s;s=s.replace(idx,new+idx);p.write_text(s)
p=Path('Sources/claude-leap/Tools.swift');s=p.read_text();marker='        Tool(name: "recording_review"'
new='''        Tool(name:"bind_project",description:"Bind the evidence project once. Subsequent app actions and observations automatically retain history; evidence tools can omit project. No UI input.",inputSchema:schema(["project":prop("string","Absolute project directory.")],required:["project"])),
        Tool(name:"ui_to_text",description:"Inspect a UI as compact structured JSON: fresh app observation or immutable snapshot. Filter roles, IDs, labels, states, subtree/depth and fields. Long strings become leapAsset references. Historical IDs require fresh validation before input. Bind a project first.",inputSchema:schema(["app":appProp,"window":prop("string","Optional window title for fresh observation."),"project":prop("string","Optional bound-project override for historical reads."),"snapshot":prop("integer","Historical snapshot; omit and supply app for a fresh observation."),"types":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"ids":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"fields":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"contains":prop("string","Label/value substring."),"root":prop("string","Subtree key from this snapshot."),"depth":prop("integer","Maximum rendered depth relative to root."),"enabled":prop("boolean","Filter enabled state."),"selected":prop("boolean","Filter selected state."),"visible":prop("boolean","Frame intersects window; not occlusion."),"after":prop("integer","Exclusive ordinal cursor."),"limit":prop("integer","Maximum 100 nodes; default 20."),"max_bytes":prop("integer","Item budget, 2048–32000; default 8000.")]),annotations:.init(readOnlyHint:true)),
        Tool(name:"leap_asset",description:"Retrieve retained content without escaped JSON blobs. info returns metadata; text returns a bounded plain-text chunk; file materializes exact captured text; auto chooses small text or file. References never fetch newer live values. Capture limits remain explicit.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"asset_id":prop("string","leapAsset.assetId from UI query."),"mode":prop("string","Default auto.",enumValues:["auto","info","text","file"]),"offset":prop("integer","Character offset for text chunks."),"limit":prop("integer","Characters, max 4000; default 2000.")],required:["asset_id"])),
        Tool(name:"ui_diff",description:"Compare two retained snapshots from the same app session/window title. Bounded added/changed/removed controls and changed field names; independent cursor, no live baseline consumption. Partial observations cannot prove disappearance.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"before":prop("integer","Earlier snapshot."),"after_snapshot":prop("integer","Later snapshot."),"after":prop("integer","Exclusive result cursor."),"limit":prop("integer","Default 20, maximum 100."),"max_bytes":prop("integer","Default 8000.")],required:["before","after_snapshot"]),annotations:.init(readOnlyHint:true)),
''';assert marker in s;s=s.replace(marker,new+marker,1)
marker='        case "recording_review":'
new='''        case "bind_project":
            guard let project=a.string("project") else {throw LeapError.unsupported("project required")}
            return try await engine.bindProject(project).result
        case "ui_to_text":
            let project=try await engine.recordingProject(a.string("project"))
            let snapshot:Int
            if let id=a.int("snapshot") {snapshot=id} else {snapshot=try await engine.observeSnapshot(app:try a.app(),window:a.string("window"))}
            return try Evidence(project:project).ui(snapshot:snapshot,types:a.strings("types"),ids:a.strings("ids"),fields:a.strings("fields"),contains:a.string("contains"),rootKey:a.string("root"),depth:a.int("depth"),enabled:a.bool("enabled"),selected:a.bool("selected"),visible:a.bool("visible"),after:a.int("after") ?? 0,limit:a.int("limit") ?? 20,maxBytes:a.int("max_bytes") ?? 8000).result
        case "leap_asset":
            guard let id=a.string("asset_id") else {throw LeapError.unsupported("asset_id required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).asset(id:id,mode:a.string("mode") ?? "auto",offset:a.int("offset") ?? 0,limit:a.int("limit") ?? 2000).result
        case "ui_diff":
            guard let before=a.int("before"),let after=a.int("after_snapshot") else {throw LeapError.unsupported("before and after_snapshot required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).diff(before:before,after:after,cursor:a.int("after") ?? 0,limit:a.int("limit") ?? 20,maxBytes:a.int("max_bytes") ?? 8000).result
''';assert marker in s;s=s.replace(marker,new+marker,1)
s=s.replace('    func string(_ k: String) -> String?', '    func strings(_ k:String)->[String] {raw[k]?.arrayValue?.compactMap{$0.stringValue} ?? []}\n    func string(_ k: String) -> String?',1)
p.write_text(s)
