import ApplicationServices
import AppKit
import Foundation

/// Coordinates app sessions and executes actions. One instance per server.
public actor Engine {
    var sessions: [pid_t: AppSession] = [:]
    public var walker = AXWalker()
    /// Wait after an input action before the next state capture so the UI can settle.
    public var settleDelay: TimeInterval = 0.6

    public init() {}

    // MARK: - Sessions

    public func session(for query: String, launch: Bool = true) async throws -> AppSession {
        let app = try await AppResolver.resolve(query, launch: launch)
        if let s = sessions[app.processIdentifier], !s.app.isTerminated { return s }
        let s = AppSession(app: app)
        sessions[app.processIdentifier] = s
        return s
    }

    func requireAX() throws {
        guard Permissions.accessibilityTrusted() else {
            throw LeapError.permission("Accessibility permission is missing for this process. Grant it in System Settings › Privacy & Security › Accessibility (the entry is the app that launched claude-leap, e.g. Claude), then retry.")
        }
    }

    /// Poll for a key window (apps that were just launched need a moment).
    func waitForWindow(_ s: AppSession, timeout: TimeInterval = 6) async throws -> AXUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            if let w = walker.keyWindow(of: s.axApp) { return w }
            if Date() > deadline { throw LeapError.noWindow(s.displayName) }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    // MARK: - State

    public struct StateOptions {
        public var includeScreenshot = true
        public var disableDiff = false
        public var scale: CGFloat = 1.0
        public var jpegQuality: CGFloat? = 0.8
        public init() {}
    }

    public struct State {
        public var text: String
        public var screenshot: Screenshot?
        public var warning: String?
    }

    public func state(app query: String, _ opts: StateOptions = .init()) async throws -> State {
        try requireAX()
        let s = try await session(for: query)
        return try await state(session: s, opts)
    }

    public func state(session s: AppSession, _ opts: StateOptions = .init()) async throws -> State {
        try requireAX()
        try await settle(s)
        let window = try await waitForWindow(s)
        guard let snap = walker.snapshot(window: window, app: s.axApp) else {
            throw LeapError.axFailure("window frame", .cannotComplete)
        }
        let (full, diff) = s.render(snap, walker: walker)
        var text = (opts.disableDiff ? full : (diff ?? full))
        var shot: Screenshot?
        var warning: String?
        if opts.includeScreenshot {
            if let info = WindowInfo.match(pid: s.pid, frame: snap.frame, title: snap.title) {
                do {
                    shot = try await Capture.window(info, scale: opts.scale, jpegQuality: opts.jpegQuality)
                    text += "\n(screenshot: \(shot!.pixelWidth)x\(shot!.pixelHeight) px, \(String(format: "%.2f", shot!.pointsPerPixel)) points/px)"
                } catch {
                    warning = "\(error)"
                    text += "\n(screenshot unavailable: \(error))"
                }
            } else {
                text += "\n(screenshot unavailable: window is not on screen — minimized or on another Space)"
            }
        }
        return State(text: text, screenshot: shot, warning: warning)
    }

    func settle(_ s: AppSession) async throws {
        let since = Date().timeIntervalSince(s.lastActionAt)
        if since < settleDelay {
            try await Task.sleep(nanoseconds: UInt64((settleDelay - since) * 1_000_000_000))
        }
    }

    // MARK: - Actions

    public struct Target {
        public var elementIndex: Int?
        public var x: CGFloat?
        public var y: CGFloat?
        public init(elementIndex: Int? = nil, x: CGFloat? = nil, y: CGFloat? = nil) {
            self.elementIndex = elementIndex; self.x = x; self.y = y
        }
    }

    /// Make sure the session has an indexed snapshot so element_index / window-relative
    /// coordinates resolve even when the caller skipped get_app_state.
    func ensureIndexed(_ s: AppSession) async throws {
        guard s.elements.isEmpty else { return }
        let window = try await waitForWindow(s)
        guard let snap = walker.snapshot(window: window, app: s.axApp) else {
            throw LeapError.axFailure("window frame", .cannotComplete)
        }
        _ = s.render(snap, walker: walker)
    }

    /// Resolve a target to a screen point. Window-relative coordinates are offset by the
    /// window frame captured in the latest state.
    func screenPoint(_ s: AppSession, _ t: Target) throws -> (CGPoint, ElementRecord?) {
        if let i = t.elementIndex {
            let rec = try s.element(i)
            guard let f = rec.node.frame else { throw LeapError.unsupported("element \(i) has no frame; use coordinates") }
            var p = CGPoint(x: f.midX, y: f.midY)
            if let x = t.x, let y = t.y { p = CGPoint(x: f.minX + x, y: f.minY + y) }
            return (p, rec)
        }
        guard let x = t.x, let y = t.y else { throw LeapError.unsupported("provide element_index or both x and y") }
        let wf = s.lastWindowFrame
        return (CGPoint(x: wf.minX + x, y: wf.minY + y), nil)
    }

    /// How synthesized input reaches the app.
    public struct InputMode {
        /// Activate the app and leave it frontmost afterwards.
        public var foreground = false
        /// Deliver with `postToPid` without ever activating. Works for Chromium/Electron-style
        /// apps; AppKit/SwiftUI drop events for apps without a key window.
        public var keepBackground = false
        public init(foreground: Bool = false, keepBackground: Bool = false) {
            self.foreground = foreground; self.keepBackground = keepBackground
        }
    }

    /// Runs `body` with the app able to receive real input events. Unless the app is already
    /// frontmost (or `keepBackground` is set), it is activated for the duration of the call and
    /// the previously frontmost app is restored afterwards, so the user's focus survives.
    func withInput<T>(_ s: AppSession, _ mode: InputMode, _ body: (Delivery) throws -> T) async throws -> T {
        if mode.keepBackground { return try body(.app(s.pid)) }
        if mode.foreground {
            try await activate(s)
            return try body(.system)
        }
        if s.app.isActive { return try body(.system) }
        let previous = NSWorkspace.shared.frontmostApplication
        try await activate(s)
        let result = try body(.system)
        // Let the HID queue drain into the target before handing focus back.
        try await Task.sleep(nanoseconds: 120_000_000)
        if let previous, previous.processIdentifier != s.pid, !previous.isTerminated {
            Self.bringToFront(previous)
        }
        return result
    }

    /// Activate the app and *verify* it became frontmost. Never returns normally while another
    /// app is active, so synthesized HID events can't leak into the user's current app.
    func activate(_ s: AppSession) async throws {
        guard !s.app.isActive else { return }
        Self.bringToFront(s.app)
        var deadline = Date().addingTimeInterval(1.0)
        while !s.app.isActive && Date() < deadline {
            try await Task.sleep(nanoseconds: 30_000_000)
        }
        if !s.app.isActive, let url = s.app.bundleURL {
            // LaunchServices fallback (works for apps that ignore AX frontmost).
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            _ = try? await NSWorkspace.shared.openApplication(at: url, configuration: config)
            deadline = Date().addingTimeInterval(1.5)
            while !s.app.isActive && Date() < deadline {
                try await Task.sleep(nanoseconds: 30_000_000)
            }
        }
        guard s.app.isActive else {
            throw LeapError.unsupported("Could not bring \(s.displayName) to the front to deliver input (macOS refused activation). No events were sent. Use an accessibility action (click by element_index / set_value) or retry with foreground=true.")
        }
        try await Task.sleep(nanoseconds: 80_000_000) // key window + first responder settle
    }

    /// Accessibility-based activation works from any AX-trusted process, unlike
    /// `NSRunningApplication.activate()` which macOS 14 ignores for non-frontmost callers.
    static func bringToFront(_ app: NSRunningApplication) {
        let ax = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetAttributeValue(ax, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        if let window: AXUIElement = AX.attr(ax, kAXFocusedWindowAttribute) ?? AX.attr(ax, kAXMainWindowAttribute) {
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        }
        app.activate()
    }

    public func click(app query: String, target: Target, button: MouseButton = .left, count: Int = 1,
                      modifiers: String? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        let (p, rec) = try screenPoint(s, target)
        let flags = try modifierFlags(modifiers)
        defer { s.lastActionAt = Date() }
        // Prefer the AX action: no synthesized events, no focus change, works for background apps.
        if let rec, button == .left, count == 1, flags.isEmpty, target.x == nil, !mode.foreground,
           rec.node.actions.contains(kAXPressAction) {
            let err = AXUIElementPerformAction(rec.node.element, kAXPressAction as CFString)
            if err == .success { return "pressed [\(rec.index)] via accessibility" }
        }
        try await withInput(s, mode) { d in Input.click(at: p, button: button, count: count, flags: flags, d) }
        return "clicked \(button.rawValue)×\(count) at window (\(Int(p.x - s.lastWindowFrame.minX)),\(Int(p.y - s.lastWindowFrame.minY)))" + (rec.map { " on [\($0.index)]" } ?? "")
    }

    public func drag(app query: String, from: Target, to: Target, steps: Int = 12, modifiers: String? = nil,
                     mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        let (a, _) = try screenPoint(s, from)
        let (b, _) = try screenPoint(s, to)
        let flags = try modifierFlags(modifiers)
        defer { s.lastActionAt = Date() }
        try await withInput(s, mode) { d in Input.drag(from: a, to: b, flags: flags, steps: steps, d) }
        return "dragged"
    }

    public func scroll(app query: String, target: Target, direction: String, pages: Double = 1,
                       pixels: Int? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        let (p, rec) = try screenPoint(s, target)
        let extent = rec?.node.frame ?? s.lastWindowFrame
        defer { s.lastActionAt = Date() }
        var dx: Int32 = 0, dy: Int32 = 0
        let vertical = Int32(pixels.map { Double($0) } ?? (Double(extent.height) * 0.85 * pages))
        let horizontal = Int32(pixels.map { Double($0) } ?? (Double(extent.width) * 0.85 * pages))
        switch direction.lowercased() {
        case "down", "d": dy = -vertical
        case "up", "u": dy = vertical
        case "right", "r": dx = -horizontal
        case "left", "l": dx = horizontal
        default: throw LeapError.unsupported("direction must be up/down/left/right")
        }
        try await withInput(s, mode) { d in Input.scroll(at: p, dx: dx, dy: dy, d) }
        return "scrolled \(direction)"
    }

    public func pressKey(app query: String, key: String, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        let chord = try Keys.parse(key)
        defer { s.lastActionAt = Date() }
        try await withInput(s, mode) { d in Input.press(chord, d) }
        return "pressed \(key)"
    }

    public func typeText(app query: String, text: String, elementIndex: Int? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        defer { s.lastActionAt = Date() }
        if let i = elementIndex {
            let rec = try s.element(i)
            // Background-safe path: insert through the text system so bindings/notifications fire.
            if !mode.foreground, AX.insertText(rec.node.element, text, replaceAll: false) {
                return "inserted \(text.count) characters into [\(i)] via accessibility"
            }
            AXUIElementSetAttributeValue(rec.node.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            usleep(80_000)
        }
        try await withInput(s, mode) { d in Input.type(text, d) }
        return "typed \(text.count) characters"
    }

    public func setValue(app query: String, elementIndex: Int, value: String) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        let rec = try s.element(elementIndex)
        defer { s.lastActionAt = Date() }
        // 1. Text elements: replace the selection through the text system (fires change notifications,
        //    so SwiftUI/AppKit bindings update — a raw kAXValue write often does not).
        if AX.insertText(rec.node.element, value, replaceAll: true) {
            return "replaced text of [\(elementIndex)] via accessibility selection"
        }
        // 2. Generic settable value (sliders, checkboxes, steppers, non-text fields).
        let err = AXUIElementSetAttributeValue(rec.node.element, kAXValueAttribute as CFString, value as CFTypeRef)
        if err == .success { return "set value of [\(elementIndex)]" }
        // 3. Last resort: focus, select all, type real keystrokes.
        AXUIElementSetAttributeValue(rec.node.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        usleep(80_000)
        try await withInput(s, .init()) { d in
            Input.press(KeyChord(keyCode: 0, flags: .maskCommand), d) // ⌘A
            Input.type(value, d)
        }
        return "AX set failed (\(err.name)); focused [\(elementIndex)], selected all and typed instead"
    }

    public func performAction(app query: String, elementIndex: Int, action: String) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        let rec = try s.element(elementIndex)
        let wanted = action.lowercased().replacingOccurrences(of: " ", with: "")
        guard let name = rec.node.actions.first(where: {
            let n = $0.lowercased()
            return n == wanted || n == "ax" + wanted || n.dropFirst(2) == wanted
        }) else {
            throw LeapError.unsupported("element [\(elementIndex)] does not expose \"\(action)\"; available: \(rec.node.actions.joined(separator: ", "))")
        }
        defer { s.lastActionAt = Date() }
        let err = AXUIElementPerformAction(rec.node.element, name as CFString)
        guard err == .success else { throw LeapError.axFailure(name, err) }
        return "performed \(name) on [\(elementIndex)]"
    }

    public func paste(app query: String, text: String, html: String? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await session(for: query)
        try await ensureIndexed(s)
        defer { s.lastActionAt = Date() }
        try await withInput(s, mode) { d in Input.paste(text, html: html, d) }
        return "pasted \(text.count) characters"
    }

    /// Frame of the app's key window in screen points (used for window-center defaults).
    public func windowFrame(app query: String) async throws -> CGRect {
        try requireAX()
        let s = try await session(for: query)
        let window = try await waitForWindow(s)
        guard let frame = AX.frame(window) else { throw LeapError.noWindow(s.displayName) }
        return frame
    }

    public func activate(app query: String) async throws -> String {
        let s = try await session(for: query)
        s.app.activate()
        return "activated \(s.displayName)"
    }

    public func screenshot(app query: String, region: CGRect? = nil, scale: CGFloat = 1.0) async throws -> Screenshot {
        try requireAX()
        let s = try await session(for: query)
        let window = try await waitForWindow(s)
        guard let frame = AX.frame(window) else { throw LeapError.noWindow(s.displayName) }
        let title: String? = AX.attr(window, kAXTitleAttribute)
        guard let info = WindowInfo.match(pid: s.pid, frame: frame, title: title) else {
            throw LeapError.capture("window is not on screen")
        }
        return try await Capture.window(info, scale: scale, jpegQuality: 0.85, region: region)
    }

    func modifierFlags(_ text: String?) throws -> CGEventFlags {
        guard let text, !text.isEmpty else { return [] }
        var flags: CGEventFlags = []
        for part in text.split(separator: "+") {
            guard let f = Keys.modifiers[part.trimmingCharacters(in: .whitespaces).lowercased()] else {
                throw LeapError.unsupported("unknown modifier \"\(part)\"")
            }
            flags.insert(f)
        }
        return flags
    }
}
