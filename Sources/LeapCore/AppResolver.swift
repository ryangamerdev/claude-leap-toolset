import AppKit
import Foundation

public enum LeapError: Error, CustomStringConvertible {
    case appNotFound(String)
    case launchFailed(String, String)
    case noWindow(String)
    case axFailure(String, AXError)
    case noSuchElement(Int)
    case staleElement(Int, String)
    case unsupported(String)
    case capture(String)
    case permission(String)
    /// The app's process changed under us (quit/crash/reinstall); actions need a fresh state.
    case processChanged(String)
    /// An element_index/label action arrived before any state was read for the app.
    case notActive(String)
    case ambiguousApp(String, [String])

    public var description: String {
        switch self {
        case .processChanged(let name):
            return "\(name) was relaunched (new process) since the last state; nothing was done. Call get_app_state to read the fresh tree before sending more actions — the old indices are void."
        case .notActive(let name):
            return "No state has been read for \(name) in this session; nothing was done. Call get_app_state first so element indices and labels refer to what you have seen."
        case .ambiguousApp(let q, let paths):
            return "Ambiguous app \"\(q)\": several copies share it — " + paths.joined(separator: ", ") + ". Use the full .app path."
        case .appNotFound(let q):
            return "No running or installed app matches \"\(q)\". Try a bundle id (list_apps shows them)."
        case .launchFailed(let q, let why): return "Failed to launch \"\(q)\": \(why)"
        case .noWindow(let name): return "\"\(name)\" has no accessible window (is it still launching, or minimized to the Dock?)"
        case .axFailure(let what, let err): return "Accessibility call \(what) failed: \(err.name)"
        case .noSuchElement(let i):
            return "No element with index \(i) in the latest state; call get_app_state and use a fresh index."
        case .staleElement(let i, let why):
            return "The UI changed since the last state: element [\(i)] \(why). Nothing was done. Call get_app_state and act on the fresh tree (the user may have interacted with the app)."
        case .unsupported(let what): return what
        case .capture(let why): return "Screenshot failed: \(why)"
        case .permission(let what): return what
        }
    }
}

extension AXError {
    var name: String {
        switch self {
        case .success: return "success"
        case .failure: return "failure"
        case .illegalArgument: return "illegalArgument"
        case .invalidUIElement: return "invalidUIElement (element went away)"
        case .invalidUIElementObserver: return "invalidUIElementObserver"
        case .cannotComplete: return "cannotComplete (app busy or not responding to AX)"
        case .attributeUnsupported: return "attributeUnsupported"
        case .actionUnsupported: return "actionUnsupported"
        case .notificationUnsupported: return "notificationUnsupported"
        case .notImplemented: return "notImplemented"
        case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
        case .notificationNotRegistered: return "notificationNotRegistered"
        case .apiDisabled: return "apiDisabled (Accessibility permission missing)"
        case .noValue: return "noValue"
        case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
        case .notEnoughPrecision: return "notEnoughPrecision"
        @unknown default: return "AXError(\(rawValue))"
        }
    }
}

public struct AppInfo: Codable {
    public var name: String
    public var bundleId: String?
    public var pid: Int32?
    public var isRunning: Bool
    public var isActive: Bool
    public var windowCount: Int
    public var path: String?
}

public enum AppResolver {
    /// Resolve by display name, bundle identifier, process name, or .app path.
    /// Launches (without activating) when not running and `launch` is set.
    public static func resolve(_ query: String, launch: Bool = true) async throws -> NSRunningApplication {
        if let running = try findRunning(query) { return running }
        guard launch else { throw LeapError.appNotFound(query) }
        if !query.contains("/") {
            let copies = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: query)
            if copies.count > 1 { throw LeapError.ambiguousApp(query, copies.map { $0.path }) }
        }
        guard let url = installedURL(for: query) else { throw LeapError.appNotFound(query) }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        config.addsToRecentItems = false
        let app: NSRunningApplication
        do {
            app = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
        } catch {
            throw LeapError.launchFailed(query, error.localizedDescription)
        }
        // Give the process a moment to register its AX server; callers poll for windows.
        try? await Task.sleep(nanoseconds: 400_000_000)
        return app
    }

    static func normalized(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.hasSuffix(".app") { t.removeLast(4) }
        return t
    }

    /// Several running copies of one app (e.g. Gameday.app in ~/Applications and a build dir):
    /// the frontmost one wins, else the only one with windows on screen, else it is a genuine
    /// ambiguity and — like Sky — we refuse rather than guess, listing the paths.
    static func pickOne(_ candidates: [NSRunningApplication], _ query: String) throws -> NSRunningApplication? {
        if candidates.count <= 1 { return candidates.first }
        if let active = candidates.first(where: { $0.isActive }) { return active }
        let counts = WindowInfo.onScreenWindowCounts()
        let withWindows = candidates.filter { (counts[$0.processIdentifier] ?? 0) > 0 }
        if withWindows.count == 1 { return withWindows[0] }
        throw LeapError.ambiguousApp(query, candidates.map { $0.bundleURL?.path ?? "pid \($0.processIdentifier)" })
    }

    public static func findRunning(_ query: String) throws -> NSRunningApplication? {
        let q = normalized(query)
        let apps = NSWorkspace.shared.runningApplications
        let byBundle = apps.filter { $0.bundleIdentifier?.lowercased() == q }
        if let one = try pickOne(byBundle, query) { return one }
        let byName = apps.filter { normalized($0.localizedName ?? "") == q }
        if let one = try pickOne(byName, query) { return one }
        if query.contains("/") {
            let path = (query as NSString).expandingTildeInPath
            if let byPath = apps.first(where: {
                $0.bundleURL?.path == path || $0.executableURL?.path == path
            }) { return byPath }
        }
        if let byExec = apps.first(where: { normalized($0.executableURL?.lastPathComponent ?? "") == q }) {
            return byExec
        }
        // Loose match: "edge" -> "Microsoft Edge"
        let loose = apps.filter { $0.activationPolicy == .regular }
            .filter { normalized($0.localizedName ?? "").contains(q) }
        return loose.count == 1 ? loose.first : nil
    }

    public static func installedURL(for query: String) -> URL? {
        if query.contains("/") {
            let url = URL(fileURLWithPath: (query as NSString).expandingTildeInPath)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: query) { return url }
        let name = query.hasSuffix(".app") ? query : query + ".app"
        let dirs = ["/Applications", "/Applications/Utilities", "/System/Applications",
                    "/System/Applications/Utilities", NSHomeDirectory() + "/Applications"]
        for dir in dirs {
            let candidate = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        // Case-insensitive scan of /Applications as a last resort.
        let q = normalized(query)
        for dir in dirs {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            if let hit = items.first(where: { normalized($0) == q && $0.hasSuffix(".app") }) {
                return URL(fileURLWithPath: dir).appendingPathComponent(hit)
            }
        }
        return nil
    }

    /// Running GUI apps first (with window counts), then installed apps from /Applications.
    public static func listApps(includeInstalled: Bool) -> [AppInfo] {
        let windowsByPid = WindowInfo.onScreenWindowCounts()
        var seen = Set<String>()
        var result: [AppInfo] = []
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            let name = app.localizedName ?? app.bundleIdentifier ?? "pid \(app.processIdentifier)"
            seen.insert(normalized(name))
            result.append(AppInfo(
                name: name, bundleId: app.bundleIdentifier, pid: app.processIdentifier,
                isRunning: true, isActive: app.isActive,
                windowCount: windowsByPid[app.processIdentifier] ?? 0,
                path: app.bundleURL?.path))
        }
        result.sort { ($0.isActive ? 0 : 1, $0.name) < ($1.isActive ? 0 : 1, $1.name) }
        guard includeInstalled else { return result }
        for dir in ["/Applications", "/System/Applications"] {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in items.sorted() where item.hasSuffix(".app") {
                let name = String(item.dropLast(4))
                guard !seen.contains(normalized(name)) else { continue }
                seen.insert(normalized(name))
                let url = URL(fileURLWithPath: dir).appendingPathComponent(item)
                let bundleId = Bundle(url: url)?.bundleIdentifier
                result.append(AppInfo(name: name, bundleId: bundleId, pid: nil, isRunning: false,
                                      isActive: false, windowCount: 0, path: url.path))
            }
        }
        return result
    }
}
