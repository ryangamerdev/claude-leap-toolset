import AppKit
import Foundation
import LeapCore
import MCP

let instructions = """
claude-leap: native macOS computer use for AI agents (accessibility-first, background-first).

Workflow
1. get_app_state(app) — returns the app's key window as an indexed accessibility tree plus a screenshot. The app is launched in the background if needed.
2. Act with element_index values from that text: click, set_value, perform_action, type_text, press_key, scroll, drag, paste. By default these return the updated state diff, so you rarely need a separate get_app_state.
3. Prefer batch for any predictable sequence (click field → type → Return → read state) to save round trips.

The user keeps their computer
- Nothing you do activates an app or moves the real cursor. The user can keep typing and clicking in their own window while you work in another app.
- A virtual pointer and a sonar ripple appear on screen where you act, so the user can see what you are doing. This is cosmetic only.
- foreground=true is the one exception: it activates the app and takes over the real keyboard/mouse. It interrupts the user, so only use it when an app demonstrably ignores background input, and say why.

Reading state
- Lines look like: [42] Button "Save" @812,540 40x22 [settable] actions=ShowMenu. Coordinates are window-relative points; the screenshot is rendered 1 px per point unless scale is set.
- Indices are stable for the life of the window. By default you get a diff (+ added, ~ changed, - removed); pass disable_diff=true for the full tree.
- Prefer element_index over coordinates. Accessibility actions work from the background; synthesized clicks and keystrokes may not reach every app.
- For text, prefer set_value (replaces the field's contents through the text system, which SwiftUI/AppKit bindings observe) over click+select-all+type.
- Fall back to coordinates and the screenshot when an app exposes poor accessibility (custom canvases such as Blender's viewport, games, web canvases).

Safety
- Ask the user before destructive or irreversible UI actions (deleting, sending, purchasing, changing system settings). Never enter credentials.
"""

func runServer() async throws {
    let engine = Engine()
    let server = Server(
        name: "claude-leap",
        version: "0.1.0",
        instructions: instructions,
        capabilities: .init(tools: .init(listChanged: false))
    )
    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: LeapTools.all)
    }
    await server.withMethodHandler(CallTool.self) { params in
        await LeapTools.call(params, engine: engine)
    }
    try await server.start(transport: StdioTransport())
    await server.waitUntilCompleted()
}

/// The process runs an AppKit event loop so it can draw the on-screen activity indicator.
/// `.accessory` keeps it out of the Dock and the ⌘-Tab switcher, and the overlay window is
/// ordered in with `orderFrontRegardless()`, so this process never becomes frontmost.
final class LeapAppDelegate: NSObject, NSApplicationDelegate {
    // `Notification` is qualified: the MCP SDK also declares a `Notification` protocol.
    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        Task.detached(priority: .userInitiated) {
            do {
                try await runServer()
            } catch {
                FileHandle.standardError.write(Data("claude-leap: \(error)\n".utf8))
            }
            await MainActor.run { NSApplication.shared.terminate(nil) }
        }
    }
}

let application = NSApplication.shared
let leapDelegate = LeapAppDelegate()
application.delegate = leapDelegate
application.setActivationPolicy(.accessory)
application.run()
