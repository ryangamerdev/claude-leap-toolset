import Foundation
import AppKit
import ApplicationServices

extension Engine {
    static let macActions:Set<String> = ["click","double_click","type_text","set_value","press_key","scroll","drag","activate"]
    static let deviceActions:Set<String> = ["click","double_click","type_text","drag","scroll","press_key","rotate","activate"]

    /// Called within the server's serial operation boundary. All v2 tools share the same
    /// journal and selector/check implementation; adapters own only acquisition and input.
    public func automation(_ tool:String,json:String) async throws -> String {
        guard let args=try JSONSerialization.jsonObject(with:Data(json.utf8)) as? [String:Any] else {throw AutomationModel.fail("Arguments must be an object")}
        if tool == "target_list" {
            var targets:[[String:Any]]=AppResolver.listApps(includeInstalled:false).map { a in
                ["id":a.bundleId ?? a.name,"name":a.name,"backend":"mac_ax","pid":a.pid ?? 0,"foreground":a.isActive,"actions":Self.macActions.sorted(),"acceptance":"capabilities, not certification"]
            }
            let process=Process();process.executableURL=URL(fileURLWithPath:"/usr/bin/xcrun");process.arguments=["simctl","list","devices","available","--json"]
            let pipe=Pipe();process.standardOutput=pipe;process.standardError=FileHandle.nullDevice
            var warning:String?
            do {
                try process.run();let data=pipe.fileHandleForReading.readDataToEndOfFile();process.waitUntilExit()
                guard process.terminationStatus == 0 else {throw AutomationModel.fail("simctl unavailable")}
                let devices=(try JSONSerialization.jsonObject(with:data) as? [String:Any])?["devices"] as? [String:[[String:Any]]] ?? [:]
                for (runtime,items) in devices {for d in items {targets.append(["id":d["udid"] ?? "","name":d["name"] ?? "","state":d["state"] ?? "","runtime":runtime,"backend":"wda","readiness":"requires local WDA runner endpoint","actions":Self.deviceActions.sorted()])}}
            } catch {warning=String(describing:error)}
            return try RecordingStore.json(["schemaVersion":2,"targets":targets,"warning":warning ?? ""])
        }
        if tool == "evidence_read" {
            let e=try Evidence(project:recordingProject(args["project"] as? String))
            guard let id=args["session_id"] as? String,let seq=args["record"] as? Int,
                  let row=try e.rows("SELECT payload FROM records WHERE session=? AND seq=? AND kind LIKE 'automation_%'",[id,String(seq)]).first,
                  let payload=row["payload"] as? String else {throw AutomationModel.fail("Retained automation record not found")}
            var value:Any=try JSONSerialization.jsonObject(with:Data(payload.utf8))
            for key in args["path"] as? [String] ?? [] {
                if let obj=value as? [String:Any],let child=obj[key] {value=child}
                else if let arr=value as? [Any],let i=Int(key),arr.indices.contains(i) {value=arr[i]}
                else {throw AutomationModel.fail("Evidence path not found; use object keys or array indices")}
            }
            let raw:String
            if let text=value as? String {raw=text} else {
                raw=String(decoding:try JSONSerialization.data(withJSONObject:value,options:[.sortedKeys,.fragmentsAllowed]),as:UTF8.self)
            }
            let offset=max(0,args["offset"] as? Int ?? 0),limit=max(128,min(8000,args["max_bytes"] as? Int ?? 4000))
            var chunk=String(raw.dropFirst(offset).prefix(limit))
            while chunk.utf8.count>limit {chunk.removeLast()}
            return "Retained record \(seq), character offset \(offset), nextOffset=\(offset+chunk.count), hasMore=\(offset+chunk.count<raw.count)\n"+chunk
        }
        if tool == "session_history" {
            let evidence=try Evidence(project:recordingProject(args["project"] as? String))
            let kind=args["kind"] as? String ?? "automation_result"
            guard ["automation_session","automation_result","automation_step","automation_intent","automation_artifact"].contains(kind) else {throw AutomationModel.fail("Unsupported history kind")}
            let limit=max(1,min(20,args["limit"] as? Int ?? 10)),after=max(0,args["after"] as? Int ?? 0)
            var sql="SELECT seq,session,interaction,wall,kind,json_extract(payload,'$.execution') AS execution,json_extract(payload,'$.verification') AS verification FROM records WHERE seq>CAST(? AS INTEGER) AND kind=?"
            var values=[String(after),kind]
            if let id=args["session_id"] as? String {sql += " AND session=?";values.append(id)}
            sql += " ORDER BY seq LIMIT \(limit+1)"
            let rows=try evidence.rows(sql,values)
            let items=rows.prefix(limit).map {row -> [String:Any] in
                var r=row
                r["file"]=evidence.root+"/.leap/sessions/\(row["session"] ?? "")/\(row["seq"] ?? "")-\(kind.dropFirst(11)).json"
                return r
            }
            return try RecordingStore.json(["schemaVersion":2,"items":items,"hasMore":rows.count>limit,"nextCursor":Int(items.last?["seq"] as? String ?? "") ?? after])
        }
        if tool == "session_open" {
            guard let app=args["app"] as? String,!app.isEmpty,let project=args["project"] as? String else {throw AutomationModel.fail("session_open requires project and app")}
            let backend=args["backend"] as? String ?? "mac_ax"
            guard ["mac_ax","wda"].contains(backend) else {throw AutomationModel.fail("backend must be mac_ax or wda")}
            _ = try bindProject(project)
            guard let root=boundProject,let store=recordingStores[root] else {throw AutomationModel.fail("Project store unavailable")}
            let window=args["window"] as? String
            var pid:pid_t?,client:WDAClient?
            if backend == "mac_ax" {
                let native=try await session(for:app);pid=native.pid
            } else {
                guard let endpoint=args["endpoint"] as? String else {throw AutomationModel.fail("WDA requires endpoint from scripts/wda.py; no implicit host-AX fallback")}
                guard !automationSessions.values.contains(where:{$0.wda?.endpoint.absoluteString == endpoint}) else {throw AutomationModel.fail("WDA endpoint already owned by a Leap session")}
                client=try WDAClient(endpoint:endpoint)
            }
            let id=try store.attach(app:app,pid:pid ?? 0)
            let s=AutomationSession(id:id,app:app,backend:backend,window:window,store:store,pid:pid)
            s.wda=client
            _ = try s.save("session",["backend":backend,"app":app,"window":window ?? "","endpoint":args["endpoint"] ?? "","lifecycle":"opening; WDA may launch/activate guest app, no reset"],interaction:recordingInteraction)
            do {
                if let client {try await client.open(app:app)}
                automationSessions[id]=s
                let snap=try await automationObserve(s)
                return try RecordingStore.json(["schemaVersion":2,"session_id":id,"backend":backend,"app":app,"snapshot":snap["snapshot"]!,"file":snap["file"]!,"actions":(backend == "mac_ax" ? Self.macActions:Self.deviceActions).sorted(),"next":"ui_observe(session_id) or ui_perform(session_id, steps)","restart":"Live handles expire at MCP restart; history remains; open a new live session"])
            } catch {
                automationSessions[id]=nil
                _ = try? s.save("open_failed",["error":String(describing:error),"lifecycle":"Guest launch/activation may have occurred"],interaction:recordingInteraction)
                try? store.finish(id)
                throw error
            }
        }
        guard let id=args["session_id"] as? String else {throw AutomationModel.fail("session_id required")}
        // Historical snapshot retrieval works after restart without reviving live handles.
        if tool == "ui_observe",let seq=args["snapshot"] as? Int {
            let root=try recordingProject(args["project"] as? String)
            let e=try Evidence(project:root)
            guard let row=try e.rows("SELECT payload FROM records WHERE seq=? AND session=? AND kind='automation_snapshot'",[String(seq),id]).first,
                  let payload=row["payload"] as? String,
                  var snapshot=try JSONSerialization.jsonObject(with:Data(payload.utf8)) as? [String:Any] else {throw AutomationModel.fail("Snapshot not found in session")}
            snapshot["snapshot"]=seq;snapshot["file"]=root+"/.leap/sessions/\(id)/\(seq)-snapshot.json"
            return try automationPage(snapshot,args:args)
        }
        guard let s=automationSessions[id] else {throw AutomationModel.fail("Live session unavailable or expired after restart; open a new session. Retained snapshots/history remain readable.")}
        switch tool {
        case "session_close":
            try s.store.finish(s.id);automationSessions[id]=nil
            // Do not DELETE WDA session: external backend lifecycle can terminate guest apps.
            return try RecordingStore.json(["schemaVersion":2,"session_id":id,"closed":true,"applicationTerminated":false])
        case "ui_observe":return try automationPage(try await automationObserve(s),args:args)
        case "ui_perform":return try await automationPerform(s,args:args)
        default:throw AutomationModel.fail("Unknown automation tool")
        }
    }

    func automationObserve(_ s:AutomationSession) async throws -> [String:Any] {
        let started=ISO8601DateFormatter().string(from:Date())
        var observation:[String:Any]
        if let wda=s.wda {observation=try await wda.observe()}
        else {
            let native=try await session(for:s.app,launch:false)
            guard native.pid == s.pid else {throw AutomationModel.fail("Target process changed; open a new session")}
            _ = try await state(app:s.app,window:s.window)
            guard let snap=native.automationSnapshot else {throw AutomationModel.fail("AX snapshot unavailable")}
            if let identity=s.windowIdentity,!CFEqual(identity,snap.window) {throw AutomationModel.fail("Selected window changed; open a new explicitly targeted session")}
            s.windowIdentity=snap.window
            if s.window == nil {s.window=snap.title}
            var ancestors:[(Int,String)]=[]
            let nodes:[[String:Any]]=snap.nodes.map {n in
                while let last=ancestors.last,last.0>=n.depth {ancestors.removeLast()}
                var node:[String:Any]=["id":n.key,"role":n.role,"label":n.title ?? n.description ?? n.placeholder ?? "","enabled":n.enabled,"selected":n.selected,"focused":n.focused,"offscreen":n.offscreen,"depth":n.depth,"ancestors":ancestors.map{$0.1},"actions":n.actions,"valueLimited":n.valueLimited]
                node["identifier"]=n.identifier;node["value"]=n.capturedValue ?? n.value;node["index"]=native.indexByKey[n.key]
                if let f=n.frame {node["frame"]=[f.minX-snap.frame.minX,f.minY-snap.frame.minY,f.width,f.height]}
                ancestors.append((n.depth,n.key));return node
            }
            observation=["nodes":nodes,"complete":snap.supportsStateChecks && !snap.retainedEarlierObservation,"coordinateSpace":"window_points","bounds":[snap.frame.minX,snap.frame.minY,snap.frame.width,snap.frame.height],"window":snap.title ?? "","pid":native.pid,"blockingReadFailures":snap.blockingReadFailures,"advisoryReadFailures":snap.advisoryReadFailures,"limitations":["AX acquisition is not atomic; frame intersection is not occlusion","Simulator host AX geometry can be invalid; prefer device backend"]]
        }
        observation["schemaVersion"]=2;observation["session_id"]=s.id;observation["backend"]=s.backend
        observation["started_at"]=started;observation["finished_at"]=ISO8601DateFormatter().string(from:Date())
        let (seq,file)=try s.save("snapshot",observation,interaction:recordingInteraction)
        observation["snapshot"]=seq;observation["file"]=file;s.latest=observation
        return observation
    }

    func automationPage(_ snapshot:[String:Any],args:[String:Any]) throws -> String {
        let selector=AutomationModel.object(args["selector"]);try AutomationModel.validateSelector(selector)
        let nodes=snapshot["nodes"] as? [[String:Any]] ?? []
        let rootDepth=nodes.first { $0["id"] as? String == selector["root"] as? String }?["depth"] as? Int ?? 0
        let all=nodes.filter {node in
            AutomationModel.matches(node,selector) && (args["depth"] as? Int).map { (node["depth"] as? Int ?? 0)-rootDepth <= max(0,$0) } != false
        }
        let after=max(0,args["after"] as? Int ?? 0), limit=max(1,min(100,args["limit"] as? Int ?? 20))
        let budget=max(2048,min(32000,args["max_bytes"] as? Int ?? 10000))
        let fields=args["fields"] as? [String] ?? ["id","role","label","identifier","value","enabled","selected","frame"]
        var result=snapshot.filter{$0.key != "nodes"}
        result["matched"]=all.count;result["historical"]=args["snapshot"] != nil
        var items:[[String:Any]]=[]
        for node in all.dropFirst(after).prefix(limit) {
            var item=node.filter{fields.contains($0.key)}
            for (key,value) in item {if let text=value as? String,text.utf8.count>512 {item[key]=["preview":String(text.prefix(100)),"retained":snapshot["file"] ?? "","node":node["id"] ?? "","field":key]}}
            items.append(item)
            result["items"]=items;result["nextCursor"]=after+items.count;result["hasMore"]=after+items.count<all.count
            if try RecordingStore.json(result).utf8.count>budget {items.removeLast();break}
        }
        result["items"]=items;result["nextCursor"]=after+items.count;result["hasMore"]=after+items.count<all.count
        if items.isEmpty && after<all.count {throw AutomationModel.fail("One node exceeds budget; request fewer fields or larger max_bytes. Full snapshot: \(snapshot["file"] ?? "")")}
        return try AutomationModel.bounded(result,budget:budget,file:snapshot["file"] as? String ?? "")
    }

    func automationCheck(_ s:AutomationSession,expectation:[String:Any],timeout:Double) async throws -> (String,[String:Any]) {
        let end=ProcessInfo.processInfo.systemUptime+max(0,timeout)
        while true {
            let snap=try await automationObserve(s)
            let verdict=AutomationModel.verdict(nodes:snap["nodes"] as? [[String:Any]] ?? [],complete:snap["complete"] as? Bool == true,expectation:expectation)
            if verdict == "passed" || ProcessInfo.processInfo.systemUptime>=end {return(verdict,snap)}
            try await Task.sleep(nanoseconds:200_000_000)
        }
    }

    func automationCapture(_ s:AutomationSession) async throws -> [String:Any] {
        let path=s.store.root+"/.leap/sessions/"+s.id+"/"+UUID().uuidString+".png"
        let data:Data
        var meta:[String:Any]=["file":path,"type":"screenshot","session_id":s.id,"snapshot":s.latest?["snapshot"] ?? NSNull()]
        if let wda=s.wda {data=try await wda.screenshot();meta["coordinateSpace"]="device_screenshot_pixels"}
        else {let shot=try await screenshot(app:s.app,png:true,window:s.window);data=shot.data;meta["pointsPerPixel"]=shot.pointsPerPixel;meta["width"]=shot.pixelWidth;meta["height"]=shot.pixelHeight;meta["coordinateSpace"]="window_screenshot_pixels"}
        try data.write(to:URL(fileURLWithPath:path),options:.atomic)
        meta["bytes"]=data.count
        _ = try s.save("artifact",meta,interaction:recordingInteraction)
        return meta
    }

    func automationPerform(_ s:AutomationSession,args:[String:Any]) async throws -> String {
        guard let steps=args["steps"] as? [[String:Any]],!steps.isEmpty,steps.count<=50 else {throw AutomationModel.fail("steps must contain 1–50 objects")}
        // Validate every step before any input. Backend-specific capabilities are explicit.
        let allowed=s.backend == "mac_ax" ? Self.macActions:Self.deviceActions
        for step in steps {
            guard Set(step.keys).isSubset(of:["id","type","action","selector","arguments","before","expect","timeout"]) else {throw AutomationModel.fail("Unknown step field; no input sent")}
            if let raw=step["selector"],!(raw is [String:Any]) {throw AutomationModel.fail("Selector must be object")}
            if let raw=step["arguments"],!(raw is [String:Any]) {throw AutomationModel.fail("Arguments must be object")}
            guard let type=step["type"] as? String,["action","assert","wait","observe","capture"].contains(type) else {throw AutomationModel.fail("Invalid step type")}
            if let selector=step["selector"] as? [String:Any] {try AutomationModel.validateSelector(selector)}
            for key in ["before","expect"] {if let value=step[key] {guard let e=value as? [String:Any] else {throw AutomationModel.fail("Expectation must be object")};try AutomationModel.validateExpectation(e)}}
            if ["assert","wait"].contains(type),step["expect"] == nil {throw AutomationModel.fail("assert/wait requires expect")}
            if type == "action" {
                guard let action=step["action"] as? String,allowed.contains(action) else {throw AutomationModel.fail("Unsupported action for \(s.backend); no steps sent")}
                let a=AutomationModel.object(step["arguments"])
                var keys:Set<String>
                switch action {
                case "click","double_click": keys=["x","y","snapshot","space"]
                case "drag":keys=["from_x","from_y","to_x","to_y","snapshot","space"]
                case "type_text","set_value":keys=["text"]
                case "press_key":keys=["key"]
                case "scroll":keys=["direction"]
                case "rotate":keys=["orientation"]
                default:keys=[]
                }
                if s.backend == "mac_ax" {
                    keys.insert("foreground")
                    if ["click","double_click","drag"].contains(action) {keys.insert("modifiers")}
                    if ["click","double_click"].contains(action) {keys.insert("button")}
                    if action == "scroll" {keys.formUnion(["pages","x","y","snapshot","space"])}
                }
                guard Set(a.keys).isSubset(of:keys) else {throw AutomationModel.fail("Unsupported arguments for \(s.backend) \(action); no input sent")}
                for (key,value) in a {
                    if ["x","y","from_x","from_y","to_x","to_y","snapshot","pages"].contains(key) {
                        guard let number=value as? NSNumber,CFGetTypeID(number) != CFBooleanGetTypeID(),number.doubleValue.isFinite else {throw AutomationModel.fail("\(key) must be a finite number")}
                    } else if key == "foreground" {
                        guard let number=value as? NSNumber,CFGetTypeID(number) == CFBooleanGetTypeID() else {throw AutomationModel.fail("foreground must be boolean")}
                    } else if !(value is String) {throw AutomationModel.fail("\(key) must be a string")}
                }
                if let button=a["button"] as? String,MouseButton(alias:button) == nil {throw AutomationModel.fail("Invalid mouse button")}
                if s.backend == "wda",action == "press_key",!["Return","Enter","Backspace","Tab"].contains(a["key"] as? String ?? "") {throw AutomationModel.fail("Unsupported device key; no steps sent")}
                if ["type_text","set_value"].contains(action),!(a["text"] is String) {throw AutomationModel.fail("Text action needs arguments.text")}
                if action == "scroll", !["up","down","left","right"].contains(a["direction"] as? String ?? "") {throw AutomationModel.fail("Scroll needs valid direction")}
                if action == "scroll",step["selector"] == nil, !(s.backend == "mac_ax" && a["x"] is NSNumber && a["y"] is NSNumber) {throw AutomationModel.fail("Scroll requires selector or Mac x/y with snapshot and space")}
                if action == "rotate", !["PORTRAIT","PORTRAIT_UPSIDEDOWN","LANDSCAPE","LANDSCAPE_RIGHT"].contains(a["orientation"] as? String ?? "") {throw AutomationModel.fail("Invalid orientation")}
                if action == "press_key",!(a["key"] is String) {throw AutomationModel.fail("press_key needs arguments.key")}
                if ["type_text","set_value"].contains(action),step["selector"] == nil {throw AutomationModel.fail("Text actions require selector")}
                if ["click","double_click"].contains(action),step["selector"] == nil,!(a["x"] is NSNumber && a["y"] is NSNumber) {throw AutomationModel.fail("Click needs selector or x/y")}
                if action == "drag", !["from_x","from_y","to_x","to_y"].allSatisfy({a[$0] is NSNumber}) {throw AutomationModel.fail("Drag needs from_x/from_y/to_x/to_y")}
            }
        }
        if let expected=args["expected_snapshot"] as? Int,expected != s.latest?["snapshot"] as? Int {throw AutomationModel.fail("Expected snapshot is no longer current; observe before acting")}
        let interaction=recordingInteraction ?? UUID().uuidString
        let started=ProcessInfo.processInfo.systemUptime
        let deadline=started+min(120,max(0.1,args["timeout"] as? Double ?? 60))
        var results:[[String:Any]]=[], stopped=false,overall="passed"
        for (i,step) in steps.enumerated() {
            var r:[String:Any]=["id":step["id"] ?? String(i),"index":i,"type":step["type"]!,"dispatch":"not_sent","verification":"not_evaluated","started_at":ISO8601DateFormatter().string(from:Date())]
            if stopped {r["execution"]="skipped";results.append(r);continue}
            var attempted=false
            do {
                guard ProcessInfo.processInfo.systemUptime<deadline else {throw AutomationModel.fail("Workflow scheduling deadline exceeded")}
                if let health=s.store.health() {throw AutomationModel.fail("Recording unavailable: \(health)")}
                let type=step["type"] as! String
                var pre=try await automationObserve(s)
                r["before_snapshot"]=pre["snapshot"]
                if let before=step["before"] as? [String:Any] {
                    let (v,snap)=try await automationCheck(s,expectation:before,timeout:min(5,max(0,deadline-ProcessInfo.processInfo.systemUptime)))
                    pre=snap;r["precondition"]=v
                    guard v == "passed" else {r["verification"]=v;throw AutomationModel.fail("Precondition not established; no input sent")}
                }
                if type == "action" {
                    let action=step["action"] as! String,a=AutomationModel.object(step["arguments"])
                    r["before_snapshot"]=pre["snapshot"]
                    let nodes=pre["nodes"] as? [[String:Any]] ?? []
                    var node:[String:Any]?
                    if let selector=step["selector"] as? [String:Any] {
                        let hits=nodes.filter{AutomationModel.matches($0,selector)}
                        guard pre["complete"] as? Bool == true,hits.count==1 else {throw AutomationModel.fail("Selector missing/ambiguous or observation incomplete; no input sent")}
                        node=hits[0]
                        guard node?["enabled"] as? Bool != false else {throw AutomationModel.fail("Target disabled; no input sent")}
                    }
                    if action == "drag" || (["click","double_click","scroll"].contains(action) && node == nil) {
                        guard let baseline=a["snapshot"] as? Int,let prior=try automationStoredSnapshot(s,seq:baseline),
                              prior["coordinateSpace"] as? String == a["space"] as? String,
                              prior["coordinateSpace"] as? String == pre["coordinateSpace"] as? String,
                              AutomationModel.sameOrientation(prior,pre),
                              AutomationModel.sameBounds(prior["bounds"],pre["bounds"]),
                              try RecordingStore.json(prior["nodes"] ?? []) == RecordingStore.json(pre["nodes"] ?? []),
                              prior["window"] as? String == pre["window"] as? String else {throw AutomationModel.fail("Coordinates require snapshot and space with unchanged target bounds; no input sent")}
                        let b=pre["bounds"] as? [Double] ?? []
                        guard b.count==4 else {throw AutomationModel.fail("Coordinate bounds unavailable")}
                        let pairs=action == "drag" ? [("from_x","from_y"),("to_x","to_y")]:[("x","y")]
                        for (x,y) in pairs {guard let px=a[x] as? Double,let py=a[y] as? Double,px.isFinite,py.isFinite,px>=0,py>=0,px<b[2],py<b[3] else {throw AutomationModel.fail("Coordinate outside target bounds")}}
                    }
                    _ = try s.save("intent",["step":i,"action":action,"dispatch":"not_sent","arguments":"omitted","snapshot":pre["snapshot"]!],interaction:interaction)
                    guard Diagnostics.shared.record(level:"info",kind:"automation_input_attempt",detail:"\(s.backend) \(action) step \(i)") != nil else {throw AutomationModel.fail("Diagnostics unavailable; no input sent")}
                    attempted=true;r["dispatch"]="attempted"
                    try await automationInput(s,action:action,node:node,args:a)
                    r["acknowledgement"]="returned"
                }
                var post=pre
                if let expectation=step["expect"] as? [String:Any] {
                    let wait=type == "assert" ? 0:min(30,max(0,step["timeout"] as? Double ?? 5))
                    let (v,snap)=try await automationCheck(s,expectation:expectation,timeout:min(wait,max(0,deadline-ProcessInfo.processInfo.systemUptime)))
                    post=snap;r["verification"]=v
                    if v != "passed" {stopped=true;overall=v}
                } else if type == "action" {post=try await automationObserve(s)}
                if type == "capture" {r["artifact"]=try await automationCapture(s)}
                r["after_snapshot"]=post["snapshot"]
                r["delta"]=AutomationModel.delta(pre["nodes"] as? [[String:Any]] ?? [],post["nodes"] as? [[String:Any]] ?? [],complete:pre["complete"] as? Bool == true && post["complete"] as? Bool == true)
                r["execution"]="completed"
            } catch {
                stopped=true;overall="unknown";r["execution"]="failed";r["error"]=String(describing:error)
                if attempted {r["dispatch"]="uncertain"}
                if r["verification"] as? String == "not_evaluated" {r["verification"]="unknown"}
                Diagnostics.shared.record(level:"error",kind:"automation_step_failed",detail:String(describing:error))
                do {
                    let post=try await automationObserve(s);r["after_snapshot"]=post["snapshot"]
                    if attempted,let expectation=step["expect"] as? [String:Any] {
                        r["verification"]=AutomationModel.verdict(nodes:post["nodes"] as? [[String:Any]] ?? [],complete:post["complete"] as? Bool == true,expectation:expectation)
                    }
                } catch {r["observation_error"]=String(describing:error)}
            }
            if stopped {do {r["failure_artifact"]=try await automationCapture(s)} catch {r["capture_error"]=String(describing:error)}}
            r["finished_at"]=ISO8601DateFormatter().string(from:Date())
            _ = try s.save("step",r,interaction:interaction)
            results.append(r)
        }
        let hasAssertions=results.contains{$0["verification"] as? String != "not_evaluated"}
        let result:[String:Any]=["schemaVersion":2,"session_id":s.id,"interaction_id":interaction,"execution":stopped ? "stopped":"completed","verification":hasAssertions ? overall:"not_evaluated","steps":results,"duration_ms":Int((ProcessInfo.processInfo.systemUptime-started)*1000),"inputReplay":"never","deadlineOverrun":ProcessInfo.processInfo.systemUptime>deadline]
        let (_,file)=try s.save("result",result,interaction:interaction)
        return try AutomationModel.bounded(result,budget:16000,file:file)
    }

    func automationStoredSnapshot(_ s:AutomationSession,seq:Int) throws -> [String:Any]? {
        let e=try Evidence(project:s.store.root)
        guard let row=try e.rows("SELECT payload FROM records WHERE seq=? AND session=? AND kind='automation_snapshot'",[String(seq),s.id]).first,let payload=row["payload"] as? String else {return nil}
        return try JSONSerialization.jsonObject(with:Data(payload.utf8)) as? [String:Any]
    }

    func automationInput(_ s:AutomationSession,action:String,node:[String:Any]?,args:[String:Any]) async throws {
        if let wda=s.wda {var a=args;a["app"]=s.app;try await wda.action(action,node:node,args:a);return}
        let index=node?["index"] as? Int
        let target=Target(elementIndex:index,x:(args["x"] as? Double).map { CGFloat($0) },y:(args["y"] as? Double).map { CGFloat($0) })
        let mode=InputMode(foreground:args["foreground"] as? Bool ?? false)
        switch action {
        case "click","double_click":_ = try await click(app:s.app,target:target,button:MouseButton(alias:args["button"] as? String ?? "left") ?? .left,count:action == "double_click" ? 2:1,modifiers:args["modifiers"] as? String,mode:mode)
        case "type_text":_ = try await typeText(app:s.app,text:args["text"] as? String ?? "",elementIndex:index,mode:mode)
        case "set_value":guard let index else {throw AutomationModel.fail("set_value requires selector")};_ = try await setValue(app:s.app,elementIndex:index,value:args["text"] as? String ?? "",mode:mode)
        case "press_key":_ = try await pressKey(app:s.app,key:args["key"] as? String ?? "",mode:mode)
        case "scroll":_ = try await scroll(app:s.app,target:target,direction:args["direction"] as? String ?? "down",pages:args["pages"] as? Double ?? 1,mode:mode)
        case "drag":_ = try await drag(app:s.app,from:Target(x:(args["from_x"] as? Double).map { CGFloat($0) },y:(args["from_y"] as? Double).map { CGFloat($0) }),to:Target(x:(args["to_x"] as? Double).map { CGFloat($0) },y:(args["to_y"] as? Double).map { CGFloat($0) }),modifiers:args["modifiers"] as? String,mode:mode)
        case "activate":_ = try await activate(app:s.app)
        default:throw AutomationModel.fail("Unsupported action")
        }
    }
}
