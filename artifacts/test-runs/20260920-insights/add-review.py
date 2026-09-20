from pathlib import Path
p=Path('Sources/LeapCore/Recording.swift');s=p.read_text().replace('snapshot: Int? = nil) throws -> String {','snapshot: Int? = nil, outline: Bool = false, review: String? = nil, through: Int? = nil) throws -> String {')
pos='        if let snapshot {\n'
new='''        if let review {
            guard ["overview","actions","issues","events"].contains(review) else {throw LeapError.unsupported("Unknown review view")}
            // Freeze the read transaction and return its high-water mark for stable later pages.
            _ = try read("BEGIN",[])
            let maximum=try read("SELECT COALESCE(MAX(seq),0) AS high FROM records",[]).first?["high"] as? String ?? "0"
            let high=min(max(0,through ?? Int(maximum) ?? 0),Int(maximum) ?? 0)
            var scope="seq <= ?";var bindings=[String(high)]
            for (column,value) in [("session",session),("interaction",interaction)] {
                if let value {scope += " AND \\(column)=?";bindings.append(value)}
            }
            let issue="""
            (kind='capture_gap' OR kind='coverage'
             OR (kind='action_result' AND json_extract(payload,'$.apiOutcome') LIKE 'error%')
             OR (kind='expectation_result' AND json_extract(payload,'$.phase')='after' AND json_extract(payload,'$.outcome')!='met')
             OR (kind='subscription' AND json_extract(payload,'$.result') NOT IN (0,-25209)))
            """
            let counts=try read("SELECT kind,COUNT(*) AS count,MIN(seq) AS first,MAX(seq) AS last FROM records WHERE \\(scope) GROUP BY kind ORDER BY kind",bindings)
            let totals=try read("SELECT COUNT(*) AS records,MIN(seq) AS first,MAX(seq) AS last,SUM(CASE WHEN \\(issue) THEN 1 ELSE 0 END) AS attentionRecords FROM records WHERE \\(scope)",bindings)
            let pageSize=min(50,cap)
            let sql:String
            if review == "events" {
                sql="""
                SELECT MIN(seq) AS seq,MAX(seq) AS last,COUNT(*) AS count,
                  json_extract(payload,'$.notification') AS notification,
                  json_extract(payload,'$.elementHash') AS elementHash,
                  MIN(wall) AS firstReceipt,MAX(wall) AS lastReceipt
                FROM records WHERE \\(scope) AND kind='ax_notification'
                GROUP BY session,json_extract(payload,'$.notification'),json_extract(payload,'$.elementHash')
                HAVING MIN(seq)>CAST(? AS INTEGER) ORDER BY MIN(seq) LIMIT ?
                """
            } else {
                let selection = review == "actions" ? "kind IN ('action_intent','action_result','expectation_result')" : issue
                sql="""
                SELECT seq,session,interaction,kind,wall,
                  json_extract(payload,'$.actionId') AS actionId,
                  json_extract(payload,'$.tool') AS tool,
                  json_extract(payload,'$.apiOutcome') AS apiOutcome,
                  json_extract(payload,'$.phase') AS phase,
                  json_extract(payload,'$.outcome') AS expectation,
                  substr(COALESCE(json_extract(payload,'$.label'),''),1,160) AS label,
                  substr(COALESCE(json_extract(payload,'$.detail'),json_extract(payload,'$.result'),payload),1,400) AS excerpt,
                  length(payload) AS retainedCharacters
                FROM records WHERE \\(scope) AND \\(selection) AND seq>? ORDER BY seq LIMIT ?
                """
            }
            var page=try read(sql,bindings+[String(max(0,after)),String(pageSize+1)])
            var more=page.count>pageSize;if more {page.removeLast()}
            var kept:[[String:Any]]=[];var bytes=0
            for row in page {let size=try json(row).utf8.count;if !kept.isEmpty && bytes+size>10000 {more=true;break};kept.append(row);bytes+=size}
            let cursor=Int(kept.last?["seq"] as? String ?? "") ?? max(0,after)
            return try json(["view":review,"historical":true,"through":high,"counts":counts,"totals":totals,
                "items":kept,"hasMore":more,"nextCursor":cursor,
                "scope":["session":session ?? "all","interaction":interaction ?? "all"],
                "coverage":"Recorded evidence only. API errors are not proof of failed effects; unsupported notifications and capture gaps require attention. Events grouped by session, notification and ephemeral element hash; separate actions are never merged.",
                "next":["page":"recording_review with same filters, through and after=nextCursor",
                        "actions":"recording_review(view: actions)","events":"recording_review(view: events)",
                        "evidence":"recording_query(after: record seq minus 1, limit: 1)",
                        "tree":"recording_nodes(snapshot: snapshot seq, outline: true)"],
                "presentation":"Values/excerpts may be shortened; full retained records remain queryable. Overview lists attention records first; counts cover the whole selected history, not just this page."])
        }
'''
assert pos in s;s=s.replace(pos,new+pos,1)
s=s.replace('            for var row in nodes {','''            for var row in nodes {
                if outline, let node=row["payload"] as? [String:Any] {
                    row["payload"]=node.filter { ["key","role","depth","label","enabled","offscreen"].contains($0.key) }
                }''',1);p.write_text(s)
p=Path('Sources/LeapCore/Engine+Recording.swift');s=p.read_text().replace('    public func beginInteraction()', '''    public func recordingProject(_ explicit:String?) throws -> String {
        if let explicit {return explicit}
        guard recordingStores.count == 1, let root=recordingStores.keys.first else {
            throw LeapError.unsupported("Specify project, or start recording for one project first.")
        }
        return root
    }
    public func beginInteraction()''');p.write_text(s)
p=Path('Sources/claude-leap/Tools.swift');s=p.read_text();idx='        Tool(name: "recording_start"';tool='''        Tool(name: "recording_review", description: "Explain recorded activity without dumping trees: overview highlights issues and counts; actions lists input attempts and checks; issues lists errors, unmet postchecks and capture limitations; events groups repeated notifications. Historical evidence, not a fresh app read. Bounded excerpts, evidence references and stable pagination. Project can be omitted while recording one project.", inputSchema:schema(["project":prop("string","Optional project; defaults to the sole active recording project."),"session_id":prop("string","Optional session filter."),"interaction_id":prop("string","Optional interaction: what happened during this action?"),"view":prop("string","Default overview.",enumValues:["overview","actions","issues","events"]),"after":prop("integer","Exclusive page cursor; default 0."),"through":prop("integer","Return this value from the first page to keep subsequent pages consistent."),"limit":prop("integer","Page size 1–50, default 10.")]),annotations:.init(readOnlyHint:true)),
''';assert idx in s;s=s.replace(idx,tool+idx,1)
s=s.replace('"snapshot":prop("integer","Snapshot sequence ID from state footer or query."),','"snapshot":prop("integer","Snapshot sequence ID from state footer or query."),"outline":prop("boolean","Tree structure/labels only; omit values, geometry and actions. Default false."),',1)
s=s.replace('        case "recording_start":','''        case "recording_review":
            return try RecordingStore.query(project:engine.recordingProject(a.string("project")),session:a.string("session_id"),interaction:a.string("interaction_id"),kind:nil,contains:nil,after:a.int("after") ?? 0,limit:a.int("limit") ?? 10,review:a.string("view") ?? "overview",through:a.int("through")).result
        case "recording_start":''',1)
s=s.replace('snapshot:name == "recording_nodes" ? a.int("snapshot") : nil).result','snapshot:name == "recording_nodes" ? a.int("snapshot") : nil,outline:a.bool("outline") ?? false).result');p.write_text(s)
# A newly observed node has no actionable index yet; do not advertise a fictional index 0.
p=Path('Sources/LeapCore/Engine.swift');s=p.read_text().replace('lastSeen = "[\\(h.index)] \\(h.node.role.dropFirst(2))"','lastSeen = (h.index > 0 ? "[\\(h.index)] " : "[new node; use the returned state for its index] ") + "\\(h.node.role.dropFirst(2))"');p.write_text(s)
