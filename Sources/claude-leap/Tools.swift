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
             description: "Read the target app's key window: an indexed accessibility tree (roles, titles, values, window-relative coordinates, extra actions) plus a window screenshot. Indices are stable across calls; by default only the diff since the previous state is returned. Call this before acting on an app and after actions whose result you need to see.",
             inputSchema: schema([
                "app": appProp,
                "include_screenshot": prop("boolean", "Default true. Set false to save tokens when the tree is enough."),
                "disable_diff": prop("boolean", "Default false. Set true to get the full tree instead of the diff."),
                "scale": prop("number", "Screenshot scale, 0.1–1.0 (default 1.0 = 1 px per point so pixel coords equal window points)."),
                "window": prop("string", "Target a specific window by title substring (e.g. \"iPhone 16\" in Simulator). Sticks for later actions on this app; pass \"\" to go back to the key window."),
             ], required: ["app"]),
             annotations: .init(readOnlyHint: true)),

        Tool(name: "screenshot",
             description: "Window screenshot only (no accessibility tree). Optional region crop in window points for zooming into detail.",
             inputSchema: schema([
                "app": appProp,
                "x": prop("number", "Crop origin x (window points)."), "y": prop("number", "Crop origin y."),
                "width": prop("number", "Crop width."), "height": prop("number", "Crop height."),
                "scale": prop("number", "0.1–1.0, default 1.0."),
                "save_path": prop("string", "Also write the image to this file path (PNG or JPEG by extension), e.g. for before/after documentation."),
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
             description: "Run several actions on one app in a single call, then return the updated state. Each action is {\"tool\": \"click\"|\"drag\"|\"scroll\"|\"press_key\"|\"type_text\"|\"set_value\"|\"perform_action\"|\"paste\"|\"wait\", ...args}. Stops at the first error. Use this whenever you can predict a sequence (click field → type → Return).",
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
            return try await dispatch(params.name, args, engine)
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
            opts.includeScreenshot = a.bool("include_screenshot") ?? true
            opts.disableDiff = a.bool("disable_diff") ?? false
            if let s = a.double("scale") { opts.scale = s }
            let st = try await engine.state(app: try a.app(), opts, announce: true, window: a.string("window"))
            return result(text: st.text, shot: st.screenshot)

        case "screenshot":
            var region: CGRect?
            if let x = a.double("x"), let y = a.double("y"), let w = a.double("width"), let h = a.double("height") {
                region = CGRect(x: x, y: y, width: w, height: h)
            }
            let shot = try await engine.screenshot(app: try a.app(), region: region, scale: a.double("scale") ?? 1.0)
            var saved = ""
            if let path = a.string("save_path"), !path.isEmpty {
                let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try shot.data.write(to: url)
                saved = " — saved to \(url.path)"
            }
            return result(text: "screenshot \(shot.pixelWidth)x\(shot.pixelHeight) px, \(String(format: "%.2f", shot.pointsPerPixel)) points/px" + (region.map { " (region \(Int($0.minX)),\(Int($0.minY)) \(Int($0.width))x\(Int($0.height)))" } ?? "") + saved, shot: shot)

        case "activate":
            return try await engine.activate(app: try a.app()).result

        case "batch":
            let app = try a.app()
            guard let actions = a.raw["actions"]?.arrayValue else { throw LeapError.unsupported("actions must be an array") }
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
                throw error
            }
            await engine.endInputSession()
            var text = "## Batch\n" + log.joined(separator: "\n")
            var shot: Screenshot?
            if a.bool("then_state") ?? true {
                var opts = Engine.StateOptions()
                opts.includeScreenshot = a.bool("include_screenshot") ?? false
                let st = try await engine.state(app: app, opts)
                text += "\n\n" + st.text
                shot = st.screenshot
            }
            return result(text: text, shot: shot)

        default:
            guard Self.actionTools.contains(name) else { throw LeapError.unsupported("unknown tool \(name)") }
            let message = try await performAction(name, a, engine)
            guard a.bool("then_state") ?? true else { return message.result }
            var opts = Engine.StateOptions()
            opts.includeScreenshot = false
            let st = try await engine.state(app: try a.app(), opts)
            return result(text: message + "\n\n" + st.text, shot: nil)
        }
    }

    static let actionTools: Set<String> = ["click", "drag", "scroll", "press_key", "type_text", "set_value", "perform_action", "paste"]

    /// Executes one input action and returns a one-line description of what happened.
    static func performAction(_ name: String, _ argsIn: Args, _ engine: Engine) async throws -> String {
        let app = try argsIn.app()
        // `label` is sugar for element_index: resolve it once here so every action supports it.
        var a = argsIn
        if a.int("element_index") == nil, let label = a.string("label"), !label.isEmpty {
            var raw = a.raw
            raw["element_index"] = .int(try await engine.findElement(app: app, label: label))
            a = Args(raw)
        }
        let mode = Engine.InputMode(foreground: a.bool("foreground") ?? false)
        switch name {
        case "click":
            let button = MouseButton(alias: a.string("button") ?? "left") ?? .left
            return try await engine.click(app: app, target: a.target(), button: button,
                                          count: a.int("click_count") ?? 1, modifiers: a.string("modifiers"), mode: mode)
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
    func int(_ k: String) -> Int? {
        if let i = raw[k]?.intValue { return i }
        if let d = raw[k]?.doubleValue { return Int(d) }
        return nil
    }
    func double(_ k: String) -> Double? {
        if let d = raw[k]?.doubleValue { return d }
        if let i = raw[k]?.intValue { return Double(i) }
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
