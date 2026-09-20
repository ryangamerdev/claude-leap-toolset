import Foundation
import ApplicationServices

/// Shared intent contract. JSON stays at the adapter boundary; selectors and verdicts are
/// evaluated identically for Mac AX and XCTest observations.
public enum AutomationModel {
    static func sameOrientation(_ before:[String:Any],_ after:[String:Any]) -> Bool {
        guard before["orientation"] as? String == after["orientation"] as? String else {return false}
        if before["backend"] as? String == "wda" || after["backend"] as? String == "wda" {
            guard before["orientationStable"] as? Bool == true, after["orientationStable"] as? Bool == true,
                  let a=before["orientationIdentity"] as? String,!a.isEmpty,
                  let b=after["orientationIdentity"] as? String else {return false}
            return a == b
        }
        return true
    }
    static func fail(_ message: String) -> LeapError { .unsupported(message) }
    static func object(_ value: Any?) -> [String:Any] { value as? [String:Any] ?? [:] }
    static func role(_ value: String) -> String {
        value.replacingOccurrences(of:"XCUIElementType",with:"").replacingOccurrences(of:"AX",with:"").lowercased()
    }
    static let selectorKeys: Set<String> = ["id","identifier","role","label","contains","root"]
    static func validateSelector(_ selector: [String:Any]) throws {
        guard Set(selector.keys).isSubset(of: selectorKeys), selector.values.allSatisfy({$0 is String}) else {
            throw fail("Invalid selector: use string id, identifier, role, label, contains or root")
        }
    }
    static func matches(_ node: [String:Any], _ selector: [String:Any]) -> Bool {
        for key in ["id","identifier","label"] {
            if let wanted=selector[key] as? String, node[key] as? String != wanted {return false}
        }
        if let r=selector["role"] as? String, role(node["role"] as? String ?? "") != role(r) {return false}
        if let text=selector["contains"] as? String,
           !((node["label"] as? String ?? "")+" "+(node["value"] as? String ?? "")).localizedCaseInsensitiveContains(text) {return false}
        if let root=selector["root"] as? String, node["id"] as? String != root,
           !(node["ancestors"] as? [String] ?? []).contains(root) {return false}
        return true
    }
    static let conditions: Set<String> = ["exists","absent","enabled","disabled","selected","value_equals","value_contains","count"]
    static func validateExpectation(_ expectation: [String:Any]) throws {
        guard Set(expectation.keys).isSubset(of:["selector","condition","value"]),
              let condition=expectation["condition"] as? String, conditions.contains(condition),
              let selector=expectation["selector"] as? [String:Any] else {throw fail("Expectation needs condition and selector")}
        try validateSelector(selector)
        if condition.hasPrefix("value_") && !(expectation["value"] is String) {throw fail("Value assertion needs a string value")}
        if condition == "count" && !(expectation["value"] is Int) {throw fail("Count assertion needs integer value")}
    }
    static func verdict(nodes: [[String:Any]], complete: Bool, expectation: [String:Any]) -> String {
        let hits=nodes.filter {matches($0,object(expectation["selector"]))}
        let condition=expectation["condition"] as? String ?? ""
        // Incomplete reads cannot establish exhaustive counts, uniqueness or absence.
        if !complete {return "unknown"}
        switch condition {
        case "exists": return hits.isEmpty ? "failed":"passed"
        case "absent": return hits.isEmpty ? "passed":"failed"
        case "count": return hits.count == expectation["value"] as? Int ? "passed":"failed"
        default: break
        }
        guard hits.count == 1 else {return hits.isEmpty ? "failed":"unknown"}
        let n=hits[0]
        switch condition {
        case "enabled","disabled","selected":
            guard let value=n[condition == "disabled" ? "enabled":condition] as? Bool else {return "unknown"}
            return value == (condition != "disabled") ? "passed":"failed"
        case "value_equals","value_contains":
            guard let value=n["value"] as? String, n["valueLimited"] as? Bool != true else {return "unknown"}
            let wanted=expectation["value"] as? String ?? ""
            return (condition == "value_equals" ? value == wanted:value.contains(wanted)) ? "passed":"failed"
        default: return "unknown"
        }
    }
    static func coordinateBounds(_ value:Any?) -> [Double]? {
        // Mac observations contain CGFloat arrays; persisted JSON contains NSNumber.
        // Normalize both at the boundary instead of casting a live array to Double.
        guard let values=value as? [NSNumber],values.count==4,
              values.allSatisfy({CFGetTypeID($0) != CFBooleanGetTypeID() && $0.doubleValue.isFinite}) else {return nil}
        let result=values.map(\.doubleValue)
        guard result[2]>0,result[3]>0 else {return nil}
        return result
    }
    static func sameBounds(_ lhs:Any?, _ rhs:Any?) -> Bool {
        guard let a=coordinateBounds(lhs),let b=coordinateBounds(rhs) else {return false}
        return a == b
    }
    static func delta(_ before: [[String:Any]], _ after: [[String:Any]], complete: Bool) -> [String:Any] {
        func keyed(_ nodes: [[String:Any]]) -> [String:[String:Any]] {
            var result: [String:[String:Any]]=[:]
            for n in nodes {if let id=n["id"] as? String {result[id]=n}}
            return result
        }
        let old=keyed(before), new=keyed(after)
        var changes:[[String:Any]]=[]
        for id in Set(old.keys).union(new.keys).sorted() {
            if old[id] == nil {changes.append(["id":id,"change":"added","after":new[id]!])}
            else if new[id] == nil {changes.append(["id":id,"change":complete ? "removed":"not_observed"])}
            else {
                var fields:[String:Any]=[:]
                for k in ["label","value","enabled","selected","focused","frame"] {
                    if String(describing:old[id]![k]) != String(describing:new[id]![k]) {
                        fields[k]=["before":old[id]![k] ?? NSNull(),"after":new[id]![k] ?? NSNull()]
                    }
                }
                if !fields.isEmpty {changes.append(["id":id,"change":"changed","fields":fields])}
            }
        }
        return ["changes":Array(changes.prefix(12)),"totalChanges":changes.count,"omitted":max(0,changes.count-12),"complete":complete,"meaning":"Observed differences, not causal attribution; IDs can churn"]
    }
    /// Budget applies to the complete envelope. A full retained object is available by file.
    static func bounded(_ value: [String:Any], budget: Int, file: String) throws -> String {
        let full=try RecordingStore.json(value)
        if full.utf8.count <= budget {return full}
        var result:[String:Any]=["schemaVersion":2,"omittedFromResponse":true,"bytes":full.utf8.count,"file":file,"hint":"Read retained JSON or use ui_observe with snapshot and narrower fields/selector"]
        for key in ["session_id","interaction_id","snapshot","execution","verification","error","hasMore","nextCursor"] {result[key]=value[key]}
        return try RecordingStore.json(result)
    }
}

final class AutomationSession {
    let id:String, app:String, backend:String, store:RecordingStore
    var window:String?
    var windowIdentity:AXUIElement?
    let pid:pid_t?
    var wda:WDAClient?
    var latest:[String:Any]?
    init(id:String,app:String,backend:String,window:String?,store:RecordingStore,pid:pid_t?) {
        self.id=id; self.app=app; self.backend=backend; self.window=window; self.store=store; self.pid=pid
    }
    func save(_ kind:String,_ value:[String:Any],interaction:String?) throws -> (Int,String) {
        let seq=try store.append(session:id,interaction:interaction,kind:"automation_"+kind,payload:value)
        let path=store.root+"/.leap/sessions/"+id+"/\(seq)-\(kind).json"
        try RecordingStore.json(value).write(toFile:path,atomically:true,encoding:.utf8)
        return (Int(seq),path)
    }
}
