import Foundation
import LeapCore
import MCP

let instructions = """
claude-leap: native macOS computer use for AI agents (accessibility-first).

Workflow
1. get_app_state(app) — returns the app's key window as an indexed accessibility tree plus a screenshot. The app is launched in the background if needed; you never have to activate it.
2. Act with element_index values from that text: click, set_value, perform_action, type_text, press_key, scroll, drag, paste. Actions are delivered straight to the app (no focus stealing) and by default return the updated state diff, so you rarely need a separate get_app_state.
3. Prefer batch for any predictable sequence (click field → type → Return → read state) to save round trips.

Reading state
- Lines look like: [42] Button "Save" @812,540 40x22 actions=ShowMenu. Coordinates are window-relative points; the screenshot is rendered 1 px per point unless scale is set.
- Indices are stable across calls. By default you get a diff (+ added, ~ changed, - removed); pass disable_diff=true for the full tree.
- Prefer element_index over coordinates; fall back to coordinates (or the screenshot) when an app exposes poor accessibility (custom canvases such as Blender's viewport, games, web canvases).
- If an app ignores background input, retry the action with foreground=true.

Safety
- Ask the user before destructive or irreversible UI actions (deleting, sending, purchasing, changing system settings). Never enter credentials.
"""

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

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
