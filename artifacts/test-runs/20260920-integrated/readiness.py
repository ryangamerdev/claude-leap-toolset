from pathlib import Path
p=Path('Sources/LeapCore/AXTree.swift');s=p.read_text();s=s.replace('    public let key: String\n','    public let key: String\n    public var capturedValue: String? = nil\n    public var valueLimited: Bool = false\n',1);s=s.replace('    public let truncated: Bool\n','    public let truncated: Bool\n    public var readFailures: Int = 0\n    public var deadlineExceeded: Bool = false\n    public var captureStarted: Double = 0\n    public var captureEnded: Double = 0\n',1)
s=s.replace('enum AX {','''final class AXReadBudget {
    let started = ProcessInfo.processInfo.systemUptime
    let deadline: Double
    var failures = 0
    var expired: Bool { ProcessInfo.processInfo.systemUptime >= deadline }
    init(seconds: Double) { deadline = ProcessInfo.processInfo.systemUptime + max(0.01,seconds) }
}

enum AX {
    static var budget: AXReadBudget? { Thread.current.threadDictionary["leap.readBudget"] as? AXReadBudget }
    static func prepare(_ el: AXUIElement) -> Bool {
        guard let budget else { return true }
        guard !budget.expired else {return false}
        AXUIElementSetMessagingTimeout(el,Float(min(0.25,max(0.01,budget.deadline-ProcessInfo.processInfo.systemUptime))))
        return true
    }
    static func note(_ result: AXError) {
        // Unsupported/missing attributes are legitimate; transport/element failures are not absence.
        if result != .success && ![-25205,-25212].contains(Int(result.rawValue)) {budget?.failures += 1}
    }
''',1)
s=s.replace('        var v: CFTypeRef?\n        guard AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success, let v else { return nil }','        guard prepare(el) else {return nil}\n        var v: CFTypeRef?\n        let result=AXUIElementCopyAttributeValue(el, name as CFString, &v);note(result)\n        guard result == .success, let v else { return nil }',1)
s=s.replace('        var out: CFArray?\n        let status', '        guard prepare(el) else {return [:]}\n        var out: CFArray?\n        let status',1)
s=s.replace('guard let value, CFGetTypeID(value) != AXValueGetTypeID() || AXValueGetType(value as! AXValue) != .axError else { continue }','''guard let value else {continue}
                if CFGetTypeID(value) == AXValueGetTypeID(), AXValueGetType(value as! AXValue) == .axError {
                    var error=AXError.success
                    AXValueGetValue(value as! AXValue,.axError,&error);note(error);continue
                }''',1)
s=s.replace('        for name in names {\n            var v:', '        note(status)\n        for name in names {\n            guard prepare(el) else {break}\n            var v:',1)
s=s.replace('if AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success, let v { dict[name] = v }','let result=AXUIElementCopyAttributeValue(el, name as CFString, &v);note(result)\n            if result == .success, let v { dict[name] = v }',1)
s=s.replace('        var names: CFArray?\n        guard AXUIElementCopyActionNames','        guard prepare(el) else {return []}\n        var names: CFArray?\n        guard AXUIElementCopyActionNames',1)
s=s.replace('public func snapshot(window: AXUIElement, app: AXUIElement) -> AXWindowSnapshot? {','''public func snapshot(window: AXUIElement, app: AXUIElement, timeout: Double = 3) -> AXWindowSnapshot? {
        let budget=AXReadBudget(seconds:timeout)
        let previous=Thread.current.threadDictionary["leap.readBudget"]
        Thread.current.threadDictionary["leap.readBudget"]=budget
        defer {Thread.current.threadDictionary["leap.readBudget"]=previous}''',1)
s=s.replace('nodes: nodes, truncated: truncated)','nodes: nodes, truncated: truncated, readFailures:budget.failures, deadlineExceeded:budget.expired, captureStarted:budget.started, captureEnded:ProcessInfo.processInfo.systemUptime)',1)
s=s.replace('if count >= maxNodes || depth > maxDepth {','if AX.budget?.expired == true || count >= maxNodes || depth > maxDepth {',1)
s=s.replace('actions: actions, settable: settable, offscreen: offscreen, depth: depth, key: key))','''actions: actions, settable: settable, offscreen: offscreen, depth: depth, key: key,
                                capturedValue: role == "AXSecureTextField" ? nil : (a[kAXValueAttribute] as? String).map {String($0.prefix(65536))},
                                valueLimited: role != "AXSecureTextField" && ((a[kAXValueAttribute] as? String)?.count ?? 0)>65536))''',1)
p.write_text(s)
p=Path('Sources/LeapCore/Engine.swift');s=p.read_text();s=s.replace('    var recordingInteraction: String?','    var boundProject: String?\n    var recordingSuppressed = Set<pid_t>()\n    var latestEvidence: [pid_t:Int] = [:]\n    var recordingInteraction: String?')
s=s.replace('if let s = sessions[app.processIdentifier], !s.app.isTerminated { return s }','if let s = sessions[app.processIdentifier], !s.app.isTerminated {try autoRecord(s); return s}')
s=s.replace('        pidByIdentity[identity] = s.pid\n        return s','        pidByIdentity[identity] = s.pid\n        try autoRecord(s)\n        return s')
s=s.replace('if now == previous && !busy {','if now == previous && !busy && again.readFailures == 0 && !again.deadlineExceeded && !again.truncated {')
s=s.replace('guard let again = walker.snapshot(window: window, app: s.axApp) else { break }','guard let again = walker.snapshot(window: window, app: s.axApp, timeout:max(0.01,deadline.timeIntervalSinceNow)) else { break }')
s=s.replace('        do { text += try recordSnapshot(snap, session: s) }','''        if snap.readFailures>0 || snap.deadlineExceeded || snap.truncated {
            text += "\\nObservation incomplete: readFailures=\\(snap.readFailures), deadline=\\(snap.deadlineExceeded), nodeLimit=\\(snap.truncated). Missing controls do not prove absence."
        }
        do {
            let footer=try recordSnapshot(snap, session:s)
            if recordings[s.pid] != nil {text=compactObservation(text)}
            text += footer
        }''')
s=s.replace('        let deadline = Date().addingTimeInterval(timeout)\n        let started = Date()\n        var lastSeen', '        let deadline = ProcessInfo.processInfo.systemUptime + timeout\n        let started = Date()\n        let grace=min(max(0,settleDelay-Date().timeIntervalSince(s.lastActionAt)),timeout/2)\n        if grace>0 {try await Task.sleep(nanoseconds:UInt64(grace*1_000_000_000))}\n        var lastSeen')
s=s.replace('            let window = try await waitForWindow(s)\n            guard let snap = walker.snapshot(window: window, app: s.axApp) else {\n                throw LeapError.unsupported("Expectation unknown: accessibility observation unavailable")\n            }','''            let remaining=deadline-ProcessInfo.processInfo.systemUptime
            guard remaining>0 else {throw LeapError.unsupported("Expectation unknown: observation deadline exhausted; input is not retried")}
            let window = try await waitForWindow(s,timeout:remaining)
            guard let snap = walker.snapshot(window:window,app:s.axApp,timeout:max(0.01,deadline-ProcessInfo.processInfo.systemUptime)) else {
                if ProcessInfo.processInfo.systemUptime < deadline {continue}
                throw LeapError.unsupported("Expectation unknown: accessibility observation unavailable")
            }''',1)
s=s.replace('if condition == .disappears && snap.truncated {\n                throw LeapError.unsupported("Expectation unknown: absence cannot be established from a truncated tree")\n            }','''let incomplete=snap.truncated || snap.readFailures>0 || snap.deadlineExceeded
            if incomplete || ProcessInfo.processInfo.systemUptime > deadline {
                if ProcessInfo.processInfo.systemUptime < deadline {
                    try await Task.sleep(nanoseconds:UInt64(min(0.3,max(0,deadline-ProcessInfo.processInfo.systemUptime))*1_000_000_000));continue
                }
                throw LeapError.unsupported("Expectation unknown: incomplete or late observation; no input retry. Read failures=\\(snap.readFailures)")
            }''')
s=s.replace('            if Date() >= deadline {\n                throw LeapError.unsupported("wait_for timed out','            if ProcessInfo.processInfo.systemUptime >= deadline {\n                throw LeapError.unsupported("wait_for timed out')
s=s.replace('            try await Task.sleep(nanoseconds: 300_000_000)\n        }\n    }\n\n    /// Elements','            try await Task.sleep(nanoseconds: UInt64(min(0.3,max(0,deadline-ProcessInfo.processInfo.systemUptime))*1_000_000_000))\n        }\n    }\n\n    /// Elements')
p.write_text(s)
