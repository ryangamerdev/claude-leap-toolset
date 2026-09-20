import Foundation
import LeapCore
import MCP

// MARK: - Schema helpers

private func prop(_ type: String, _ description: String, enumValues: [String]? = nil) -> Value {
    var v: [String: Value] = ["type": .string(type), "description": .string(description)]
    if let enumValues { v["enum"] = .array(enumValues.map { .string($0) }) }
    return .object(v)
}

private func schema(_ props: [String: Value], required: [String] = []) -> Value {
    .object([
        "type": "object",
        "properties": .object(props),
        "required": .array(required.map { .string($0) }),
        "additionalProperties": false,
    ])
}

private let appProp = prop("string", "Target app: display name (\"Blender\"), bundle id (\"org.blenderfoundation.blender\"), or .app path. Launched in the background if not running.")
private let foregroundProp = prop("boolean", "Default false — the app is NEVER activated and the user keeps their frontmost window, keyboard focus and mouse. Set true only for apps that ignore posted events (some games, custom GL/Metal canvases); this steals focus, so ask the user first.")
private let thenStateProp = prop("boolean", "Default true: append the app's updated accessibility state (diff) to the result so you don't need a separate get_app_state call.")

private let labelProp = prop("string", "Alternative to element_index: the element's visible title/description/value, e.g. \"Save notes\". Case-insensitive; exact match wins, else a unique substring match. Errors list candidates if ambiguous.")

private let targetProps: [String: Value] = [
    "element_index": prop("integer", "Element index from the latest state text, e.g. 42 for \"[42] Button ...\". Preferred over coordinates."),
    "label": labelProp,
    "x": prop("number", "Window-relative x in points (see the window size in the state header). With element_index, x/y are relative to that element."),
    "y": prop("number", "Window-relative y in points."),
]

// MARK: - Tool definitions

enum LeapTools {
    static let all: [Tool] = [
        Tool(name: "list_apps",
             description: "List running GUI apps (frontmost first, with window counts) and optionally installed apps. Not needed to target an app you already know by name.",
             inputSchema: schema(["include_installed": prop("boolean", "Also list apps in /Applications that are not running (default false).")]),
             annotations: .init(readOnlyHint: true)),

        Tool(name: "get_app_state",
             description: "Read the target app's key window: an indexed accessibility tree (roles, titles, values, extra actions; coordinates only with include_frames) plus a window screenshot. Indices are stable across calls; by default only the diff since the previous state is returned. Call this before acting on an app and after actions whose result you need to see.",
             inputSchema: schema([
                "app": appProp,
                "include_screenshot": prop("boolean", "Default FALSE: the accessibility tree is the observation, like a screen reader. Set true only when the answer is visual and the tree cannot express it — a zoom level, a drag/pan offset, a canvas/diagram, a rendering glitch. A screenshot is ~110 KB; do not attach one by habit."),
                "disable_diff": prop("boolean", "Default false. Set true to get the full tree instead of the diff."),
                "scale": prop("number", "Screenshot scale, 0.1–1.0 (default 1.0 = 1 px per point so pixel coords equal window points)."),
                "window": prop("string", "Target a specific window by title substring (e.g. \"iPhone 16\" in Simulator). Sticks for later actions on this app; pass \"\" to go back to the key window."),
                "include_frames": prop("boolean", "Default false. Add each element's window-relative @x,y w×h (only needed for coordinate clicks/drags on canvases)."),
             ], required: ["app"]),
             annotations: .init(readOnlyHint: true)),

        Tool(name: "screenshot",
             description: "Capture a window as an image. With save_path it writes the file (creating parent folders) and, unless embed=true, returns only a text confirmation so bulk documentation capture does not flood context. Without save_path it returns the image inline.",
             inputSchema: schema([
                "app": appProp,
                "window": prop("string", "Target a specific window by title substring, e.g. \"iPhone 16\" or \"iPad Air\" in Simulator. Sticks for later actions on this app."),
                "x": prop("number", "Crop origin x (window points)."), "y": prop("number", "Crop origin y."),
                "width": prop("number", "Crop width."), "height": prop("number", "Crop height."),
                "scale": prop("number", "0.1–1.0, default 1.0 (full resolution)."),
                "save_path": prop("string", "Write the image here (PNG or JPEG by extension); parent folders are created. e.g. docs/screenshots/0.19.0/desktop-playbook-main.png"),
                "embed": prop("boolean", "Return the image inline as well as saving it (default false when save_path is set, so a capture pass stays light)."),
             ], required: ["app"]),
             annotations: .init(readOnlyHint: true)),

        Tool(name: "click",
             description: "Click an element by index (preferred; uses the accessibility Press action when available, which needs no focus) or a window-relative coordinate.",
             inputSchema: schema(targetProps.merging([
                "app": appProp,
                "button": prop("string", "left (default), right, middle", enumValues: ["left", "right", "middle"]),
                "click_count": prop("integer", "1 (default), 2 for double-click, 3 for triple."),
                "modifiers": prop("string", "Modifier keys to hold, e.g. \"shift\" or \"cmd+alt\"."),
                "foreground": foregroundProp, "then_state": thenStateProp,
             ]) { a, _ in a }, required: ["app"])),

        Tool(name: "drag",
             description: "Press at one window-relative point, move, and release at another (e.g. Blender viewport orbit, slider, reorder).",
             inputSchema: schema([
                "app": appProp,
                "from_x": prop("number", ""), "from_y": prop("number", ""),
                "to_x": prop("number", ""), "to_y": prop("number", ""),
                "steps": prop("integer", "Intermediate move events (default 12)."),
                "modifiers": prop("string", "Modifier keys to hold during the drag."),
                "foreground": foregroundProp, "then_state": thenStateProp,
             ], required: ["app", "from_x", "from_y", "to_x", "to_y"])),

        Tool(name: "scroll",
             description: "Scroll at an element or point by pages (default 1) or an exact pixel distance.",
             inputSchema: schema(targetProps.merging([
                "app": appProp,
                "direction": prop("string", "up, down, left, right", enumValues: ["up", "down", "left", "right"]),
                "pages": prop("number", "Number of pages (default 1); a page is ~85% of the element/window extent."),
                "pixels": prop("integer", "Exact distance in pixels; overrides pages."),
                "foreground": foregroundProp, "then_state": thenStateProp,
             ]) { a, _ in a }, required: ["app", "direction"])),

        Tool(name: "press_key",
             description: "Press a key or chord using xdotool-style names: \"Return\", \"Tab\", \"Escape\", \"Up\", \"super+s\", \"ctrl+shift+Tab\", \"KP_0\", \"F5\". Delivered to the target app only (not a global shortcut).",
             inputSchema: schema([
                "app": appProp,
                "key": prop("string", "Key or +-separated chord."),
                "foreground": foregroundProp, "then_state": thenStateProp,
             ], required: ["app", "key"])),

        Tool(name: "type_text",
             description: "Type literal text into the current focus (or focus element_index first). Newlines are sent as Return — many forms submit on Return, so prefer set_value/paste for multi-line text.",
             inputSchema: schema([
                "app": appProp,
                "text": prop("string", "Text to type."),
                "element_index": prop("integer", "Optional: focus this element before typing."),
                "label": labelProp,
                "foreground": foregroundProp, "then_state": thenStateProp,
             ], required: ["app", "text"])),

        Tool(name: "set_value",
             description: "Replace the value of an editable element (text field, slider, checkbox) via accessibility. Falls back to focus + select-all + type.",
             inputSchema: schema([
                "app": appProp,
                "element_index": prop("integer", "Editable element index."),
                "label": labelProp,
                "value": prop("string", "New value."),
                "then_state": thenStateProp,
             ], required: ["app", "value"])),

        Tool(name: "select_text",
             description: "Select matching text inside an editable element, or place the caret before/after it, via accessibility (no keystrokes). Use prefix/suffix to disambiguate repeated matches. Follow with type_text to replace the selection or insert at the caret.",
             inputSchema: schema([
                "app": appProp,
                "element_index": prop("integer", "Editable element index."),
                "label": labelProp,
                "text": prop("string", "Text to select (exact, case-sensitive)."),
                "prefix": prop("string", "Optional text that must immediately precede the match."),
                "suffix": prop("string", "Optional text that must immediately follow the match."),
                "selection_type": prop("string", "text (default): select the text; cursor_before / cursor_after: collapse the selection to a caret.", enumValues: ["text", "cursor_before", "cursor_after"]),
                "then_state": thenStateProp,
             ], required: ["app", "text"])),

        Tool(name: "wait_for",
             description: "Wait (bounded) until a labelled element appears, disappears, becomes enabled/disabled, or its value contains text. Use after actions that finish asynchronously (network results, saves that close a dialog) instead of assuming the settled tree is the final one. Fails on timeout so a batch stops.",
             inputSchema: schema([
                "app": appProp,
                "label": prop("string", "Visible title/description/value of the element (exact match preferred, substring fallback)."),
                "condition": prop("string", "appears (default), disappears, enabled, disabled, value_contains", enumValues: ["appears", "disappears", "enabled", "disabled", "value_contains"]),
                "value": prop("string", "For value_contains: the text the element's value must contain."),
                "timeout": prop("number", "Seconds to wait, default 10, max 60."),
                "then_state": thenStateProp,
             ], required: ["app", "label"])),

        Tool(name: "perform_action",
             description: "Invoke a secondary accessibility action listed in the element's actions= field, e.g. ShowMenu, Increment, Decrement, Confirm, Cancel, Expand, Collapse, Raise.",
             inputSchema: schema([
                "app": appProp,
                "element_index": prop("integer", ""),
                "label": labelProp,
                "action": prop("string", "Action name as shown in the state text (case-insensitive)."),
                "then_state": thenStateProp,
             ], required: ["app", "action"])),

        Tool(name: "paste",
             description: "Insert text (or HTML) via the pasteboard, then restore the user's previous clipboard. Best for multi-line or formatted content.",
             inputSchema: schema([
                "app": appProp,
                "text": prop("string", "Plain text."),
                "html": prop("string", "Optional HTML representation."),
                "foreground": foregroundProp, "then_state": thenStateProp,
             ], required: ["app", "text"])),

        Tool(name: "activate",
             description: "Bring the app to the foreground (only when the user should see it, or an app ignores background input).",
             inputSchema: schema(["app": appProp], required: ["app"])),

        Tool(name: "batch",
             description: "Run several actions on one app in a single call, then return the updated state. Each action is {\"tool\": \"click\"|\"drag\"|\"scroll\"|\"press_key\"|\"type_text\"|\"set_value\"|\"select_text\"|\"perform_action\"|\"paste\"|\"wait_for\"|\"wait\", ...args}. Stops at the first error and reports which steps were already applied. Use this whenever you can predict a sequence (click field → type → Return → wait_for the result).",
             inputSchema: schema([
                "app": appProp,
                "actions": .object([
                    "type": "array",
                    "description": "Ordered actions; each object has a \"tool\" key plus that tool's arguments (app is implied). {\"tool\":\"wait\",\"seconds\":1.5} pauses.",
                    "items": .object(["type": "object"]),
                ]),
                "include_screenshot": prop("boolean", "Include a screenshot with the final state (default false)."),
                "then_state": prop("boolean", "Return the final state (default true)."),
             ], required: ["app", "actions"])),

        Tool(name: "permissions",
             description: "Report whether Accessibility and Screen Recording are granted to this server, optionally triggering the system prompts.",
             inputSchema: schema(["prompt": prop("boolean", "Raise the macOS permission prompts if missing (default false).")]),
             annotations: .init(readOnlyHint: true)),
    ]

    // MARK: - Dispatch

    static func call(_ params: CallTool.Parameters, engine: Engine) async -> CallTool.Result {
        Inactivity.touch()
        let args = Args(params.arguments ?? [:])
        do {
            // One tool call — action plus its follow-up state, or a whole batch — runs to
            // completion before the next starts, even if the client issues calls in parallel.
            let name = params.name
            return try await engine.serialized { try await dispatch(name, args, engine) }
        } catch {
            return .init(content: [.text(text: "Error: \(error)", annotations: nil, _meta: nil)], isError: true)
        }
    }

    static func dispatch(_ name: String, _ a: Args, _ engine: Engine) async throws -> CallTool.Result {
        switch name {
        case "list_apps":
            let apps = AppResolver.listApps(includeInstalled: a.bool("include_installed") ?? false)
            var text = "## Apps (\(apps.filter { $0.isRunning }.count) running)\n"
            for app in apps {
                var line = app.isRunning ? "• " : "  "
                line += app.name
                if let b = app.bundleId { line += "  (\(b))" }
                if app.isRunning { line += "  pid=\(app.pid ?? 0) windows=\(app.windowCount)" }
                if app.isActive { line += "  [frontmost]" }
                text += line + "\n"
            }
            return text.result

        case "permissions":
            let prompt = a.bool("prompt") ?? false
            if prompt {
                _ = Permissions.accessibilityTrusted(prompt: true)
                if !Permissions.screenRecordingGranted() { _ = Permissions.requestScreenRecording() }
            }
            let who = Bundle.main.bundleIdentifier != nil
                ? "the \"claude-leap\" entry"
                : "the app that launched this dev build (Claude Code's helper, shown as \"claude\")"
            return ("claude-leap permissions: " + Permissions.summary() + "\nGrant missing ones in System Settings › Privacy & Security › Accessibility / Screen Recording — enable \(who) — then retry.").result

        case "get_app_state":
            var opts = Engine.StateOptions()
            opts.includeScreenshot = a.bool("include_screenshot") ?? false
            opts.disableDiff = a.bool("disable_diff") ?? false
            if let s = a.double("scale") { opts.scale = s }
            opts.includeFrames = a.bool("include_frames") ?? false
            let st = try await engine.state(app: try a.app(), opts, announce: true, window: a.string("window"))
            return result(text: st.text, shot: st.screenshot)

        case "screenshot":
            var region: CGRect?
            if let x = a.double("x"), let y = a.double("y"), let w = a.double("width"), let h = a.double("height") {
                region = CGRect(x: x, y: y, width: w, height: h)
            }
            let savePath = a.string("save_path").flatMap { $0.isEmpty ? nil : $0 }
            let wantsPNG = savePath?.lowercased().hasSuffix(".png") ?? false
            let shot = try await engine.screenshot(app: try a.app(), region: region, scale: a.double("scale") ?? 1.0,
                                                   png: wantsPNG, window: a.string("window"))
            var saved = ""
            if let path = savePath {
                let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try shot.data.write(to: url)
                saved = " — saved to \(url.path)"
            }
            // When saving to disk, don't also stream the image back unless asked: a capture pass
            // of many screens should not cost a screenshot's worth of context per shot.
            let embed = a.bool("embed") ?? (savePath == nil)
            let text = "screenshot \(shot.pixelWidth)x\(shot.pixelHeight) px, \(String(format: "%.2f", shot.pointsPerPixel)) points/px" + (region.map { " (region \(Int($0.minX)),\(Int($0.minY)) \(Int($0.width))x\(Int($0.height)))" } ?? "") + saved
            return result(text: text, shot: embed ? shot : nil)

        case "activate":
            return try await engine.activate(app: try a.app()).result

        case "batch":
            let app = try a.app()
            guard let actions = a.raw["actions"]?.arrayValue else { throw LeapError.unsupported("actions must be an array") }
            guard actions.count <= 50 else { throw LeapError.unsupported("batch is limited to 50 actions (got \(actions.count))") }
            // Hold focus for the whole batch: the app is activated at most once (lazily, only
            // if some action needs synthesized events) and the user's app is restored once.
            try await engine.beginInputSession(app: app, mode: Engine.InputMode(
                foreground: a.bool("foreground") ?? false))
            var log: [String] = []
            do {
                for (i, item) in actions.enumerated() {
                    guard var obj = item.objectValue, let tool = obj["tool"]?.stringValue else {
                        throw LeapError.unsupported("actions[\(i)] needs a \"tool\" string")
                    }
                    obj["app"] = .string(app)
                    obj["then_state"] = .bool(false)
                    let sub = Args(obj)
                    if tool == "wait" {
                        let secs = sub.double("seconds") ?? 1
                        try await Task.sleep(nanoseconds: UInt64(max(0, min(secs, 30)) * 1_000_000_000))
                        log.append("[\(i + 1)] waited \(secs)s")
                        continue
                    }
                    guard Self.actionTools.contains(tool) else { throw LeapError.unsupported("actions[\(i)]: \"\(tool)\" is not a batchable action") }
                    let r = try await performAction(tool, sub, engine)
                    log.append("[\(i + 1)] \(tool): \(r)")
                }
            } catch {
                await engine.endInputSession()
                // The steps that ran did run. Report them so the caller never re-sends them.
                let done = log.isEmpty ? "(none)" : log.joined(separator: "\n")
                throw LeapError.unsupported("Batch stopped at step \(log.count + 1) of \(actions.count): \(error)\nCompleted steps (already applied — do not repeat them):\n\(done)")
            }
            await engine.endInputSession()
            var text = "## Batch (all \(log.count) steps applied)\n" + log.joined(separator: "\n")
            var shot: Screenshot?
            if a.bool("then_state") ?? true {
                var opts = Engine.StateOptions()
                opts.includeScreenshot = a.bool("include_screenshot") ?? false
                do {
                    let st = try await engine.state(app: app, opts)
                    text += "\n\n" + st.text
                    shot = st.screenshot
                } catch {
                    text += "\n\n(state unavailable after the batch: \(error) — the actions above were applied; call get_app_state)"
                }
            }
            return result(text: text, shot: shot)

        default:
            guard Self.actionTools.contains(name) else { throw LeapError.unsupported("unknown tool \(name)") }
            let message = try await performAction(name, a, engine)
            guard a.bool("then_state") ?? true else { return message.result }
            var opts = Engine.StateOptions()
            opts.includeScreenshot = false
            // The action is done; a failed *observation* (Save closed the window, the app quit)
            // must not be reported as a failed action, or the caller will retry it.
            do {
                let st = try await engine.state(app: try a.app(), opts)
                return result(text: message + "\n\n" + st.text, shot: nil)
            } catch {
                return result(text: message + "\n\n(action applied; state unavailable afterwards: \(error) — call get_app_state)", shot: nil)
            }
        }
    }

    static let actionTools: Set<String> = ["click", "drag", "scroll", "press_key", "type_text", "set_value", "select_text", "perform_action", "paste", "wait_for"]

    /// Executes one input action and returns a one-line description of what happened.
    static func performAction(_ name: String, _ argsIn: Args, _ engine: Engine) async throws -> String {
        let app = try argsIn.app()
        // `label` is sugar for element_index: resolve it once here so every action supports it.
        var a = argsIn
        if name != "wait_for", a.int("element_index") == nil, let label = a.string("label"), !label.isEmpty {
            var raw = a.raw
            raw["element_index"] = .int(try await engine.findElement(app: app, label: label))
            a = Args(raw)
        }
        let mode = Engine.InputMode(foreground: a.bool("foreground") ?? false)
        switch name {
        case "click":
            let button = MouseButton(alias: a.string("button") ?? "left") ?? .left
            return try await engine.click(app: app, target: a.target(), button: button,
                                          count: max(1, min(a.int("click_count") ?? 1, 3)), modifiers: a.string("modifiers"), mode: mode)
        case "drag":
            guard let fx = a.double("from_x"), let fy = a.double("from_y"), let tx = a.double("to_x"), let ty = a.double("to_y") else {
                throw LeapError.unsupported("drag needs from_x, from_y, to_x, to_y")
            }
            return try await engine.drag(app: app, from: .init(x: fx, y: fy), to: .init(x: tx, y: ty),
                                         steps: a.int("steps") ?? 12, modifiers: a.string("modifiers"), mode: mode)
        case "scroll":
            guard let dir = a.string("direction") else { throw LeapError.unsupported("scroll needs direction") }
            var target = a.target()
            if target.elementIndex == nil && target.x == nil {
                target = try await centerTarget(app, engine) // default: window center
            }
            return try await engine.scroll(app: app, target: target, direction: dir,
                                           pages: a.double("pages") ?? 1, pixels: a.int("pixels"), mode: mode)
        case "press_key":
            guard let key = a.string("key") else { throw LeapError.unsupported("press_key needs key") }
            return try await engine.pressKey(app: app, key: key, mode: mode)
        case "type_text":
            guard let text = a.string("text") else { throw LeapError.unsupported("type_text needs text") }
            return try await engine.typeText(app: app, text: text, elementIndex: a.int("element_index"), mode: mode)
        case "set_value":
            guard let i = a.int("element_index"), let v = a.string("value") else { throw LeapError.unsupported("set_value needs element_index (or label) and value") }
            return try await engine.setValue(app: app, elementIndex: i, value: v)
        case "wait_for":
            guard let label = a.string("label") else { throw LeapError.unsupported("wait_for needs label") }
            guard let cond = Engine.WaitCondition(rawValue: a.string("condition") ?? "appears") else {
                throw LeapError.unsupported("condition must be appears, disappears, enabled, disabled or value_contains")
            }
            return try await engine.waitFor(app: app, label: label, condition: cond, value: a.string("value"),
                                            timeout: a.double("timeout") ?? 10)
        case "select_text":
            guard let i = a.int("element_index"), let text = a.string("text") else { throw LeapError.unsupported("select_text needs element_index (or label) and text") }
            let sel = Engine.SelectionType(rawValue: a.string("selection_type") ?? "text") ?? .text
            return try await engine.selectText(app: app, elementIndex: i, text: text, prefix: a.string("prefix"),
                                               suffix: a.string("suffix"), selection: sel)
        case "perform_action":
            guard let i = a.int("element_index"), let act = a.string("action") else { throw LeapError.unsupported("perform_action needs element_index (or label) and action") }
            return try await engine.performAction(app: app, elementIndex: i, action: act)
        case "paste":
            guard let text = a.string("text") else { throw LeapError.unsupported("paste needs text") }
            return try await engine.paste(app: app, text: text, html: a.string("html"), mode: mode)
        default:
            throw LeapError.unsupported("unknown action \(name)")
        }
    }

    static func centerTarget(_ app: String, _ engine: Engine) async throws -> Engine.Target {
        let frame = try await engine.windowFrame(app: app)
        return .init(x: frame.width / 2, y: frame.height / 2)
    }

    static func result(text: String, shot: Screenshot?) -> CallTool.Result {
        var content: [Tool.Content] = [.text(text: text, annotations: nil, _meta: nil)]
        if let shot {
            content.append(.image(data: shot.data.base64EncodedString(), mimeType: shot.mimeType, annotations: nil, _meta: nil))
        }
        return .init(content: content, isError: false)
    }
}

private extension String {
    var result: CallTool.Result { .init(content: [.text(text: self, annotations: nil, _meta: nil)], isError: false) }
}

/// Typed access to tool arguments.
struct Args {
    let raw: [String: Value]
    init(_ raw: [String: Value]) { self.raw = raw }

    func string(_ k: String) -> String? { raw[k]?.stringValue }
    func bool(_ k: String) -> Bool? { raw[k]?.boolValue }
    /// Numbers are bounded and finite before conversion: `Int(Double.nan)` and oversized
    /// values trap, which would take the whole server down on one malformed argument.
    func int(_ k: String) -> Int? {
        if let i = raw[k]?.intValue { return max(-1_000_000, min(1_000_000, i)) }
        if let d = raw[k]?.doubleValue, d.isFinite { return Int(max(-1_000_000, min(1_000_000, d.rounded()))) }
        return nil
    }
    func double(_ k: String) -> Double? {
        if let d = raw[k]?.doubleValue, d.isFinite { return max(-1_000_000, min(1_000_000, d)) }
        if let i = raw[k]?.intValue { return Double(max(-1_000_000, min(1_000_000, i))) }
        return nil
    }
    func app() throws -> String {
        guard let app = string("app"), !app.isEmpty else { throw LeapError.unsupported("\"app\" is required") }
        return app
    }
    func target() -> Engine.Target {
        .init(elementIndex: int("element_index"), x: double("x").map { CGFloat($0) }, y: double("y").map { CGFloat($0) })
    }
}
