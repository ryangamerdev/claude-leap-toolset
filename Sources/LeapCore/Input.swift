import AppKit
import CoreGraphics
import Foundation

public enum MouseButton: String, Codable {
    case left, right, middle

    public init?(alias: String) {
        switch alias.lowercased() {
        case "left", "l": self = .left
        case "right", "r": self = .right
        case "middle", "m", "center": self = .middle
        default: return nil
        }
    }

    var down: CGEventType {
        switch self { case .left: return .leftMouseDown; case .right: return .rightMouseDown; case .middle: return .otherMouseDown }
    }
    var up: CGEventType {
        switch self { case .left: return .leftMouseUp; case .right: return .rightMouseUp; case .middle: return .otherMouseUp }
    }
    var dragged: CGEventType {
        switch self { case .left: return .leftMouseDragged; case .right: return .rightMouseDragged; case .middle: return .otherMouseDragged }
    }
    var cgButton: CGMouseButton {
        switch self { case .left: return .left; case .right: return .right; case .middle: return .center }
    }
}

/// Where synthesized events are delivered.
public enum Delivery {
    /// `CGEvent.postToPid` — the target app receives the event even when it is not
    /// frontmost, and the user's cursor/focus are left alone. Default.
    case app(pid_t)
    /// System HID tap — moves the real cursor and requires the app to be frontmost.
    /// Escape hatch for apps that ignore posted events.
    case system
}

/// Synthesizes mouse and keyboard input. All coordinates are global screen points
/// with a top-left origin (the same space AX reports).
public enum Input {
    static let source = CGEventSource(stateID: .combinedSessionState)
    static let clickGap: UInt32 = 25_000
    static let keyGap: UInt32 = 8_000

    static func post(_ event: CGEvent, _ delivery: Delivery) {
        switch delivery {
        case .app(let pid): event.postToPid(pid)
        case .system: event.post(tap: .cghidEventTap)
        }
    }

    public static func moveMouse(to p: CGPoint, _ delivery: Delivery) {
        guard let e = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left) else { return }
        post(e, delivery)
    }

    public static func click(at p: CGPoint, button: MouseButton = .left, count: Int = 1,
                             flags: CGEventFlags = [], _ delivery: Delivery) {
        if case .system = delivery { moveMouse(to: p, delivery); usleep(clickGap) }
        for i in 1...max(1, count) {
            guard let down = CGEvent(mouseEventSource: source, mouseType: button.down, mouseCursorPosition: p, mouseButton: button.cgButton),
                  let up = CGEvent(mouseEventSource: source, mouseType: button.up, mouseCursorPosition: p, mouseButton: button.cgButton)
            else { return }
            for e in [down, up] {
                e.flags = flags
                e.setIntegerValueField(.mouseEventClickState, value: Int64(i))
            }
            post(down, delivery); usleep(clickGap)
            post(up, delivery); usleep(clickGap)
        }
    }

    public static func drag(from a: CGPoint, to b: CGPoint, button: MouseButton = .left,
                            flags: CGEventFlags = [], steps: Int = 12, _ delivery: Delivery) {
        if case .system = delivery { moveMouse(to: a, delivery); usleep(clickGap) }
        guard let down = CGEvent(mouseEventSource: source, mouseType: button.down, mouseCursorPosition: a, mouseButton: button.cgButton) else { return }
        down.flags = flags
        post(down, delivery); usleep(60_000)
        for i in 1...max(1, steps) {
            let t = CGFloat(i) / CGFloat(steps)
            let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
            guard let move = CGEvent(mouseEventSource: source, mouseType: button.dragged, mouseCursorPosition: p, mouseButton: button.cgButton) else { continue }
            move.flags = flags
            post(move, delivery); usleep(16_000)
        }
        guard let up = CGEvent(mouseEventSource: source, mouseType: button.up, mouseCursorPosition: b, mouseButton: button.cgButton) else { return }
        up.flags = flags
        usleep(60_000); post(up, delivery)
    }

    /// Scroll by pixel deltas at a point (positive dy scrolls content up / wheel down).
    public static func scroll(at p: CGPoint, dx: Int32, dy: Int32, _ delivery: Delivery) {
        // Chunk large scrolls so apps with per-event clamping still travel the full distance.
        var remainingX = dx, remainingY = dy
        while remainingX != 0 || remainingY != 0 {
            let stepX = max(-120, min(120, remainingX)), stepY = max(-120, min(120, remainingY))
            guard let e = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2,
                                  wheel1: stepY, wheel2: stepX, wheel3: 0) else { return }
            e.location = p
            post(e, delivery)
            remainingX -= stepX; remainingY -= stepY
            usleep(12_000)
        }
    }

    public static func press(_ chord: KeyChord, _ delivery: Delivery) {
        if let code = chord.keyCode {
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else { return }
            down.flags = chord.flags; up.flags = chord.flags
            post(down, delivery); usleep(keyGap); post(up, delivery); usleep(keyGap)
        } else if let text = chord.unicodeFallback {
            type(text, flags: chord.flags, delivery)
        }
    }

    /// Types literal text. Newlines are sent as Return, tabs as Tab.
    public static func type(_ text: String, flags: CGEventFlags = [], _ delivery: Delivery) {
        var buffer: [UniChar] = []
        func flush() {
            guard !buffer.isEmpty else { return }
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }
            down.flags = flags; up.flags = flags
            buffer.withUnsafeBufferPointer { ptr in
                down.keyboardSetUnicodeString(stringLength: ptr.count, unicodeString: ptr.baseAddress)
                up.keyboardSetUnicodeString(stringLength: ptr.count, unicodeString: ptr.baseAddress)
            }
            post(down, delivery); usleep(keyGap); post(up, delivery); usleep(keyGap)
            buffer.removeAll()
        }
        for scalar in text.utf16 {
            switch scalar {
            case 0x0A, 0x0D: flush(); press(KeyChord(keyCode: 36, flags: flags), delivery)
            case 0x09: flush(); press(KeyChord(keyCode: 48, flags: flags), delivery)
            default:
                buffer.append(scalar)
                if buffer.count >= 20 { flush() }
            }
        }
        flush()
    }

    /// Paste via the pasteboard, then restore whatever the user had on it.
    public static func paste(_ text: String, html: String? = nil, _ delivery: Delivery) {
        let pb = NSPasteboard.general
        let saved = pb.pasteboardItems?.compactMap { item -> NSPasteboardItem? in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        } ?? []
        pb.clearContents()
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        if let html { item.setString(html, forType: .html) }
        pb.writeObjects([item])
        let ours = pb.changeCount
        usleep(50_000)
        press(KeyChord(keyCode: 9, flags: .maskCommand), delivery) // ⌘V
        usleep(350_000)
        // Restore only if the pasteboard still holds *our* item: if the user copied something
        // in the meantime, their copy wins and is left alone.
        guard pb.changeCount == ours else { return }
        pb.clearContents()
        if !saved.isEmpty { pb.writeObjects(saved) }
    }
}
