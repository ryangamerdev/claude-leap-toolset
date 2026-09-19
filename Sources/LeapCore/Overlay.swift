import AppKit
import QuartzCore

/// A click-through heads-up overlay showing where claude-leap is acting.
///
/// Deliberately a *virtual* pointer: the user's real cursor is never moved, so the agent
/// and the user can work at the same time without fighting over the mouse. The window is
/// borderless, ignores mouse events, floats above normal windows, joins every Space, and is
/// ordered in with `orderFrontRegardless()` so showing it never activates this process.
///
/// Set `LEAP_OVERLAY=0` to disable (headless / CI).
@MainActor
public final class Overlay {
    public static let shared = Overlay()

    public enum Ping {
        case click, edit, scroll, drag

        var tint: NSColor {
            switch self {
            case .click: return NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)  // claude coral
            case .edit: return NSColor(srgbRed: 0.36, green: 0.72, blue: 0.62, alpha: 1)   // teal
            case .scroll: return NSColor(srgbRed: 0.44, green: 0.60, blue: 0.86, alpha: 1) // blue
            case .drag: return NSColor(srgbRed: 0.76, green: 0.55, blue: 0.86, alpha: 1)   // violet
            }
        }

        var radius: CGFloat {
            switch self {
            case .click: return 52
            case .edit: return 40
            case .scroll: return 34
            case .drag: return 30
            }
        }
    }

    public private(set) var isAvailable = false
    private var window: NSWindow?
    private var root: CALayer?
    private var pointer: CALayer?
    private var fadeTask: Task<Void, Never>?

    /// Seconds of inactivity after which the pointer fades away.
    public var idleTimeout: TimeInterval = 10

    private init() {}

    private static var enabled: Bool { ProcessInfo.processInfo.environment["LEAP_OVERLAY"] != "0" }

    // MARK: - Public API

    /// Show the pointer at a screen point (top-left origin, as AX and CGEvent report) and
    /// emit a ripple there. Safe to call when the overlay can't be created.
    public func signal(at point: CGPoint, ping: Ping) {
        guard Self.enabled, ensureWindow() else { return }
        movePointer(to: point, tint: ping.tint)
        ripple(at: point, ping: ping)
        scheduleFade()
    }

    /// Animate the pointer along a drag path and trail ripples behind it.
    public func signalDrag(from: CGPoint, to: CGPoint) {
        guard Self.enabled, ensureWindow() else { return }
        movePointer(to: from, tint: Ping.drag.tint)
        ripple(at: from, ping: .drag)
        guard let pointer, let window else { return }
        let end = convert(to, in: window)
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

    // MARK: - Pointer

    private func makePointer() -> CALayer {
        let container = CALayer()
        container.bounds = CGRect(x: 0, y: 0, width: 96, height: 96)
        container.opacity = 0

        // Pulsing halo so the position is obvious against any background.
        let halo = CAShapeLayer()
        halo.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 34, height: 34), transform: nil)
        halo.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
        halo.position = CGPoint(x: 48, y: 48)
        halo.fillColor = NSColor.white.withAlphaComponent(0.10).cgColor
        halo.strokeColor = NSColor.white.withAlphaComponent(0.55).cgColor
        halo.lineWidth = 1.5
        // One slow pulse, then rest. Deliberately not a rocking motion and not a double beat —
        // the idle animation is how the user tells this pointer apart from anything else.
        let beatTimes: [NSNumber] = [0, 0.18, 0.40, 1.0]
        let ease = CAMediaTimingFunction(name: .easeInEaseOut)
        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values = [1.0, 1.24, 1.0, 1.0]
        pulse.keyTimes = beatTimes
        pulse.duration = 1.8
        pulse.repeatCount = .infinity
        pulse.timingFunctions = Array(repeating: ease, count: beatTimes.count - 1)
        halo.add(pulse, forKey: "pulse")
        let breathe = CAKeyframeAnimation(keyPath: "opacity")
        breathe.values = [0.5, 1.0, 0.5, 0.5]
        breathe.keyTimes = beatTimes
        breathe.duration = 1.8
        breathe.repeatCount = .infinity
        breathe.timingFunctions = Array(repeating: ease, count: beatTimes.count - 1)
        halo.add(breathe, forKey: "breathe")
        container.addSublayer(halo)

        // Arrow cursor glyph, drawn top-left-anchored at the hot spot.
        let arrow = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -19))
        path.addLine(to: CGPoint(x: 4.6, y: -14.6))
        path.addLine(to: CGPoint(x: 7.6, y: -21.2))
        path.addLine(to: CGPoint(x: 10.8, y: -19.8))
        path.addLine(to: CGPoint(x: 7.8, y: -13.4))
        path.addLine(to: CGPoint(x: 13.4, y: -13.4))
        path.closeSubpath()
        arrow.path = path
        arrow.bounds = CGRect(x: 0, y: -22, width: 14, height: 22)
        arrow.anchorPoint = CGPoint(x: 0, y: 1)
        arrow.position = CGPoint(x: 48, y: 48)
        arrow.fillColor = NSColor.white.cgColor
        arrow.strokeColor = NSColor.black.withAlphaComponent(0.85).cgColor
        arrow.lineWidth = 1.2
        arrow.lineJoin = .round
        // Shadow keeps it readable over white UI, per the request.
        arrow.shadowColor = NSColor.black.cgColor
        arrow.shadowOpacity = 0.55
        arrow.shadowRadius = 3
        arrow.shadowOffset = CGSize(width: 0, height: -2)
        container.addSublayer(arrow)
        self.arrow = arrow
        self.halo = halo
        return container
    }

    private var arrow: CAShapeLayer?
    private var halo: CAShapeLayer?

    private func movePointer(to point: CGPoint, tint: NSColor) {
        guard let pointer, let window else { return }
        let target = convert(point, in: window)
        halo?.strokeColor = tint.withAlphaComponent(0.9).cgColor
        halo?.fillColor = tint.withAlphaComponent(0.18).cgColor
        arrow?.fillColor = tint.blended(withFraction: 0.72, of: .white)?.cgColor ?? NSColor.white.cgColor

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

    // MARK: - Ripple

    private func ripple(at point: CGPoint, ping: Ping) {
        guard let root, let window else { return }
        let center = convert(point, in: window)
        let r = ping.radius

        let wave = CAShapeLayer()
        wave.bounds = CGRect(x: 0, y: 0, width: r * 2, height: r * 2)
        wave.position = center
        wave.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: r * 2, height: r * 2), transform: nil)
        wave.fillColor = ping.tint.withAlphaComponent(0.16).cgColor
        wave.strokeColor = ping.tint.withAlphaComponent(0.95).cgColor
        wave.lineWidth = 2.5
        wave.opacity = 0
        root.insertSublayer(wave, at: 0)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.18
        scale.toValue = 1.0
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0.0, 0.95, 0.0]
        fade.keyTimes = [0, 0.18, 1]
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 0.72
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = true
        wave.add(group, forKey: "sonar")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 760_000_000)
            wave.removeFromSuperlayer()
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
