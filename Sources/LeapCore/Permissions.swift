import AppKit
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

    static let screenRecordingPane = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    /// Request Screen Recording the way Sky does (ScreenRecordingPermission.validateAuthorization):
    /// open System Settings at the Screen Recording list first, then call the request while that
    /// pane is visible. On current macOS a bare CGRequestScreenCaptureAccess() from a background
    /// (LSUIElement) helper only posts a notification and does not add the app to the list
    /// (observed 2026-09-30: tccd "Notifying for access kTCCServiceScreenCapture", no entry).
    @discardableResult
    public static func requestScreenRecording(openSettings: Bool = true) -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        if openSettings {
            NSWorkspace.shared.open(screenRecordingPane)
            // Let Settings show the pane before the request, as Sky waits for its window.
            let settings = "com.apple.systempreferences"
            for _ in 0..<20 {
                if NSRunningApplication.runningApplications(withBundleIdentifier: settings).first?.isFinishedLaunching == true { break }
                Thread.sleep(forTimeInterval: 0.1)
            }
            Thread.sleep(forTimeInterval: 0.8)
        }
        return CGRequestScreenCaptureAccess()
    }

    public static func summary() -> String {
        let ax = accessibilityTrusted() ? "granted" : "MISSING"
        let sr = screenRecordingGranted() ? "granted" : "MISSING"
        return "accessibility=\(ax) screen_recording=\(sr)"
    }
}
