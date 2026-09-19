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

    /// bundle path → pid of the session we last handed out for that app, so a relaunch
    /// (new pid, same app) is recognised and reported instead of silently re-indexed.
    var pidByIdentity: [String: pid_t] = [:]

    public func session(for query: String, launch: Bool = true) async throws -> AppSession {
        let app = try await AppResolver.resolve(query, launch: launch)
        if let s = sessions[app.processIdentifier], !s.app.isTerminated { return s }
        let identity = app.bundleURL?.path ?? app.bundleIdentifier ?? "pid \(app.processIdentifier)"
        let s = AppSession(app: app)
        if let oldPid = pidByIdentity[identity], oldPid != app.processIdentifier, sessions[oldPid] != nil {
            sessions[oldPid] = nil
            s.relaunchedFrom = oldPid
        }
        sessions[app.processIdentifier] = s
        pidByIdentity[identity] = app.processIdentifier
        return s
    }

    /// Session for an *action*. Refuses — like Sky's "The user changed '<app>'" and "Computer
    /// Use is not active for '<app>'" errors — when the process was replaced since the last
    /// state, or when an element_index/label arrives before any state was ever read: in both
    /// cases the caller's indices refer to a tree it has not seen. Coordinate-only actions
    /// still index silently (they only need the window frame).
    func actionSession(_ query: String, needsElements: Bool) async throws -> AppSession {
        let s = try await session(for: query)
        if s.relaunchedFrom != nil { throw LeapError.processChanged(s.displayName) }
        if needsElements && s.elements.isEmpty { throw LeapError.notActive(s.displayName) }
        try await ensureIndexed(s)
        return s
    }

    func requireAX() throws {
        guard Permissions.accessibilityTrusted() else {
            throw LeapError.permission("Accessibility permission is missing for this process. Grant it in System Settings › Privacy & Security › Accessibility (the entry is the app that launched claude-leap, e.g. Claude), then retry.")
        }
    }

    /// All of the app's windows with their titles (for the state header and `window:` targeting).
    func windows(_ s: AppSession) -> [(AXUIElement, String)] {
        let ws: [AXUIElement] = AX.attr(s.axApp, kAXWindowsAttribute) ?? []
        return ws.map { ($0, (AX.attr($0, kAXTitleAttribute) as String?) ?? "") }
    }

    /// Poll for the target window: the pinned one (by title substring) if set, else the key window.
    /// Apps that were just launched need a moment, hence the polling.
    func waitForWindow(_ s: AppSession, timeout: TimeInterval = 6) async throws -> AXUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            if let pin = s.pinnedWindow {
                let all = windows(s)
                if let hit = all.first(where: { $0.1.localizedCaseInsensitiveContains(pin) }) { return hit.0 }
                if Date() > deadline {
                    throw LeapError.unsupported("\(s.displayName) has no window matching \"\(pin)\". Windows: " + all.map { "\"\($0.1)\"" }.joined(separator: ", "))
                }
            } else if let w = walker.keyWindow(of: s.axApp) { return w }
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
        /// Per-element window-relative frames in the tree. Off by default (Sky's tree has none;
        /// the screenshot carries geometry) — saves ~20 tokens per element.
        public var includeFrames = false
        public init() {}
    }

    public struct State {
        public var text: String
        public var screenshot: Screenshot?
        public var warning: String?
    }

    /// `announce` shows the "thinking" face over the window; used by the explicit
    /// get_app_state tool, not by the state that follows an action (which keeps the action's face).
    public func state(app query: String, _ opts: StateOptions = .init(), announce: Bool = false, window: String? = nil) async throws -> State {
        try requireAX()
        let s = try await session(for: query)
        if let window { s.pinnedWindow = window.isEmpty ? nil : window }
        let st = try await state(session: s, opts)
        if announce { await signal(indicatorPoint(s, nil), .observe) }
        return st
    }

    /// Extra time allowed after an action while the tree is still changing (loading indicators,
    /// list refreshes). Sky's runtime waits ~1 s plus up to 5 s more "if the app has a loading
    /// indicator or other signs of state changes" (its plugin skill says so); we poll for stability.
    public var maxSettleAfterAction: TimeInterval = 5.0

    public func state(session s: AppSession, _ opts: StateOptions = .init()) async throws -> State {
        try requireAX()
        try await settle(s)
        let window = try await waitForWindow(s)
        guard var snap = walker.snapshot(window: window, app: s.axApp) else {
            throw LeapError.axFailure("window frame", .cannotComplete)
        }
        // Settle until stable: two consecutive reads that agree, or the deadline.
        let sinceAction = Date().timeIntervalSince(s.lastActionAt)
        if sinceAction < maxSettleAfterAction {
            let deadline = s.lastActionAt.addingTimeInterval(settleDelay + maxSettleAfterAction)
            var previous = Self.fingerprint(snap)
            while Date() < deadline {
                try await Task.sleep(nanoseconds: 300_000_000)
                guard let again = walker.snapshot(window: window, app: s.axApp) else { break }
                let now = Self.fingerprint(again)
                let busy = again.nodes.contains { $0.role == "AXProgressIndicator" || $0.role == "AXBusyIndicator" }
                snap = again
                if now == previous && !busy { break }
                previous = now
            }
        }
        let (full, diff) = s.render(snap, walker: walker, includeFrames: opts.includeFrames)
        s.relaunchedFrom = nil
        var text = (opts.disableDiff ? full : (diff ?? full))
        // Tooltip-sized AXDialog popups (Simulator shows a 52x20 "Window") are not targets.
        let others = windows(s).filter { !CFEqual($0.0, snap.window) }
            .filter { (AX.frame($0.0).map { $0.width * $0.height } ?? 0) >= 4000 }.map { $0.1 }
        if !others.isEmpty {
            text += "\nOther windows of \(s.displayName): " + others.map { "\"\($0)\"" }.joined(separator: ", ") + " — target one with get_app_state(window: \"<title part>\")."
        }
        var shot: Screenshot?
        var warning: String?
        let info = WindowInfo.match(pid: s.pid, frame: snap.frame, title: snap.title)
        if let info { await ShareIndicator.shared.hold(info.id) }
        if opts.includeScreenshot {
            if let info {
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

    /// Cheap identity of a snapshot's visible content, for the stability poll.
    static func fingerprint(_ snap: AXWindowSnapshot) -> Int {
        var h = Hasher()
        h.combine(snap.title ?? "")
        for n in snap.nodes {
            h.combine(n.key); h.combine(n.value ?? ""); h.combine(n.title ?? ""); h.combine(n.description ?? "")
            h.combine(n.enabled); h.combine(n.selected); h.combine(n.focused)
        }
        return h.finalize()
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
    ///
    /// Background (`postToPid`) is the default and the app is *never* activated implicitly —
    /// the user keeps their mouse, keyboard and frontmost window while the agent works.
    /// Accessibility actions (press, set value, insert text, menu commands) are preferred over
    /// synthesized events precisely because they always work from the background.
    public struct InputMode {
        /// Opt in to activating the app and using real HID events. Only needed for apps that
        /// ignore posted events (some games, custom GL/Metal canvases).
        public var foreground = false
        public init(foreground: Bool = false) { self.foreground = foreground }
    }

    /// Runs `body` with the app able to receive real input events. Unless the app is already
    /// frontmost (or `keepBackground` is set), it is activated for the duration of the call and
    /// the previously frontmost app is restored afterwards, so the user's focus survives.
    /// An activation held across a sequence of actions (a `batch`), so the app is brought
    /// forward at most once and the user's app is restored at most once.
    final class FocusHold {
        let session: AppSession
        let mode: InputMode
        /// nil until an action actually needs synthesized input; AX-only batches never activate.
        var delivery: Delivery?
        var restoreTo: NSRunningApplication?
        init(session: AppSession, mode: InputMode) { self.session = session; self.mode = mode }
    }

    var hold: FocusHold?

    /// Begin a held-focus sequence. Activation is lazy: a batch that only performs
    /// accessibility actions still runs entirely in the background.
    public func beginInputSession(app query: String, mode: InputMode = .init()) async throws {
        let s = try await session(for: query)
        hold = FocusHold(session: s, mode: mode)
    }

    /// End the sequence. Nothing to restore unless the caller asked for foreground input.
    public func endInputSession() async {
        hold = nil
    }

    /// Flash the on-screen indicator (virtual pointer + sonar ripple) at a screen point.
    /// Purely cosmetic; never moves the user's real cursor.
    func signal(_ point: CGPoint?, _ ping: Overlay.Ping) async {
        guard let point else { return }
        await MainActor.run { Overlay.shared.signal(at: point, ping: ping) }
    }

    /// Screen-point centre of an element index, for the indicator.
    func indicatorPoint(_ s: AppSession, _ index: Int?) -> CGPoint? {
        if let index, let rec = try? s.element(index), let f = rec.node.frame {
            return CGPoint(x: f.midX, y: f.midY)
        }
        let w = s.lastWindowFrame
        return w.isEmpty ? nil : CGPoint(x: w.midX, y: w.midY)
    }

    func withInput<T>(_ s: AppSession, _ mode: InputMode, _ body: (Delivery) throws -> T) async throws -> T {
        let wantsForeground = mode.foreground || (hold?.session.pid == s.pid && hold?.mode.foreground == true)
        guard wantsForeground else {
            // Background: events go straight to the process. The user's frontmost app,
            // keyboard focus and real cursor are all untouched.
            return try body(.app(s.pid))
        }
        if let hold, hold.session.pid == s.pid, hold.delivery != nil {
            return try body(.system) // already activated for this batch
        }
        try await activate(s)
        hold?.delivery = .system
        return try body(.system)
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
        let s = try await actionSession(query, needsElements: target.elementIndex != nil)
        let (p, rec) = try screenPoint(s, target)
        let flags = try modifierFlags(modifiers)
        defer { s.lastActionAt = Date() }
        // Prefer the AX action: no synthesized events, no focus change, works for background apps.
        // Text elements are excluded: AXPress does not place the caret, so a later ⌘A / type
        // would act on the wrong first responder.
        if let rec, button == .left, count == 1, flags.isEmpty, target.x == nil, !mode.foreground,
           !AXWalker.textRoles.contains(rec.node.role),
           rec.node.actions.contains(kAXPressAction) {
            let err = AXUIElementPerformAction(rec.node.element, kAXPressAction as CFString)
            if err == .success {
                await signal(p, .click)
                return "pressed [\(rec.index)] via accessibility"
            }
        }
        try await withInput(s, mode) { d in Input.click(at: p, button: button, count: count, flags: flags, d) }
        await signal(p, .click)
        return "clicked \(button.rawValue)×\(count) at window (\(Int(p.x - s.lastWindowFrame.minX)),\(Int(p.y - s.lastWindowFrame.minY)))" + (rec.map { " on [\($0.index)]" } ?? "")
    }

    public func drag(app query: String, from: Target, to: Target, steps: Int = 12, modifiers: String? = nil,
                     mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: from.elementIndex != nil || to.elementIndex != nil)
        let (a, _) = try screenPoint(s, from)
        let (b, _) = try screenPoint(s, to)
        let flags = try modifierFlags(modifiers)
        defer { s.lastActionAt = Date() }
        try await withInput(s, mode) { d in Input.drag(from: a, to: b, flags: flags, steps: steps, d) }
        await MainActor.run { Overlay.shared.signalDrag(from: a, to: b) }
        return "dragged"
    }

    public func scroll(app query: String, target: Target, direction: String, pages: Double = 1,
                       pixels: Int? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: target.elementIndex != nil)
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
        await signal(p, .scroll)
        return "scrolled \(direction)"
    }

    public func pressKey(app query: String, key: String, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: false)
        let chord = try Keys.parse(key)
        defer { s.lastActionAt = Date() }
        // Accessibility first, the way the Sky service does it (its binary imports no
        // CGEventPost at all): command chords press the matching menu item, Return confirms,
        // Escape cancels. Synthesized keystrokes are the fallback, not the mechanism.
        if !mode.foreground, let done = axKeyPress(s, chord, key) {
            await signal(indicatorPoint(s, nil), .edit)
            return done
        }
        try await withInput(s, mode) { d in Input.press(chord, d) }
        await signal(indicatorPoint(s, nil), .edit)
        return "pressed \(key) (synthesized keystroke)"
    }

    /// Try to satisfy a key press through accessibility. Returns a description on success,
    /// nil when nothing in the AX tree handles it (caller falls back to keystrokes).
    func axKeyPress(_ s: AppSession, _ chord: KeyChord, _ key: String) -> String? {
        let focused: AXUIElement? = AX.attr(s.axApp, kAXFocusedUIElementAttribute)
        if chord.flags.contains(.maskCommand), let code = chord.keyCode {
            // Text editing chords: AppKit disables Edit-menu items for a background app (no key
            // window to validate against), so these go through the AX text API instead — the
            // Sky service does the same (it carries `selectAll:`, not menu presses, for this).
            let plainCommand = chord.flags.subtracting([.maskCommand, .maskNonCoalesced, .maskNumericPad]).isEmpty
            if plainCommand, let target = focused, let done = axTextCommand(target, code) { return done }
            if let item = menuItem(s, matching: chord) {
                let enabled: Bool = AX.attr(item.element, kAXEnabledAttribute) ?? true
                if enabled, AXUIElementPerformAction(item.element, kAXPressAction as CFString) == .success {
                    return "pressed menu item \"\(item.path)\" for \(key) via accessibility"
                }
                if !enabled {
                    return "menu item \"\(item.path)\" for \(key) is disabled while the app is in the background; nothing was done"
                }
            }
            return nil
        }
        guard chord.flags.isEmpty, let code = chord.keyCode else { return nil }
        if code == 53, let menu = openMenu(s) { // Escape closes an open menu-bar menu
            if AXUIElementPerformAction(menu, kAXCancelAction as CFString) == .success {
                return "closed the open menu via accessibility (Escape)"
            }
        }
        guard let target = focused else { return nil }
        let actions = AX.actions(target)
        switch code {
        case 36, 76: // Return / Enter
            if actions.contains("AXConfirm"), AXUIElementPerformAction(target, "AXConfirm" as CFString) == .success {
                return "confirmed focused element via accessibility (Return)"
            }
        case 53: // Escape
            if actions.contains("AXCancel"), AXUIElementPerformAction(target, "AXCancel" as CFString) == .success {
                return "cancelled focused element via accessibility (Escape)"
            }
        default: break
        }
        return nil
    }

    /// ⌘A / ⌘C / ⌘V / ⌘X on the focused text element through the accessibility text API.
    func axTextCommand(_ target: AXUIElement, _ code: CGKeyCode) -> String? {
        let selectedRange: CFTypeRef? = AX.attr(target, kAXSelectedTextRangeAttribute)
        guard selectedRange != nil else { return nil } // not a text element
        let length: Int = AX.attr(target, kAXNumberOfCharactersAttribute) ?? ((AX.attr(target, kAXValueAttribute) as String?)?.count ?? 0)
        func selectAll() -> Bool {
            var range = CFRange(location: 0, length: length)
            guard let v = AXValueCreate(.cfRange, &range) else { return false }
            return AXUIElementSetAttributeValue(target, kAXSelectedTextRangeAttribute as CFString, v) == .success
        }
        switch code {
        case 0: // A
            return selectAll() ? "selected all text (\(length) characters) via accessibility" : nil
        case 8: // C
            let text: String = AX.attr(target, kAXSelectedTextAttribute) ?? ""
            guard !text.isEmpty else { return "nothing selected to copy" }
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
            return "copied \(text.count) characters to the clipboard via accessibility"
        case 9: // V
            guard let text = NSPasteboard.general.string(forType: .string) else { return "clipboard has no text" }
            return AXUIElementSetAttributeValue(target, kAXSelectedTextAttribute as CFString, text as CFTypeRef) == .success
                ? "pasted \(text.count) characters via accessibility" : nil
        case 7: // X
            let text: String = AX.attr(target, kAXSelectedTextAttribute) ?? ""
            guard !text.isEmpty else { return "nothing selected to cut" }
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
            return AXUIElementSetAttributeValue(target, kAXSelectedTextAttribute as CFString, "" as CFTypeRef) == .success
                ? "cut \(text.count) characters via accessibility" : nil
        default:
            return nil
        }
    }

    /// The AXMenu of a menu-bar title that is currently open (non-zero frame, visible items).
    func openMenu(_ s: AppSession) -> AXUIElement? {
        guard let bar: AXUIElement = AX.attr(s.axApp, kAXMenuBarAttribute),
              let items: [AXUIElement] = AX.attr(bar, kAXChildrenAttribute) else { return nil }
        for item in items {
            for menu in (AX.attr(item, kAXChildrenAttribute) as [AXUIElement]?) ?? [] {
                if let f = AX.frame(menu), f.width > 0, f.height > 0 { return menu }
            }
        }
        return nil
    }

    struct MenuHit { let element: AXUIElement; let path: String }

    /// Find the menu item whose key equivalent matches the chord (Edit › Select All for ⌘A).
    /// AXMenuItemCmdModifiers bits: 1 shift, 2 option, 4 control, 8 = no command key.
    func menuItem(_ s: AppSession, matching chord: KeyChord) -> MenuHit? {
        guard let code = chord.keyCode else { return nil }
        var want = 0
        if chord.flags.contains(.maskShift) { want |= 1 }
        if chord.flags.contains(.maskAlternate) { want |= 2 }
        if chord.flags.contains(.maskControl) { want |= 4 }
        let wantChar = Keys.character(for: code).map { String($0).uppercased() }
        guard let bar: AXUIElement = AX.attr(s.axApp, kAXMenuBarAttribute) else { return nil }
        func search(_ el: AXUIElement, _ path: [String], _ depth: Int) -> MenuHit? {
            guard depth < 6, let kids: [AXUIElement] = AX.attr(el, kAXChildrenAttribute) else { return nil }
            for kid in kids {
                let a = AX.attrs(kid, [kAXRoleAttribute, kAXTitleAttribute, "AXMenuItemCmdChar", "AXMenuItemCmdModifiers", "AXMenuItemCmdVirtualKey"])
                let role = a[kAXRoleAttribute] as? String ?? ""
                let title = a[kAXTitleAttribute] as? String ?? ""
                if role == "AXMenuItem" {
                    let mods = (a["AXMenuItemCmdModifiers"] as? NSNumber)?.intValue ?? 8
                    let cmdChar = (a["AXMenuItemCmdChar"] as? String ?? "").uppercased()
                    let vkey = (a["AXMenuItemCmdVirtualKey"] as? NSNumber)?.intValue
                    let charHit = wantChar != nil && !cmdChar.isEmpty && cmdChar == wantChar
                    let keyHit = vkey != nil && vkey == Int(code)
                    if (charHit || keyHit) && (mods & 7) == want && (mods & 8) == 0 {
                        return MenuHit(element: kid, path: (path + [title]).joined(separator: " › "))
                    }
                }
                if let hit = search(kid, role == "AXMenu" ? path : path + [title].filter { !$0.isEmpty }, depth + 1) { return hit }
            }
            return nil
        }
        return search(bar, [], 0)
    }

    public func typeText(app query: String, text: String, elementIndex: Int? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: elementIndex != nil)
        defer { s.lastActionAt = Date() }
        if let i = elementIndex {
            let rec = try s.element(i)
            // Background-safe path: insert through the text system so bindings/notifications fire.
            if !mode.foreground, AX.insertText(rec.node.element, text, replaceAll: false) {
                await signal(indicatorPoint(s, i), .edit)
                return "inserted \(text.count) characters into [\(i)] via accessibility"
            }
            // iOS Simulator fields (and some others) expose no selection API, and a background
            // Simulator ignores posted keystrokes — the recorded Codex session shows Sky's
            // typeText silently typing nothing there while setValue worked every time. So
            // append through the value attribute instead, and read it back before claiming success.
            if !mode.foreground, rec.node.settable, let appended = AX.appendValue(rec.node.element, text, placeholder: rec.node.placeholder) {
                await signal(indicatorPoint(s, i), .edit)
                return "appended \(text.count) characters to [\(i)] via accessibility value (now \"\(appended.prefix(60))\")"
            }
            AXUIElementSetAttributeValue(rec.node.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            usleep(80_000)
        }
        try await withInput(s, mode) { d in Input.type(text, d) }
        await signal(indicatorPoint(s, elementIndex), .edit)
        return "typed \(text.count) characters"
    }

    public func setValue(app query: String, elementIndex: Int, value: String, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: true)
        let rec = try s.element(elementIndex)
        defer { s.lastActionAt = Date() }
        // 1. Text elements: replace the selection through the text system (fires change notifications,
        //    so SwiftUI/AppKit bindings update — a raw kAXValue write often does not).
        if AX.insertText(rec.node.element, value, replaceAll: true) {
            await signal(indicatorPoint(s, elementIndex), .edit)
            return "replaced text of [\(elementIndex)] via accessibility selection"
        }
        // 2. Generic settable value (sliders, checkboxes, steppers, non-text fields).
        let err = AXUIElementSetAttributeValue(rec.node.element, kAXValueAttribute as CFString, value as CFTypeRef)
        if err == .success {
            // Read back before claiming success: iOS Simulator fields answer success and keep
            // the old text for some writes (an empty string, for one).
            usleep(80_000)
            let after: String = AX.attr(rec.node.element, kAXValueAttribute) ?? ""
            if after == value || (value.isEmpty && after == rec.node.placeholder) {
                await signal(indicatorPoint(s, elementIndex), .edit)
                return "set value of [\(elementIndex)]"
            }
            if !mode.foreground && !s.app.isActive {
                throw LeapError.unsupported("[\(elementIndex)] accepted the value write but still reads \"\(after.prefix(60))\" (wanted \"\(value.prefix(60))\"). Nothing else was tried because the app is in the background; try set_value with different text, or foreground=true.")
            }
        }
        // 3. Last resort: focus, select all, type real keystrokes.
        AXUIElementSetAttributeValue(rec.node.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        usleep(80_000)
        try await withInput(s, mode) { d in
            Input.press(KeyChord(keyCode: 0, flags: .maskCommand), d) // ⌘A
            Input.type(value, d)
        }
        return "AX set failed (\(err.name)); focused [\(elementIndex)], selected all and typed instead"
    }

    public func performAction(app query: String, elementIndex: Int, action: String) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: true)
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
        await signal(indicatorPoint(s, elementIndex), .click)
        return "performed \(name) on [\(elementIndex)]"
    }

    public func paste(app query: String, text: String, html: String? = nil, mode: InputMode = .init()) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: false)
        defer { s.lastActionAt = Date() }
        try await withInput(s, mode) { d in Input.paste(text, html: html, d) }
        await signal(indicatorPoint(s, nil), .edit)
        return "pasted \(text.count) characters"
    }

    public enum SelectionType: String { case text, cursorBefore = "cursor_before", cursorAfter = "cursor_after" }

    /// Select `text` inside an editable element (or place the caret before/after it), through
    /// the accessibility selected-text range — Sky's `select_text(prefix, suffix, selection_type)`.
    public func selectText(app query: String, elementIndex: Int, text: String, prefix: String? = nil,
                           suffix: String? = nil, selection: SelectionType = .text) async throws -> String {
        try requireAX()
        let s = try await actionSession(query, needsElements: true)
        let rec = try s.element(elementIndex)
        let el = rec.node.element
        guard AX.isSettable(el, kAXSelectedTextRangeAttribute) else {
            throw LeapError.unsupported("[\(elementIndex)] \(rec.node.role.dropFirst(2)) has no selectable text range; select_text needs a text field/area.")
        }
        let value: String = AX.attr(el, kAXValueAttribute) ?? ""
        let needle = (prefix ?? "") + text + (suffix ?? "")
        let hits = value.ranges(of: needle)
        guard let hit = hits.first else {
            throw LeapError.unsupported("\"\(needle)\" does not occur in [\(elementIndex)] (value is \"\(value.prefix(120))\").")
        }
        if hits.count > 1 {
            throw LeapError.unsupported("\"\(needle)\" occurs \(hits.count) times in [\(elementIndex)]; add prefix/suffix to disambiguate.")
        }
        let utf16 = value.utf16
        let start = utf16.distance(from: utf16.startIndex, to: hit.lowerBound.samePosition(in: utf16)!) + (prefix ?? "").utf16.count
        let length = text.utf16.count
        var range: CFRange
        switch selection {
        case .text: range = CFRange(location: start, length: length)
        case .cursorBefore: range = CFRange(location: start, length: 0)
        case .cursorAfter: range = CFRange(location: start + length, length: 0)
        }
        defer { s.lastActionAt = Date() }
        AXUIElementSetAttributeValue(el, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        usleep(60_000)
        guard let axRange = AXValueCreate(.cfRange, &range),
              AXUIElementSetAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, axRange) == .success else {
            throw LeapError.axFailure("set selected text range", .cannotComplete)
        }
        // Verify.
        var got = CFRange(location: -1, length: -1)
        if let v: CFTypeRef = AX.attr(el, kAXSelectedTextRangeAttribute), CFGetTypeID(v) == AXValueGetTypeID() {
            AXValueGetValue(v as! AXValue, .cfRange, &got)
        }
        guard got.location == range.location, got.length == range.length else {
            throw LeapError.unsupported("[\(elementIndex)] accepted the selection but reports range \(got.location)+\(got.length) instead of \(range.location)+\(range.length).")
        }
        await signal(indicatorPoint(s, elementIndex), .edit)
        switch selection {
        case .text: return "selected \"\(text)\" in [\(elementIndex)] (characters \(start)–\(start + length))"
        case .cursorBefore: return "placed the caret before \"\(text)\" in [\(elementIndex)]"
        case .cursorAfter: return "placed the caret after \"\(text)\" in [\(elementIndex)]"
        }
    }

    /// Resolve a human label (title / description / value / placeholder) to an element index
    /// in the latest state. Exact (case-insensitive) matches win; otherwise a unique substring
    /// match; otherwise an error listing the candidates so the model can pick.
    public func findElement(app query: String, label: String) async throws -> Int {
        try requireAX()
        let s = try await actionSession(query, needsElements: true)
        let needle = label.trimmingCharacters(in: .whitespaces).lowercased()
        func texts(_ n: AXNode) -> [String] { [n.title, n.description, n.value, n.placeholder].compactMap { $0?.lowercased() } }
        let all = s.elements.values.sorted { $0.index < $1.index }
        var exact = all.filter { texts($0.node).contains(needle) }
        if exact.count == 1 { return exact[0].index }
        // A button "Playbook" and a heading "PLAYBOOK" both match exactly; the one that can be
        // acted on is what a caller giving a label means.
        if exact.count > 1 {
            let actionable = exact.filter { $0.node.actions.contains(kAXPressAction) || $0.node.settable }
            if actionable.count == 1 { return actionable[0].index }
            if !actionable.isEmpty { exact = actionable }
        }
        let partial = exact.isEmpty ? all.filter { texts($0.node).contains { $0.contains(needle) } } : exact
        if partial.count == 1 { return partial[0].index }
        if partial.isEmpty { throw LeapError.unsupported("No element labelled \"\(label)\" in the latest state of \(s.displayName).") }
        let list = partial.prefix(8).map { "[\($0.index)] \($0.node.role.dropFirst(2)) \($0.node.title ?? $0.node.description ?? $0.node.value ?? "")" }
        throw LeapError.unsupported("\"\(label)\" is ambiguous (\(partial.count) matches): " + list.joined(separator: "; ") + ". Use element_index.")
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
