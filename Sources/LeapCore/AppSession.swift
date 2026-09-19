import ApplicationServices
import AppKit
import Foundation

/// A rendered element the model can refer to by index.
public struct ElementRecord {
    public let index: Int
    public let node: AXNode
}

/// Per-app state: the stable index registry, the last rendered lines (for diffs)
/// and the element table backing `element_index` actions.
public final class AppSession {
    public let pid: pid_t
    public let app: NSRunningApplication
    public let axApp: AXUIElement
    var indexByKey: [String: Int] = [:]
    var nextIndex = 1
    var lastLines: [Int: String] = [:]
    var lastOrder: [Int] = []
    var lastWindowTitle: String?
    public private(set) var elements: [Int: ElementRecord] = [:]
    public private(set) var lastWindow: AXUIElement?
    public private(set) var lastWindowFrame: CGRect = .zero
    public var lastActionAt: Date = .distantPast
    /// Title substring chosen with get_app_state(window:); nil = the app's key window.
    public var pinnedWindow: String?

    public init(app: NSRunningApplication) {
        self.app = app
        self.pid = app.processIdentifier
        self.axApp = AXUIElementCreateApplication(app.processIdentifier)
    }

    public var displayName: String { app.localizedName ?? app.bundleIdentifier ?? "pid \(pid)" }

    public func element(_ index: Int) throws -> ElementRecord {
        guard let rec = elements[index] else { throw LeapError.noSuchElement(index) }
        // The UI may have changed under us (the user clicked something, a sheet opened, the
        // app navigated). Refuse to act on an element that is gone or has become something
        // else, and tell the model to re-read state — acting on a stale index is how agents
        // click the wrong thing.
        let live = AX.attrs(rec.node.element, [kAXRoleAttribute, kAXPositionAttribute, kAXSizeAttribute])
        guard let role = live[kAXRoleAttribute] as? String else {
            throw LeapError.staleElement(index, "it no longer exists")
        }
        if role != rec.node.role {
            throw LeapError.staleElement(index, "it is now a \(role.dropFirst(2)), was \(rec.node.role.dropFirst(2))")
        }
        if let old = rec.node.frame, let p = AX.point(live[kAXPositionAttribute]), let s = AX.size(live[kAXSizeAttribute]) {
            let new = CGRect(origin: p, size: s)
            if new.width <= 0 || new.height <= 0 {
                throw LeapError.staleElement(index, "it is no longer visible")
            }
            // Position drift is normal (window moved); a size change means a relayout.
            if abs(new.width - old.width) > 2 || abs(new.height - old.height) > 2 {
                throw LeapError.staleElement(index, "its size changed (\(Int(old.width))x\(Int(old.height)) → \(Int(new.width))x\(Int(new.height)))")
            }
        }
        return rec
    }

    func index(for key: String) -> Int {
        if let i = indexByKey[key] { return i }
        let i = nextIndex
        nextIndex += 1
        indexByKey[key] = i
        return i
    }

    /// Render a snapshot into indexed text, updating the element table.
    /// Returns the full text and, when a previous render exists for the same window,
    /// a diff-only text.
    public func render(_ snap: AXWindowSnapshot, walker: AXWalker) -> (full: String, diff: String?) {
        // Never renumber: `indexByKey` is keyed by a content-addressed AX path, so an index
        // keeps pointing at the same element for the life of the session. AX hands back fresh
        // AXUIElement objects (e.g. after the window moves), so element identity must not be
        // allowed to reset the index space — that is what made indices shift under the caller.
        // Only the diff baseline is dropped when we are looking at a different window.
        let sameWindow = lastWindow != nil && CFEqual(lastWindow, snap.window) && lastWindowTitle == snap.title
        if !sameWindow {
            lastLines.removeAll()
            lastOrder.removeAll()
        }
        lastWindow = snap.window
        lastWindowTitle = snap.title
        lastWindowFrame = snap.frame

        var lines: [Int: String] = [:]
        var order: [Int] = []
        var table: [Int: ElementRecord] = [:]
        for node in snap.nodes {
            let idx = index(for: node.key)
            lines[idx] = Self.line(node, windowFrame: snap.frame, focused: snap.focusedElement)
            order.append(idx)
            table[idx] = ElementRecord(index: idx, node: node)
        }
        elements = table

        let header = Self.header(snap: snap, session: self)
        var full = header + "\n"
        for idx in order {
            let depth = table[idx]!.node.depth
            full += String(repeating: "  ", count: max(0, depth - 1)) + "[\(idx)] " + lines[idx]! + "\n"
        }
        if snap.truncated { full += "… (tree truncated at \(walker.maxNodes) elements; scroll or use a query)\n" }

        var diff: String?
        if !lastLines.isEmpty {
            var added: [Int] = [], changed: [Int] = [], removed: [Int] = []
            for idx in order {
                if let prev = lastLines[idx] {
                    if prev != lines[idx] { changed.append(idx) }
                } else { added.append(idx) }
            }
            for idx in lastOrder where lines[idx] == nil { removed.append(idx) }
            let unchanged = order.count - added.count - changed.count
            let churn = added.count + changed.count + removed.count
            if churn == 0 {
                diff = header + "\n(no accessibility changes since the previous state; \(order.count) elements unchanged)\n"
            } else if churn * 10 < max(order.count, 1) * 7 { // < 70% churn → diff is worth it
                var d = header + "\n## Diff vs previous state (\(unchanged) unchanged elements omitted; indices are stable)\n"
                for idx in order {
                    if added.contains(idx) { d += "+ [\(idx)] \(lines[idx]!)\n" }
                    else if changed.contains(idx) { d += "~ [\(idx)] \(lines[idx]!)\n" }
                }
                for idx in removed { d += "- [\(idx)] \(lastLines[idx]!)\n" }
                diff = d
            }
        }
        lastLines = lines
        lastOrder = order
        return (full, diff)
    }

    static func header(snap: AXWindowSnapshot, session: AppSession) -> String {
        let f = snap.frame
        var h = "## \(session.displayName) — window \"\(snap.title ?? "")\" \(Int(f.width))x\(Int(f.height)) at screen (\(Int(f.minX)),\(Int(f.minY)))"
        h += session.app.isActive ? " [frontmost]" : " [background]"
        h += "\nCoordinates below are window-relative points (x,y w×h). Screenshot pixels map 1:1 to these when scale=1."
        return h
    }

    static func line(_ n: AXNode, windowFrame: CGRect, focused: AXUIElement?) -> String {
        var parts: [String] = []
        var role = n.role.hasPrefix("AX") ? String(n.role.dropFirst(2)) : n.role
        if let sub = n.subrole, sub != "AXUnknown" {
            role += "/" + (sub.hasPrefix("AX") ? String(sub.dropFirst(2)) : sub)
        }
        parts.append(role)
        if let t = n.title { parts.append("\"\(t)\"") }
        if let v = n.value { parts.append("value=\"\(v)\"") }
        if let p = n.placeholder { parts.append("placeholder=\"\(p)\"") }
        if let d = n.description, d != n.title { parts.append("desc=\"\(d)\"") }
        if let id = n.identifier { parts.append("id=\(id)") }
        if let f = n.frame {
            parts.append("@\(Int(f.minX - windowFrame.minX)),\(Int(f.minY - windowFrame.minY)) \(Int(f.width))x\(Int(f.height))")
        }
        if n.settable { parts.append("[settable]") }
        if n.offscreen { parts.append("[offscreen: coords unreliable, use element_index/label]") }
        if !n.enabled { parts.append("[disabled]") }
        if n.selected { parts.append("[selected]") }
        if n.focused || (focused != nil && CFEqual(focused, n.element)) { parts.append("[focused]") }
        let extra = n.actions.filter { !AXWalker.hiddenActions.contains($0) }
            .map { $0.hasPrefix("AX") ? String($0.dropFirst(2)) : $0 }
        if !extra.isEmpty { parts.append("actions=" + extra.joined(separator: ",")) }
        return parts.joined(separator: " ")
    }
}
