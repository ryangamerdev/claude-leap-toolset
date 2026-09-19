import AppKit
import QuartzCore

/// A click-through heads-up overlay showing where claude-leap is acting.
///
/// The pointer is a *face*: an emoji chosen at random from a small set that matches the
/// kind of action (concentrating while typing, curious while scrolling, thinking while
/// reading state…). It pulses slowly like a heartbeat so it is easy to find, and every
/// interaction fires a single expanding sonar ring at the exact point so the viewer's eye
/// is pulled to what just happened.
///
/// Deliberately a *virtual* pointer: the user's real cursor is never moved, so the agent
/// and the user can work at the same time without fighting over the mouse. The window is
/// borderless, ignores mouse events, floats above normal windows, joins every Space, and is
/// ordered in with `orderFrontRegardless()` so showing it never activates this process.
///
/// Environment:
/// - `LEAP_OVERLAY=0`   disable entirely (headless / CI)
/// - `LEAP_EMOJI=0`     plain arrow instead of faces
@MainActor
public final class Overlay {
    public static let shared = Overlay()

    public enum Ping {
        case click, edit, scroll, drag, observe

        /// Facial expressions only, so the pointer feels quasi-human rather than iconic.
        var faces: [String] {
            switch self {
            case .click: return ["😊", "😃", "😉", "🙂", "😏", "😌"]
            case .edit: return ["🤓", "😐", "🧐", "😗", "🙂"]
            case .scroll: return ["😮", "🤨", "😯", "🧐", "🙄"]
            case .drag: return ["😤", "😬", "😅", "😣"]
            case .observe: return ["🤔", "🧐", "😶", "🫤", "😑"]
            }
        }

        var tint: NSColor {
            switch self {
            case .click: return NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)   // coral
            case .edit: return NSColor(srgbRed: 0.36, green: 0.72, blue: 0.62, alpha: 1)    // teal
            case .scroll: return NSColor(srgbRed: 0.44, green: 0.60, blue: 0.86, alpha: 1)  // blue
            case .drag: return NSColor(srgbRed: 0.76, green: 0.55, blue: 0.86, alpha: 1)    // violet
            case .observe: return NSColor(srgbRed: 0.80, green: 0.80, blue: 0.80, alpha: 1) // neutral
            }
        }

        var radius: CGFloat {
            switch self {
            case .click: return 56
            case .edit: return 44
            case .scroll: return 40
            case .drag: return 34
            case .observe: return 0 // reading is silent: face moves, no ring
            }
        }
    }

    public private(set) var isAvailable = false
    private var window: NSWindow?
    private var root: CALayer?
    private var pointer: CALayer?
    private var glyph: CATextLayer?
    private var fadeTask: Task<Void, Never>?

    /// Seconds of inactivity after which the pointer fades away.
    public var idleTimeout: TimeInterval = 10
    /// Offset of the face from the action point, so it never covers what it is pointing at.
    private let faceOffset = CGPoint(x: 18, y: 18)

    private init() {}

    private static var enabled: Bool { ProcessInfo.processInfo.environment["LEAP_OVERLAY"] != "0" }
    private static var useFaces: Bool { ProcessInfo.processInfo.environment["LEAP_EMOJI"] != "0" }

    // MARK: - Public API

    /// Move the face to a screen point (top-left origin, as AX and CGEvent report), pick an
    /// expression for the action, and fire one sonar ring there.
    public func signal(at point: CGPoint, ping: Ping) {
        guard Self.enabled, ensureWindow() else { return }
        movePointer(to: point, face: ping.faces.randomElement() ?? "🙂")
        if ping.radius > 0 { ripple(at: point, ping: ping) }
        scheduleFade()
    }

    /// Slide the face along a drag and ring both ends.
    public func signalDrag(from: CGPoint, to: CGPoint) {
        guard Self.enabled, ensureWindow() else { return }
        movePointer(to: from, face: Ping.drag.faces.randomElement() ?? "😤")
        ripple(at: from, ping: .drag)
        guard let pointer, let window else { return }
        let end = offset(convert(to, in: window))
        let move = CABasicAnimation(keyPath: "position")
        move.fromValue = NSValue(point: pointer.position)
        move.toValue = NSValue(point: end)
        move.duration = 0.45
        move.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pointer.position = end
        pointer.add(move, forKey: "drag")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 420_000_000)
            self.ripple(at: to, ping: .drag)
        }
        scheduleFade()
    }

    public func hide() {
        fadeTask?.cancel()
        pointer?.opacity = 0
    }

    // MARK: - Window

    private func ensureWindow() -> Bool {
        if window != nil { return true }
        // No window server (ssh / daemon): don't try, and don't crash.
        guard NSScreen.screens.first != nil else { return false }

        var union = CGRect.null
        for screen in NSScreen.screens { union = union.union(screen.frame) }
        guard !union.isNull else { return false }

        let w = NSWindow(contentRect: union, styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        let view = NSView(frame: CGRect(origin: .zero, size: union.size))
        view.wantsLayer = true
        let layer = CALayer()
        layer.frame = view.bounds
        view.layer = layer
        w.contentView = view
        w.orderFrontRegardless() // shows without activating this process

        window = w
        root = layer
        pointer = makePointer()
        if let pointer { layer.addSublayer(pointer) }
        isAvailable = true
        return true
    }

    /// Screen point (top-left origin) → overlay-window coordinates (bottom-left origin).
    private func convert(_ point: CGPoint, in window: NSWindow) -> CGPoint {
        // The primary screen has origin (0,0); global AppKit Y is measured up from its bottom.
        let primaryMaxY = NSScreen.screens.first?.frame.maxY ?? 0
        return CGPoint(x: point.x - window.frame.minX,
                       y: (primaryMaxY - point.y) - window.frame.minY)
    }

    /// The face floats up-and-right of the action point, like a cursor whose tip is the point.
    private func offset(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x + faceOffset.x, y: p.y + faceOffset.y)
    }

    // MARK: - Pointer (the face)

    private func makePointer() -> CALayer {
        let container = CALayer()
        container.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        container.opacity = 0

        let text = CATextLayer()
        text.alignmentMode = .center
        text.truncationMode = .none
        text.isWrapped = false
        text.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        text.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        text.position = CGPoint(x: 22, y: 22)
        // Drop shadow keeps the face readable over white UI.
        text.shadowColor = NSColor.black.cgColor
        text.shadowOpacity = 0.55
        text.shadowRadius = 4
        text.shadowOffset = CGSize(width: 0, height: -2)
        container.addSublayer(text)
        glyph = text
        setFace("🙂")

        // One slow pulse, then rest — a heartbeat, not a rock and not a double beat.
        let beatTimes: [NSNumber] = [0, 0.18, 0.40, 1.0]
        let ease = CAMediaTimingFunction(name: .easeInEaseOut)
        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values = [1.0, 1.22, 1.0, 1.0]
        pulse.keyTimes = beatTimes
        pulse.duration = 1.8
        pulse.repeatCount = .infinity
        pulse.timingFunctions = Array(repeating: ease, count: beatTimes.count - 1)
        text.add(pulse, forKey: "pulse")
        return container
    }

    private func setFace(_ face: String) {
        guard let glyph else { return }
        let symbol = Self.useFaces ? face : "➤"
        let attributed = NSAttributedString(string: symbol, attributes: [
            .font: NSFont.systemFont(ofSize: Self.useFaces ? 30 : 26, weight: .semibold),
            .foregroundColor: NSColor.white,
        ])
        let size = attributed.size()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glyph.string = attributed
        glyph.bounds = CGRect(origin: .zero, size: CGSize(width: ceil(size.width) + 4, height: ceil(size.height) + 4))
        CATransaction.commit()
    }

    private func movePointer(to point: CGPoint, face: String) {
        guard let pointer, let window else { return }
        setFace(face)
        let target = offset(convert(point, in: window))
        CATransaction.begin()
        if pointer.opacity < 0.5 {
            // First appearance: no slide across the screen.
            CATransaction.setDisableActions(true)
            pointer.position = target
            CATransaction.commit()
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.18)
        } else {
            CATransaction.setAnimationDuration(0.28)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            pointer.position = target
        }
        pointer.opacity = 1
        CATransaction.commit()
    }

    // MARK: - Sonar ring

    /// One ring, centred exactly on the action point, expanding and fading.
    private func ripple(at point: CGPoint, ping: Ping) {
        guard let root, let window else { return }
        let center = convert(point, in: window)
        let r = ping.radius

        let ring = CAShapeLayer()
        ring.bounds = CGRect(x: 0, y: 0, width: r * 2, height: r * 2)
        ring.position = center
        ring.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: r * 2, height: r * 2), transform: nil)
        ring.fillColor = NSColor.clear.cgColor
        ring.strokeColor = ping.tint.cgColor
        ring.lineWidth = 3
        ring.opacity = 0
        ring.shadowColor = ping.tint.cgColor
        ring.shadowOpacity = 0.6
        ring.shadowRadius = 4
        root.insertSublayer(ring, at: 0)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.12
        scale.toValue = 1.0
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0.0, 1.0, 0.0]
        fade.keyTimes = [0, 0.15, 1]
        let thin = CABasicAnimation(keyPath: "lineWidth")
        thin.fromValue = 5
        thin.toValue = 1
        let group = CAAnimationGroup()
        group.animations = [scale, fade, thin]
        group.duration = 0.8
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        ring.add(group, forKey: "sonar")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 850_000_000)
            ring.removeFromSuperlayer()
        }
    }

    private func scheduleFade() {
        fadeTask?.cancel()
        let timeout = idleTimeout
        fadeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.6)
            self.pointer?.opacity = 0
            CATransaction.commit()
        }
    }
}
