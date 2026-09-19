import Darwin
import Foundation

/// Shut the server down after a period with no tool calls.
///
/// Modelled on the mechanism the Sky computer-use service uses rather than an invented one:
/// its binary carries `inactivityTask` and emits a `cua_service_idle_timeout_reached`
/// analytics event, alongside `shouldTerminateWhenNoClientsRemain` and an flock-guarded
/// singleton socket (`computeruse.sock.lock`). Sky can rely mostly on client refcounting
/// because it is one long-lived service shared by thin per-connection clients; claude-leap is
/// one process per MCP connection, so each process owns its own ScreenCaptureKit session and
/// the idle timeout is what keeps an orphan from holding that session forever.
///
/// This matters concretely: a server left over from an earlier run kept an SCK/ReplayKit
/// session open and every later screenshot hung until it was killed by hand.
///
/// `LEAP_IDLE_TIMEOUT_SECONDS=0` disables it; the default is 30 minutes.
enum Inactivity {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var lastActivity = Date()

    static var timeout: TimeInterval {
        if let raw = ProcessInfo.processInfo.environment["LEAP_IDLE_TIMEOUT_SECONDS"],
           let value = TimeInterval(raw) {
            return value
        }
        return 30 * 60
    }

    /// Call on every tool invocation.
    static func touch() {
        lock.lock(); lastActivity = Date(); lock.unlock()
    }

    static func start() {
        let limit = timeout
        guard limit > 0 else { return }
        // Poll well inside the limit so the shutdown is not up to a full interval late.
        let poll = max(1.0, min(30.0, limit / 2))
        Task.detached(priority: .background) {
            while true {
                try? await Task.sleep(nanoseconds: UInt64(poll * 1_000_000_000))
                lock.lock(); let idle = Date().timeIntervalSince(lastActivity); lock.unlock()
                if idle >= limit {
                    FileHandle.standardError.write(Data(
                        "claude-leap: idle for \(Int(idle))s (limit \(Int(limit))s); exiting so the capture session is released\n".utf8))
                    exit(0)
                }
            }
        }
    }
}
