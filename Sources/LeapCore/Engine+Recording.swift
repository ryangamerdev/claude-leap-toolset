import Foundation
import ApplicationServices

extension Engine {
    public func startRecording(app: String, project: String, window: String?) async throws -> String {
        try requireAX()
        let s=try await session(for:app)
        if let old=recordings[s.pid] { return "Already recording: session \(old.id), project \(old.store.root). Stop before rebinding." }
        let root=RecordingStore.git(project,["rev-parse","--show-toplevel"]) ?? URL(fileURLWithPath:project).standardizedFileURL.path
        let store:RecordingStore
        if let existing=recordingStores[root] {store=existing} else {store=try RecordingStore(project:project);recordingStores[store.root]=store}
        boundProject=store.root
        recordingSuppressed.remove(s.pid)
        let recorder=try AXRecording(store:store,app:s.displayName,pid:s.pid)
        recordings[s.pid]=recorder
        recorder.setInteraction(recordingInteraction)
        _ = try store.append(session:recorder.id,kind:"session_start",payload:["pid":s.pid,"app":s.displayName,"requestedWindow":window ?? "key window","capture":"supported AX notifications; snapshots at observations; not complete app history","subscriptionCandidateLimit":64,"warning":store.warning])
        let st=try await state(app:app,StateOptions(),window:window)
        return "Recording session \(recorder.id)\nProject: \(store.root)\nCapture continues between calls while this MCP process runs. Notifications contain receipt envelopes, not guaranteed historical values. \(store.warning)\n"+st.text
    }
    public func stopRecording(app:String) async throws -> String {
        let s=try await session(for:app,launch:false)
        guard let r=recordings.removeValue(forKey:s.pid) else{return "No active recording for this app"}
        recordingSuppressed.insert(s.pid)
        r.stop()
        if boundProject != r.store.root && !recordings.values.contains(where:{$0.store.root==r.store.root}) {recordingStores[r.store.root]=nil}
        return "Recording stopped: \(r.id). Historical records retained in \(r.store.root)/.leap/leap.db."
    }
    func recordSnapshot(_ snap:AXWindowSnapshot,session s:AppSession) throws -> String {
        guard let r=recordings[s.pid] else{return ""}
        r.subscribe(snap)
        var ancestors:[(Int,String)]=[]
        let nodes:[[String:Any]]=snap.nodes.map { n in
            while let last=ancestors.last,last.0>=n.depth {ancestors.removeLast()}
            var d:[String:Any]=["key":n.key,"role":n.role,"depth":n.depth,"enabled":n.enabled,"selected":n.selected,"focused":n.focused,"offscreen":n.offscreen,"actions":n.actions]
            d["label"]=n.title ?? n.description ?? n.placeholder ?? "";d["value"]=n.capturedValue ?? n.value;d["identifier"]=n.identifier
            d["index"]=s.indexByKey[n.key];d["valueLimited"]=n.valueLimited
            d["parentKey"]=ancestors.last?.1;d["ancestorKeys"]=ancestors.map{$0.1}
            ancestors.append((n.depth,n.key))
            if let f=n.frame {d["screenFrame"]=[f.minX,f.minY,f.width,f.height]}
            return d
        }
        let seq=try r.store.append(session:r.id,interaction:recordingInteraction,kind:"snapshot",payload:["window":snap.title ?? "","screenFrame":[snap.frame.minX,snap.frame.minY,snap.frame.width,snap.frame.height],"nodes":nodes,"truncated":snap.truncated,"retainedEarlierObservation":snap.retainedEarlierObservation,"readFailures":snap.readFailures,"advisoryReadFailures":snap.advisoryReadFailures,"blockingReadFailures":snap.blockingReadFailures,"batchReadRetries":snap.batchReadRetries,"batchReadRecoveries":snap.batchReadRecoveries,"readFailureDetails":snap.readFailureDetails,"readFailureDetailsOmitted":snap.readFailureDetailsOmitted,"deadlineExceeded":snap.deadlineExceeded,"captureStarted":snap.captureStarted,"captureEnded":snap.captureEnded,"nodeCount":nodes.count,"captureLimit":walker.maxNodes,"generation":s.generation,"source":"AX snapshot; attributes read over an interval, not atomic"])
        latestEvidence[s.pid]=Int(seq)
        return "\nRecording: session=\(r.id) snapshot=\(seq) coverage=\(snap.truncated || snap.readFailures>0 || snap.deadlineExceeded ? "partial" : "captured") interaction=\(recordingInteraction ?? "none"); inspect with ui_to_text(snapshot: \(seq)) or recording_review(interaction_id: \(recordingInteraction ?? "none"))."
    }
    public func beginRecordedAction(app:String,tool:String) async throws -> String? {
        let s=try await session(for:app)
        guard let r=recordings[s.pid] else{return nil}
        r.flush()
        if let failure=r.store.health(){throw LeapError.unsupported("Not dispatched: recording unavailable: \(failure)")}
        // Capture a fresh pre-action observation without consuming the agent's rendered diff baseline.
        let window=try await waitForWindow(s)
        if let snap=walker.snapshot(window:window,app:s.axApp){_ = try recordSnapshot(snap,session:s)}
        let action=UUID().uuidString
        try r.store.append(session:r.id,interaction:recordingInteraction,kind:"action_intent",payload:["actionId":action,"tool":tool,"dispatch":"not yet attempted","note":"An unfinished intent after disconnect has unknown dispatch; never replay automatically. Arguments omitted to avoid retaining secure input."])
        return action
    }
    public func endRecordedAction(app:String,action:String?,tool:String,message:String,error:Bool) async throws {
        guard let action else{return}
        let s=try await session(for:app,launch:false);guard let r=recordings[s.pid] else{return}
        try r.store.append(session:r.id,interaction:recordingInteraction,kind:"action_result",payload:["actionId":action,"tool":tool,"apiOutcome":error ? "error; inspect evidence" : "returned","dispatch":error ? "unknown; may have been sent" : "see operation result","result":message,"expectation":"not automatically verified by API success"])
    }
    public func recordCheck(app:String, phase:String, label:String, condition:String,
                            met:Bool, detail:String) async throws {
        let s=try await session(for:app,launch:false)
        guard let r=recordings[s.pid] else{return}
        do {
            try r.store.append(session:r.id,interaction:recordingInteraction,kind:"expectation_result",payload:[
                "phase":phase,"label":label,"condition":condition,
                "outcome":met ? "met" : (["unknown","unavailable","incomplete","ambiguous"].contains(where:{detail.lowercased().contains($0)}) ? "unknown" : "not_established"),"detail":detail,
                "scope":"current-state check, not causal proof or temporal event assertion"
            ])
        } catch {
            throw LeapError.unsupported("Expectation evidence could not be retained: \(error). Earlier input may already have been sent; do not replay it.")
        }
    }
    public func recordingProject(_ explicit:String?) throws -> String {
        if let explicit {return explicit}
        if let boundProject {return boundProject}
        guard recordingStores.count == 1, let root=recordingStores.keys.first else {
            throw LeapError.unsupported("Specify project, or start recording for one project first.")
        }
        return root
    }
    public func interactionResult() throws -> String? {
        guard let root=boundProject,let id=recordingInteraction else {return nil}
        let evidence=try Evidence(project:root)
        let summary=try evidence.interaction(id)
        guard var parsed=try JSONSerialization.jsonObject(with:Data(summary.utf8)) as? [String:Any],
              let actions=parsed["actions"] as? [[String:Any]], !actions.isEmpty else { return nil }
        let delta=try evidence.interactionDelta(id)
        parsed["observation"]=try JSONSerialization.jsonObject(with:Data(delta.utf8))
        return try RecordingStore.json(parsed)
    }
    public func bindProject(_ project:String) throws -> String {
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
        for line in text.components(separatedBy:"\n") {
            if line.contains("[disabled]") && !line.hasPrefix("~") {omitted+=1;continue}
            if used+line.utf8.count>10000 {omitted+=1;continue}
            out.append(line);used+=line.utf8.count+1
        }
        if omitted>0 {out.append("\(omitted) lines omitted from this response; retained snapshot contains the captured controls. Use ui_to_text for filtered detail.")}
        return out.joined(separator:"\n")
    }
    public func observeSnapshot(app:String,window:String?) async throws -> Int {
        _ = try await state(app:app,StateOptions(),window:window)
        let s=try await session(for:app)
        guard let id=latestEvidence[s.pid] else {throw LeapError.unsupported("Bind a project first to retain queryable UI evidence")}
        if let failure=recordings[s.pid]?.store.health(){throw LeapError.unsupported("Observation storage unavailable: \(failure)")}
        return id
    }
    public func beginInteraction() -> String {let id=UUID().uuidString;recordingInteraction=id;for r in recordings.values {r.setInteraction(id)};return id}
    public func endInteraction(){for r in recordings.values {r.flush();r.setInteraction(nil)};recordingInteraction=nil}
}
