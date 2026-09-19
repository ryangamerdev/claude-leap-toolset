import ApplicationServices
import CoreGraphics
import Foundation

public enum Permissions {
    /// Accessibility (TCC "Accessibility") — required for reading AX trees and
    /// performing AX actions. Pass `prompt: true` to raise the system dialog.
    public static func accessibilityTrusted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    /// Screen Recording (TCC "Screen Recording") — required for window screenshots.
    public static func screenRecordingGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    public static func requestScreenRecording() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    public static func summary() -> String {
        let ax = accessibilityTrusted() ? "granted" : "MISSING"
        let sr = screenRecordingGranted() ? "granted" : "MISSING"
        return "accessibility=\(ax) screen_recording=\(sr)"
    }
}
