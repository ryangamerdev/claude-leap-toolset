import ApplicationServices
import AppKit
import Foundation

/// One rendered accessibility element. `key` is stable across snapshots of the
/// same window so the model's `element_index` values survive UI changes.
public struct AXNode {
    public let element: AXUIElement
    public let role: String
    public let subrole: String?
    public let title: String?
    public let value: String?
    public let description: String?
    public let identifier: String?
    public let placeholder: String?
    public let frame: CGRect? // screen coords, top-left origin
    public let enabled: Bool
    public let focused: Bool
    public let selected: Bool
    public let actions: [String]
    /// Whether kAXValue can be written (text fields, sliders, checkboxes, ...).
    public let settable: Bool
    /// Frame lies outside the window. Kept (not dropped) because some hosts — notably the iOS
    /// Simulator after a rotation — report frames in an untransformed space while the element
    /// is perfectly visible and pressable via accessibility actions.
    public let offscreen: Bool
    public let depth: Int
    public let key: String
    public var capturedValue: String? = nil
    public var valueLimited: Bool = false
    public var unavailableFields: [String] = []
}

public struct AXWindowSnapshot {
    public let window: AXUIElement
    public let title: String?
    public let frame: CGRect
    public let focusedElement: AXUIElement?
    public let nodes: [AXNode]
    public let truncated: Bool
    public var retainedEarlierObservation: Bool = false
    public var readFailures: Int = 0
    public var advisoryReadFailures: Int = 0
    public var blockingReadFailures: Int { max(0, readFailures - advisoryReadFailures) }
    public var supportsStateChecks: Bool { blockingReadFailures == 0 && !deadlineExceeded && !truncated }
    public var batchReadRetries: Int = 0
    public var batchReadRecoveries: Int = 0
    public var readFailureDetails: [[String: String]] = []
    public var readFailureDetailsOmitted: Int = 0
    public var deadlineExceeded: Bool = false
    public var captureStarted: Double = 0
    public var captureEnded: Double = 0
}

final class AXReadBudget {
    let started = ProcessInfo.processInfo.systemUptime
    let deadline: Double
    var failures = 0
    var advisoryFailures = 0
    var batchRetries = 0
    var batchRecoveries = 0
    var failureDetails: [[String: String]] = []
    var metadataFailures: [CFHashCode:Set<String>] = [:]
    var expired: Bool { ProcessInfo.processInfo.systemUptime >= deadline }
    init(seconds: Double) { deadline = ProcessInfo.processInfo.systemUptime + max(0.01,seconds) }
}

enum AX {
    static func withBudget<T>(_ seconds:Double,_ body:() throws -> T) rethrows -> T {
        let previous=Thread.current.threadDictionary["leap.readBudget"]
        Thread.current.threadDictionary["leap.readBudget"]=AXReadBudget(seconds:seconds)
        defer {Thread.current.threadDictionary["leap.readBudget"]=previous}
        return try body()
    }
    static var budget: AXReadBudget? { Thread.current.threadDictionary["leap.readBudget"] as? AXReadBudget }
    static func prepare(_ el: AXUIElement) -> Bool {
        guard let budget else { return true }
        guard !budget.expired else {return false}
        AXUIElementSetMessagingTimeout(el,Float(min(0.25,max(0.01,budget.deadline-ProcessInfo.processInfo.systemUptime))))
        return true
    }
    static func advisoryFailure(attribute: String, role: String?) -> Bool {
        // Subroles refine these non-text controls but do not determine their label/state
        // or child traversal. Unknown and text roles remain conservative (secure fields).
        if role == "AXTextArea", [kAXIdentifierAttribute,kAXDescriptionAttribute].contains(attribute) {return true}
        return attribute == kAXSubroleAttribute && ["AXButton", "AXCheckBox", "AXScrollArea",
            "AXToolbar", "AXMenuBar", "AXMenuBarItem", "AXImage"].contains(role ?? "")
    }
    static func note(_ result: AXError, attribute: String, element: AXUIElement, role: String? = nil) {
        // Unsupported/missing attributes are legitimate; transport/element failures are not absence.
        if result != .success && ![-25205,-25212].contains(Int(result.rawValue)), let budget {
            budget.failures += 1
            let advisory = result == .failure && advisoryFailure(attribute: attribute, role: role)
            if advisory {
                budget.advisoryFailures += 1
                if role == "AXTextArea" {budget.metadataFailures[CFHash(element),default:[]].insert(attribute)}
            }
            // No diagnostic AX reads: they could block or recursively add failures.
            // This hash correlates reads within an observation, never a durable target identity.
            if budget.failureDetails.count < 8 {
                budget.failureDetails.append(["attribute": attribute, "errorCode": String(result.rawValue),
                    "error": String(describing: result), "elementHash": String(CFHash(element)),
                    "role": role ?? "unknown", "impact": advisory ? "optional metadata" : "state coverage"])
            }
        }
    }

    static func attr<T>(_ el: AXUIElement, _ name: String) -> T? {
        guard prepare(el) else {return nil}
        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}
        var v: CFTypeRef?
        let result=AXUIElementCopyAttributeValue(el, name as CFString, &v);note(result, attribute: name, element: el)
        guard result == .success, let v else { return nil }
        return v as? T
    }

    static func attrs(_ el: AXUIElement, _ names: [String]) -> [String: CFTypeRef] {
        guard prepare(el) else {return [:]}
        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}
        var out: CFArray?
        let status = AXUIElementCopyMultipleAttributeValues(el, names as CFArray, [], &out)
        var dict: [String: CFTypeRef] = [:]
        if status == .success, let values = out as? [CFTypeRef?] {
            for (name, value) in zip(names, values) {
                guard let value else {continue}
                if CFGetTypeID(value) == AXValueGetTypeID(), AXValueGetType(value as! AXValue) == .axError {
                    var error=AXError.success
                    AXValueGetValue(value as! AXValue,.axError,&error)
                    // A provider may reject one field in a successful batch but support
                    // its individual getter. Retry reads only, once, within the same budget.
                    if error == .failure && prepare(el) {
                        budget?.batchRetries += 1
                        var recovered: CFTypeRef?
                        let retry = AXUIElementCopyAttributeValue(el, name as CFString, &recovered)
                        if retry == .success || retry == .attributeUnsupported || retry == .noValue {
                            budget?.batchRecoveries += 1
                        }
                        if retry == .success, let recovered { dict[name] = recovered }
                        note(retry, attribute: name, element: el, role: dict[kAXRoleAttribute] as? String)
                    } else {
                        note(error, attribute: name, element: el, role: dict[kAXRoleAttribute] as? String)
                    }
                    continue
                }
                dict[name] = value
            }
            return dict
        }
        // Chromium/Electron (ChatGPT, VS Code, browsers) reject the batched call for many
        // elements while answering single-attribute reads fine; without this fallback their
        // web content walks as an empty group.
        // A rejected batch can be fully recovered by individual reads. Count their failures, not the recovered batch.
        for name in names {
            guard prepare(el) else {break}
            var v: CFTypeRef?
            let result=AXUIElementCopyAttributeValue(el, name as CFString, &v);note(result, attribute: name, element: el)
            if result == .success, let v { dict[name] = v }
        }
        return dict
    }

    static func point(_ v: CFTypeRef?) -> CGPoint? {
        guard let v, CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
        var p = CGPoint.zero
        return AXValueGetValue(v as! AXValue, .cgPoint, &p) ? p : nil
    }

    static func size(_ v: CFTypeRef?) -> CGSize? {
        guard let v, CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
        var s = CGSize.zero
        return AXValueGetValue(v as! AXValue, .cgSize, &s) ? s : nil
    }

    static func string(_ v: CFTypeRef?, limit: Int = 240) -> String? {
        guard let v else { return nil }
        var s: String
        if let str = v as? String { s = str }
        else if let n = v as? NSNumber { s = n.stringValue }
        else if let attributed = v as? NSAttributedString { s = attributed.string }
        else if let url = v as? URL { s = url.absoluteString }
        else if CFGetTypeID(v) == AXValueGetTypeID() {
            if let p = point(v) { s = "(\(Int(p.x)),\(Int(p.y)))" }
            else if let sz = size(v) { s = "\(Int(sz.width))x\(Int(sz.height))" }
            else { return nil }
        } else { return nil }
        s = s.replacingOccurrences(of: "\n", with: "⏎")
        if s.count > limit { s = String(s.prefix(limit)) + "…" }
        return s.isEmpty ? nil : s
    }

    static func actions(_ el: AXUIElement) -> [String] {
        guard prepare(el) else {return []}
        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}
        var names: CFArray?
        guard AXUIElementCopyActionNames(el, &names) == .success, let arr = names as? [String] else { return [] }
        return arr
    }

    enum InsertOutcome {
        case verified          // the field now holds exactly the expected result
        case unchanged         // nothing happened; a fallback may try
        case uncertain(String) // the field changed, but not into the expected result: do NOT retry
        case notText           // element has no text API
    }

    /// Insert `text` at the element's selection (or replace all of its text) through the
    /// accessibility text API, and verify the *edit* — not merely that the text occurs.
    ///
    /// The expected result is computed from the value and selection read beforehand: for a
    /// replace-all it is `text`; for an insert it is the old value with the selected range
    /// replaced by `text`. If the write reports success but the field still holds the old
    /// value the outcome is `.unchanged`; if it holds something else the outcome is
    /// `.uncertain`, and callers must not fall through to another method (that is how text
    /// gets duplicated). Chromium/Electron editors answer success and ignore the write, which
    /// is why the return code alone is never trusted.
    static func insertText(_ el: AXUIElement, _ text: String, replaceAll: Bool) -> InsertOutcome {
        let probe: CFTypeRef? = attr(el, kAXSelectedTextRangeAttribute)
        guard probe != nil || isSettable(el, kAXSelectedTextAttribute) else { return .notText }
        // Many fields (SwiftUI especially) only accept selection edits while focused.
        AXUIElementSetAttributeValue(el, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        usleep(60_000)
        let before: String = attr(el, kAXValueAttribute) ?? ""
        var selection = CFRange(location: before.utf16.count, length: 0)
        if let v: CFTypeRef = attr(el, kAXSelectedTextRangeAttribute), CFGetTypeID(v) == AXValueGetTypeID() {
            AXValueGetValue(v as! AXValue, .cfRange, &selection)
        }
        if replaceAll {
            var range = CFRange(location: 0, length: before.utf16.count)
            if let axRange = AXValueCreate(.cfRange, &range) {
                AXUIElementSetAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, axRange)
            }
        }
        let expected: String
        if replaceAll {
            expected = text
        } else {
            let u = Array(before.utf16)
            let lo = max(0, min(selection.location, u.count))
            let hi = max(lo, min(selection.location + selection.length, u.count))
            expected = String(utf16CodeUnits: Array(u[..<lo]), count: lo) + text + String(utf16CodeUnits: Array(u[hi...]), count: u.count - hi)
        }
        let status = AXUIElementSetAttributeValue(el, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
        usleep(80_000)
        let after: String = attr(el, kAXValueAttribute) ?? ""
        if after == expected && (status == .success || after != before) { return .verified }
        if after == before { return .unchanged }
        return .uncertain("the field now reads \"\(after.prefix(80))\" (expected \"\(expected.prefix(80))\")")
    }

    /// Append `text` to a settable element's value (current + text) and verify by reading back.
    /// A value equal to the placeholder counts as empty (iOS reports the placeholder as the value).
    static func appendValue(_ el: AXUIElement, _ text: String, placeholder: String?) throws -> String? {
        guard isSettable(el, kAXValueAttribute) else { return nil }
        guard var current: String = attr(el, kAXValueAttribute) else { return nil }
        let original = current
        if let placeholder, current == placeholder { current = "" }
        let wanted = current + text
        _ = AXUIElementSetAttributeValue(el, kAXValueAttribute as CFString, wanted as CFTypeRef)
        usleep(80_000)
        let after: String = attr(el, kAXValueAttribute) ?? ""
        if after == wanted { return after }
        guard let observed: String = attr(el, kAXValueAttribute), observed == original else {
            throw LeapError.unsupported("Append value write left changed or unreadable text. Outcome uncertain; no keyboard fallback sent.")
        }
        return nil
    }

    static func isSettable(_ el: AXUIElement, _ name: String) -> Bool {
        guard prepare(el) else {return false}
        defer {if budget != nil {AXUIElementSetMessagingTimeout(el,AppSession.messagingTimeout)}}
        var settable: DarwinBoolean = false
        let result=AXUIElementIsAttributeSettable(el,name as CFString,&settable);note(result, attribute: name, element: el)
        return result == .success && settable.boolValue
    }

    /// SwiftUI leaks mangled type names into AXIdentifier
    /// ("SwiftUI.ModifiedContent<...>-1-AppWindow-1"); they cost tokens and carry no meaning.
    static func usefulIdentifier(_ id: String?) -> String? {
        guard let id else { return nil }
        if id.contains("SwiftUI.") || id.contains("ModifiedContent<") || id.count > 64 { return nil }
        if id.hasPrefix("_NS:") { return nil } // AppKit nib object numbers, meaningless to a reader
        return id
    }

    static func pid(of el: AXUIElement) -> pid_t? {
        var p: pid_t = 0
        return AXUIElementGetPid(el, &p) == .success ? p : nil
    }

    static func frame(_ el: AXUIElement) -> CGRect? {
        let a = attrs(el, [kAXPositionAttribute, kAXSizeAttribute])
        guard let p = point(a[kAXPositionAttribute]), let s = size(a[kAXSizeAttribute]) else { return nil }
        return CGRect(origin: p, size: s)
    }
}

public struct AXWalker {
    public var maxNodes = 1500
    public var maxDepth = 60
    /// Only render elements intersecting the window (menus/popovers are captured separately).
    public var clipToWindow = true
    public init() {}

    /// Container roles that are elided when they carry no information of their own.
    static let containerRoles: Set<String> = [
        "AXGroup", "AXSplitGroup", "AXLayoutArea", "AXLayoutItem", "AXUnknown", "AXGenericElement",
        "AXScrollArea", "AXList", "AXOutline", "AXTable", "AXWebArea", "AXSection", "AXToolbar",
        "AXTabGroup", "AXSplitter", "AXMatte", "AXGrowArea", "AXRuler", "AXBusyIndicator",
    ]

    // AXShowMenu is omitted because Chromium/Electron stamps it on every element; it stays
    // invocable through perform_action, which matches against the live action list.
    static let hiddenActions: Set<String> = ["AXPress", "AXScrollToVisible", "AXRaise", "AXShowMenu", "AXPick"]

    /// Roles where a synthesized click (which places the caret) beats the AX Press action.
    static let textRoles: Set<String> = [
        "AXTextField", "AXTextArea", "AXSearchField", "AXComboBox", "AXSecureTextField",
    ]

    static let editableRoles: Set<String> = [
        "AXTextField", "AXTextArea", "AXSearchField", "AXComboBox", "AXCheckBox", "AXRadioButton",
        "AXSlider", "AXIncrementor", "AXPopUpButton", "AXColorWell", "AXDateField", "AXTimeField",
        "AXSecureTextField", "AXSwitch", "AXToggle", "AXStepper",
    ]

    static let batchAttributes = [
        kAXRoleAttribute, kAXSubroleAttribute, kAXTitleAttribute, kAXValueAttribute,
        kAXDescriptionAttribute, kAXIdentifierAttribute, kAXPlaceholderValueAttribute,
        kAXPositionAttribute, kAXSizeAttribute, kAXEnabledAttribute, kAXFocusedAttribute,
        kAXSelectedAttribute, kAXChildrenAttribute,
    ]

    /// The key window of `app`, falling back to main / first window.
    public func keyWindow(of app: AXUIElement) -> AXUIElement? {
        if let w: AXUIElement = AX.attr(app, kAXFocusedWindowAttribute) { return w }
        if let w: AXUIElement = AX.attr(app, kAXMainWindowAttribute) { return w }
        if let ws: [AXUIElement] = AX.attr(app, kAXWindowsAttribute) { return ws.first }
        return nil
    }

    public func snapshot(window: AXUIElement, app: AXUIElement, timeout: Double = 3) -> AXWindowSnapshot? {
        let budget=AXReadBudget(seconds:timeout)
        let previous=Thread.current.threadDictionary["leap.readBudget"]
        Thread.current.threadDictionary["leap.readBudget"]=budget
        defer {Thread.current.threadDictionary["leap.readBudget"]=previous}
        guard let frame = AX.frame(window) else { return nil }
        let title: String? = AX.attr(window, kAXTitleAttribute)
        let focused: AXUIElement? = AX.attr(app, kAXFocusedUIElementAttribute)
        var nodes: [AXNode] = []
        var count = 0
        var truncated = false
        walk(window, depth: 0, parentKey: "w", siblingOrdinal: 0, windowFrame: frame,
             nodes: &nodes, count: &count, truncated: &truncated)
        if let bar: AXUIElement = AX.attr(app, kAXMenuBarAttribute) {
            walkMenuBar(bar, nodes: &nodes, count: &count, truncated: &truncated)
        }
        return AXWindowSnapshot(window: window, title: title, frame: frame, focusedElement: focused,
                                nodes: nodes, truncated: truncated, readFailures:budget.failures, advisoryReadFailures:budget.advisoryFailures, batchReadRetries:budget.batchRetries, batchReadRecoveries:budget.batchRecoveries, readFailureDetails:budget.failureDetails, readFailureDetailsOmitted:max(0,budget.failures-budget.failureDetails.count), deadlineExceeded:budget.expired, captureStarted:budget.started, captureEnded:ProcessInfo.processInfo.systemUptime)
    }

    /// The app's menu bar: its titles always, and the items of any menu that is currently open.
    ///
    /// The Codex/Sky session lists the menu bar in every full tree and, after clicking a menu
    /// title, returns that menu's items — that is how it switched Simulator device windows
    /// (Window › "iPhone 16 – iOS 18.0") and quit apps (Quit Gameday). AXPress on a title opens
    /// the menu even for a background app and leaves the frontmost app alone (verified);
    /// a closed menu has a zero-size frame and no visible children, an open one has both.
    private func walkMenuBar(_ bar: AXUIElement, nodes: inout [AXNode], count: inout Int, truncated: inout Bool) {
        guard let items: [AXUIElement] = AX.attr(bar, kAXChildrenAttribute), !items.isEmpty else { return }
        let barKey = "mb"
        nodes.append(AXNode(element: bar, role: "AXMenuBar", subrole: nil, title: nil, value: nil, description: nil,
                            identifier: nil, placeholder: nil, frame: AX.frame(bar), enabled: true, focused: false,
                            selected: false, actions: [], settable: false, offscreen: false, depth: 0, key: barKey))
        count += 1
        for (i, item) in items.enumerated() {
            if count >= maxNodes { truncated = true; return }
            let a = AX.attrs(item, [kAXTitleAttribute, kAXSelectedAttribute, kAXEnabledAttribute, kAXChildrenAttribute])
            let title = AX.string(a[kAXTitleAttribute]) ?? ""
            if title == "Apple" { continue } // the system menu, not the app's (Sky omits it too)
            let selected = (a[kAXSelectedAttribute] as? Bool) ?? false
            let key = "\(barKey)/AXMenuBarItem[\(title)]#\(i)"
            nodes.append(AXNode(element: item, role: "AXMenuBarItem", subrole: nil, title: title.isEmpty ? nil : title,
                                value: nil, description: nil, identifier: nil, placeholder: nil, frame: AX.frame(item),
                                enabled: (a[kAXEnabledAttribute] as? Bool) ?? true, focused: false, selected: selected,
                                actions: AX.actions(item), settable: false, offscreen: false, depth: 1, key: key))
            count += 1
            // Only an open menu is worth rendering; closed ones are reachable by clicking the title.
            for menu in (a[kAXChildrenAttribute] as? [AXUIElement]) ?? [] {
                guard let mf = AX.frame(menu), mf.width > 0, mf.height > 0,
                      let visible: [AXUIElement] = AX.attr(menu, kAXVisibleChildrenAttribute), !visible.isEmpty else { continue }
                walk(menu, depth: 2, parentKey: key, siblingOrdinal: 0, windowFrame: mf,
                     nodes: &nodes, count: &count, truncated: &truncated)
            }
        }
    }

    private func walk(_ el: AXUIElement, depth: Int, parentKey: String, siblingOrdinal: Int,
                      windowFrame: CGRect, nodes: inout [AXNode], count: inout Int, truncated: inout Bool) {
        if AX.budget?.expired == true || count >= maxNodes || depth > maxDepth { truncated = true; return }
        count += 1
        let a = AX.attrs(el, AXWalker.batchAttributes)
        let role = (a[kAXRoleAttribute] as? String) ?? "AXUnknown"
        let subrole = a[kAXSubroleAttribute] as? String
        let title = AX.string(a[kAXTitleAttribute])
        // Never surface what is typed into a password field.
        let value = role == "AXSecureTextField" ? (AX.string(a[kAXValueAttribute]) == nil ? nil : "••••••") : AX.string(a[kAXValueAttribute])
        let description = AX.string(a[kAXDescriptionAttribute])
        let identifier = AX.usefulIdentifier(AX.string(a[kAXIdentifierAttribute], limit: 200))
        let placeholder = AX.string(a[kAXPlaceholderValueAttribute])
        var frame: CGRect?
        if let p = AX.point(a[kAXPositionAttribute]), let s = AX.size(a[kAXSizeAttribute]) {
            frame = CGRect(origin: p, size: s)
        }
        let enabled = (a[kAXEnabledAttribute] as? Bool) ?? true
        let focused = (a[kAXFocusedAttribute] as? Bool) ?? false
        let selected = (a[kAXSelectedAttribute] as? Bool) ?? false
        let children = (a[kAXChildrenAttribute] as? [AXUIElement]) ?? []

        // Zero-size subtrees are skipped (hidden tabs, collapsed panes). Off-window elements are
        // kept and flagged: their coordinates are untrustworthy but AX actions on them work.
        var offscreen = false
        if clipToWindow, let f = frame, depth > 0 {
            if f.width <= 0 || f.height <= 0 { return }
            offscreen = !f.intersects(windowFrame.insetBy(dx: -1, dy: -1))
            // Do not prune subtrees based on hit-testing. SwiftUI overlays can
            // intercept every sampled point while the underlying controls remain
            // visible and accessible (e.g. Gameday's zoomed Sideline field).
            // Returning extra inactive-tab nodes is preferable to losing live UI.
        }

        let label = identifier ?? title ?? description ?? placeholder ?? ""
        if role == "AXMenuItem" && title == nil && description == nil && value == nil { return } // separator
        let key = "\(parentKey)/\(role)[\(label)]#\(siblingOrdinal)"
        let actions = AX.actions(el)
        let settable = (value != nil || AXWalker.editableRoles.contains(role)) && AX.isSettable(el, kAXValueAttribute)
        let informative = title != nil || value != nil || description != nil || identifier != nil
            || placeholder != nil || focused || selected
            || !actions.filter { !AXWalker.hiddenActions.contains($0) }.isEmpty
        let render = depth == 0 || !AXWalker.containerRoles.contains(role) || informative

        var unavailableFields:[String]=[]
        let missing=AX.budget?.metadataFailures[CFHash(el)] ?? []
        if missing.contains(kAXIdentifierAttribute) {unavailableFields.append("identifier")}
        if missing.contains(kAXDescriptionAttribute),title == nil {unavailableFields.append("label")}
        var childDepth = depth
        if render {
            nodes.append(AXNode(element: el, role: role, subrole: subrole, title: title, value: value,
                                description: description, identifier: identifier, placeholder: placeholder,
                                frame: frame, enabled: enabled, focused: focused, selected: selected,
                                actions: actions, settable: settable, offscreen: offscreen, depth: depth, key: key,
                                capturedValue: role == "AXSecureTextField" ? nil : (a[kAXValueAttribute] as? String).map {String($0.prefix(65536))},
                                valueLimited: role != "AXSecureTextField" && ((a[kAXValueAttribute] as? String)?.count ?? 0)>65536, unavailableFields:unavailableFields))
            childDepth = depth + 1
        }

        // Ordinal among siblings that would produce the same key prefix keeps keys stable
        // when unrelated siblings are inserted or removed.
        var ordinals: [String: Int] = [:]
        for child in children {
            let ca = AX.attrs(child, [kAXRoleAttribute, kAXIdentifierAttribute, kAXTitleAttribute])
            let crole = (ca[kAXRoleAttribute] as? String) ?? "AXUnknown"
            let clabel = AX.usefulIdentifier(AX.string(ca[kAXIdentifierAttribute], limit: 200)) ?? AX.string(ca[kAXTitleAttribute]) ?? ""
            let sig = "\(crole)[\(clabel)]"
            let ordinal = ordinals[sig, default: 0]
            ordinals[sig] = ordinal + 1
            walk(child, depth: childDepth, parentKey: key, siblingOrdinal: ordinal, windowFrame: windowFrame,
                 nodes: &nodes, count: &count, truncated: &truncated)
            if truncated { return }
        }
    }
}
