// Prints the Control Center menu-bar items currently on screen; macOS's screen-recording
// indicator shows up as "AudioVideoModule" while any process streams a window.
// Usage: swiftc -O scripts/check-indicator.swift -o /tmp/check-indicator && /tmp/check-indicator
import CoreGraphics
import Foundation
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let items = list.compactMap { w -> String? in
    guard (w[kCGWindowOwnerName as String] as? String) == "Control Center" else { return nil }
    return w[kCGWindowName as String] as? String
}
print("Control Center items: " + items.joined(separator: ", "))
print(items.contains("AudioVideoModule") ? "INDICATOR ON" : "INDICATOR OFF")
