// Verify the claude-leap activity overlay window is on screen, without Screen Recording.
//
// Window *metadata* (owner, bounds, layer, alpha) is readable by any process; only window
// titles and pixels require the Screen Recording grant. So this objectively confirms the
// overlay exists, spans the screens, and floats above normal windows.
//
// Must be compiled, not run through `swift file.swift` — the JIT cannot link CoreGraphics:
//   mkdir -p artifacts/test-runs/bin
//   swiftc -O -o artifacts/test-runs/bin/check-overlay scripts/check-overlay.swift && artifacts/test-runs/bin/check-overlay
import CoreGraphics
import Foundation

let filter = (CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "claude-leap").lowercased()
let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
let windows = (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]) ?? []

print("\(windows.count) on-screen windows; matching owner ~ \"\(filter)\":\n")
var hits = 0
for w in windows {
    let owner = (w[kCGWindowOwnerName as String] as? String) ?? ""
    guard owner.lowercased().contains(filter) else { continue }
    hits += 1
    let b = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    let layer = w[kCGWindowLayer as String] as? Int ?? 0
    let alpha = w[kCGWindowAlpha as String] as? Double ?? 0
    print("  owner=\"\(owner)\" pid=\(w[kCGWindowOwnerPID as String] ?? "?") id=\(w[kCGWindowNumber as String] ?? "?")")
    print("    layer=\(layer) (normal windows are 0; higher floats above) alpha=\(alpha)")
    print("    bounds=\(Int(b["X"] ?? 0)),\(Int(b["Y"] ?? 0)) \(Int(b["Width"] ?? 0))x\(Int(b["Height"] ?? 0))")
}

if hits == 0 {
    print("  (none)\n\nOwners currently on screen:")
    for name in Set(windows.compactMap { $0[kCGWindowOwnerName as String] as? String }).sorted() {
        print("  \(name)")
    }
}
exit(hits > 0 ? 0 : 1)
