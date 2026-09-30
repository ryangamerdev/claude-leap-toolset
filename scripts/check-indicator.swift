// Reports whether macOS's screen-recording indicator (Control Center's Audio and Video menu extra)
// is on screen. It appears while any process streams a window with ScreenCaptureKit.
// macOS 27: menu extras are owned by MenuBarAgent and read through accessibility
// (item com.apple.menuextra.audiovideo); needs the Accessibility grant of the calling terminal.
// Older macOS: Control Center windows named "AudioVideoModule" in the window list.
// First: mkdir -p artifacts/test-runs/bin
// Usage: swiftc -O scripts/check-indicator.swift -o artifacts/test-runs/bin/check-indicator && artifacts/test-runs/bin/check-indicator
import AppKit
import CoreGraphics

func attr<T>(_ e: AXUIElement, _ k: String) -> T? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(e, k as CFString, &v) == .success else { return nil }
    return v as? T
}

var items: [String] = []
func collect(_ e: AXUIElement, _ depth: Int) {
    if (attr(e, kAXRoleAttribute) as String?) == "AXMenuBarItem", let id: String = attr(e, kAXIdentifierAttribute) {
        items.append(id)
    }
    guard depth < 4 else { return }
    for child in (attr(e, kAXChildrenAttribute) as [AXUIElement]?) ?? [] { collect(child, depth + 1) }
}
for bundle in ["com.apple.MenuBarAgent", "com.apple.controlcenter", "com.apple.systemuiserver"] {
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundle) {
        let pid = app.processIdentifier
        guard pid > 0, let bar: AXUIElement = attr(AXUIElementCreateApplication(pid), "AXExtrasMenuBar") else { continue }
        collect(bar, 0)
    }
}
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let legacy = windows.compactMap { w -> String? in
    guard (w[kCGWindowOwnerName as String] as? String) == "Control Center" else { return nil }
    return w[kCGWindowName as String] as? String
}
print("Menu extras: " + items.joined(separator: ", "))
if !legacy.isEmpty { print("Control Center items: " + legacy.joined(separator: ", ")) }
let on = items.contains("com.apple.menuextra.audiovideo") || legacy.contains("AudioVideoModule")
print(on ? "INDICATOR ON" : "INDICATOR OFF")
