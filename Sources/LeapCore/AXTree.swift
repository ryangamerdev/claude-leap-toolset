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
    public let depth: Int
    public let key: String
}

public struct AXWindowSnapshot {
    public let window: AXUIElement
    public let title: String?
    public let frame: CGRect
    public let focusedElement: AXUIElement?
    public let nodes: [AXNode]
    public let truncated: Bool
}

enum AX {
    static func attr<T>(_ el: AXUIElement, _ name: String) -> T? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success, let v else { return nil }
        return v as? T
    }

    static func attrs(_ el: AXUIElement, _ names: [String]) -> [String: CFTypeRef] {
        var out: CFArray?
        let status = AXUIElementCopyMultipleAttributeValues(el, names as CFArray, [], &out)
        guard status == .success, let values = out as? [CFTypeRef?] else { return [:] }
        var dict: [String: CFTypeRef] = [:]
        for (name, value) in zip(names, values) {
            guard let value, CFGetTypeID(value) != AXValueGetTypeID() || AXValueGetType(value as! AXValue) != .axError else { continue }
            dict[name] = value
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
        var names: CFArray?
        guard AXUIElementCopyActionNames(el, &names) == .success, let arr = names as? [String] else { return [] }
        return arr
    }

    /// Insert `text` at the element's selection (or replace all of its text) through the
    /// accessibility text API. Returns false when the element is not a text element.
    static func insertText(_ el: AXUIElement, _ text: String, replaceAll: Bool) -> Bool {
        // Only text elements expose a selection; skip everything else quickly.
        let probe: CFTypeRef? = attr(el, kAXSelectedTextRangeAttribute)
        guard probe != nil || isSettable(el, kAXSelectedTextAttribute) else { return false }
        // Many fields (SwiftUI especially) only accept selection edits while focused.
        AXUIElementSetAttributeValue(el, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        usleep(60_000)
        if replaceAll {
            let count: Int = attr(el, kAXNumberOfCharactersAttribute) ?? (attr(el, kAXValueAttribute) as String?)?.count ?? 0
            var range = CFRange(location: 0, length: count)
            if let axRange = AXValueCreate(.cfRange, &range) {
                AXUIElementSetAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, axRange)
            }
        }
        return AXUIElementSetAttributeValue(el, kAXSelectedTextAttribute as CFString, text as CFTypeRef) == .success
    }

    static func isSettable(_ el: AXUIElement, _ name: String) -> Bool {
        var settable: DarwinBoolean = false
        return AXUIElementIsAttributeSettable(el, name as CFString, &settable) == .success && settable.boolValue
    }

    /// SwiftUI leaks mangled type names into AXIdentifier
    /// ("SwiftUI.ModifiedContent<...>-1-AppWindow-1"); they cost tokens and carry no meaning.
    static func usefulIdentifier(_ id: String?) -> String? {
        guard let id else { return nil }
        if id.contains("SwiftUI.") || id.contains("ModifiedContent<") || id.count > 64 { return nil }
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

    static let hiddenActions: Set<String> = ["AXPress", "AXScrollToVisible", "AXRaise"]

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

    public func snapshot(window: AXUIElement, app: AXUIElement) -> AXWindowSnapshot? {
        guard let frame = AX.frame(window) else { return nil }
        let title: String? = AX.attr(window, kAXTitleAttribute)
        let focused: AXUIElement? = AX.attr(app, kAXFocusedUIElementAttribute)
        var nodes: [AXNode] = []
        var count = 0
        var truncated = false
        walk(window, depth: 0, parentKey: "w", siblingOrdinal: 0, windowFrame: frame,
             nodes: &nodes, count: &count, truncated: &truncated)
        return AXWindowSnapshot(window: window, title: title, frame: frame, focusedElement: focused,
                                nodes: nodes, truncated: truncated)
    }

    private func walk(_ el: AXUIElement, depth: Int, parentKey: String, siblingOrdinal: Int,
                      windowFrame: CGRect, nodes: inout [AXNode], count: inout Int, truncated: inout Bool) {
        if count >= maxNodes || depth > maxDepth { truncated = true; return }
        count += 1
        let a = AX.attrs(el, AXWalker.batchAttributes)
        let role = (a[kAXRoleAttribute] as? String) ?? "AXUnknown"
        let subrole = a[kAXSubroleAttribute] as? String
        let title = AX.string(a[kAXTitleAttribute])
        let value = AX.string(a[kAXValueAttribute])
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

        // Offscreen / zero-size subtrees are skipped entirely (hidden tabs, collapsed panes).
        if clipToWindow, let f = frame, depth > 0 {
            if f.width <= 0 || f.height <= 0 || !f.intersects(windowFrame.insetBy(dx: -1, dy: -1)) {
                return
            }
        }

        let label = identifier ?? title ?? description ?? placeholder ?? ""
        let key = "\(parentKey)/\(role)[\(label)]#\(siblingOrdinal)"
        let actions = AX.actions(el)
        let settable = (value != nil || AXWalker.editableRoles.contains(role)) && AX.isSettable(el, kAXValueAttribute)
        let informative = title != nil || value != nil || description != nil || identifier != nil
            || placeholder != nil || focused || selected
            || !actions.filter { !AXWalker.hiddenActions.contains($0) }.isEmpty
        let render = depth == 0 || !AXWalker.containerRoles.contains(role) || informative

        var childDepth = depth
        if render {
            nodes.append(AXNode(element: el, role: role, subrole: subrole, title: title, value: value,
                                description: description, identifier: identifier, placeholder: placeholder,
                                frame: frame, enabled: enabled, focused: focused, selected: selected,
                                actions: actions, settable: settable, depth: depth, key: key))
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
