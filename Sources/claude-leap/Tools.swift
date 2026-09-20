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
private let foregroundProp = prop("boolean", "Default false: keep the user’s frontmost app. True explicitly brings the target app forward when synthesized input is needed. Mouse gestures use the same window-targeted delivery in both modes and do not move the real cursor. Keyboard fallback may use system events.")
private let thenStateProp = prop("boolean", "Default true: observe updated state. Recorded successful single actions return a compact outcome/delta and snapshot references; other paths return state text.")

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
        Tool(name:"evidence_read",description:"Retrieve a retained v2 record or nested field as bounded raw text, without input replay or escaped large strings. Path is an array of object keys/array indices; offset is characters, max_bytes bounds chunk.",inputSchema:schema(["project":prop("string","Project override; optional when bound."),"session_id":prop("string","Historical session."),"record":prop("integer","Snapshot or history record number."),"path":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"offset":prop("integer","Character offset, default0."),"max_bytes":prop("integer","Chunk budget128–8000, default4000.")],required:["session_id","record"]),annotations:.init(readOnlyHint:true)),
        Tool(name:"target_list",description:"Discover Mac applications and Simulator device targets with backend capabilities and readiness limitations.",inputSchema:schema([:]),annotations:.init(readOnlyHint:true)),
        Tool(name:"session_open",description:"Open a durable intent session. mac_ax controls a Mac app; wda controls the guest app through a local XCTest runner. No data reset or implicit backend fallback. Returns session_id for ui_observe/ui_perform.",inputSchema:schema(["project":prop("string","Existing absolute project path."),"app":prop("string","Mac app name/bundle ID, or guest bundle ID for wda."),"backend":prop("string","Default mac_ax.",enumValues:["mac_ax","wda"]),"window":prop("string","Mac window title selection."),"endpoint":prop("string","Local WDA HTTP origin, including port, from scripts/wda.py.")],required:["project","app"])),
        Tool(name:"session_close",description:"Close live Leap session; preserve history and leave app running.",inputSchema:schema(["session_id":prop("string","Live session ID.")],required:["session_id"])),
        Tool(name:"ui_observe",description:"Fresh or retained normalized UI with bounded JSON, exact selector, fields and pagination. Snapshot IDs scope evidence; coordinates carry space/bounds. After restart historical reads require project.",inputSchema:schema(["session_id":prop("string","Session ID."),"project":prop("string","Historical project override."),"snapshot":prop("integer","Retained snapshot; omit for fresh."),"selector":prop("object","Exact id/identifier/role/label, explicit contains, root ancestor ID."),"fields":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"depth":prop("integer","Maximum depth relative to selected root."),"after":prop("integer","Matched-node cursor."),"limit":prop("integer","1–100, default20."),"max_bytes":prop("integer","Full response budget2048–32000.")],required:["session_id"])),
        Tool(name:"ui_perform",description:"Run 1–50 intent steps with fresh targeting, preconditions, bounded checks, durable evidence, compact deltas and failure screenshots. Stops on failure/unknown. Never replays input. Steps: {type:action|wait|assert|observe|capture, action?, selector?, arguments?, before?, expect?, timeout?}. Expectation: {selector,condition:exists|absent|enabled|disabled|selected|value_equals|value_contains|count,value?}. Actions/capabilities from session_open. Coordinates require arguments.snapshot and space from observation.",inputSchema:schema(["session_id":prop("string","Live session."),"steps":.object(["type":.string("array"),"items":.object(["type":.string("object")])]),"timeout":prop("number","Workflow scheduling budget, max120 seconds; blocking OS calls may overrun."),"expected_snapshot":prop("integer","Reject known stale baseline.")],required:["session_id","steps"])),
        Tool(name:"session_history",description:"Read retained intent workflow results after restarts. Filter kind automation_step, automation_intent or automation_result; default results. No live input.",inputSchema:schema(["project":prop("string","Project path; optional when bound."),"session_id":prop("string","Optional session filter."),"kind":prop("string","Exact record kind."),"after":prop("integer","Record cursor."),"limit":prop("integer","Page size, default10.")]),annotations:.init(readOnlyHint:true)),
        Tool(name:"interaction_timeline",description:"List timestamped recorded interactions with snapshot references and input counts. Bounded pages; freeze through while paging. Read-only discovery, not full UI dumps.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"session_id":prop("string","Optional recorded session."),"group_id":prop("string","Optional logical group across app captures."),"after":prop("integer","Exclusive interaction ordinal cursor."),"through":prop("integer","Frozen record boundary returned by first page."),"limit":prop("integer","Default 10, maximum 20.")]),annotations:.init(readOnlyHint:true)),
        Tool(name:"interaction_delta",description:"Compare snapshots immediately before the first retained input and after the last input in one interaction. Returns bounded changes, quality and baseline IDs. Missing/incompatible observations remain unavailable; no input replay. ui_diff paginates or compares any compatible snapshots.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"interaction_id":prop("string","Recorded interaction ID.")],required:["interaction_id"]),annotations:.init(readOnlyHint:true)),
        Tool(name:"interaction_result",description:"Explain one recorded interaction: joined input intent/acknowledgement, before/after check outcomes, observation references and uncertainty. Does not imply a persisted save from a current-state check. Details remain available through recording_review.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"interaction_id":prop("string","Interaction ID returned by an action.")],required:["interaction_id"]),annotations:.init(readOnlyHint:true)),
        Tool(name:"diagnostic_query",description:"Audit durable MCP errors, warnings, fallbacks and outcomes, including before project binding. Bounded pages; raw arguments/UI trees omitted. Logging health is explicit. Returned success is not proof of app effect.",inputSchema:schema(["interaction_id":prop("string","Optional interaction filter."),"session_id":prop("string","Optional capture session filter."),"level":prop("string","Level: info, warning, error; issues includes warnings and errors."),"kind":prop("string","Exact diagnostic event kind."),"after":prop("integer","Exclusive sequence cursor."),"limit":prop("integer","Default 10, maximum 20.")]),annotations:.init(readOnlyHint:true)),
        Tool(name:"recording_group",description:"Start or explicitly resume a named logical task across applications and server restarts, or end its current grouping. Preserves history; closes existing capture epochs so new observations receive the selected group. No UI input. Requires bind_project.",inputSchema:schema(["action":prop("string","Operation.",enumValues:["start","resume","end"]),"name":prop("string","Required for start, maximum 200 UTF-8 bytes."),"group_id":prop("string","Required for resume; historical group UUID.")],required:["action"])),
        Tool(name:"recording_sessions",description:"Discover retained named groups or application capture sessions with counts, timestamps and storage explanation. Read-only, bounded pagination; does not initialize or clear history.",inputSchema:schema(["project":prop("string","Optional bound project override."),"view":prop("string","Default recordings.",enumValues:["recordings","groups"]),"group_id":prop("string","Filter capture sessions by logical group."),"after":prop("integer","Exclusive ordinal cursor, default 0."),"limit":prop("integer","Default 10, maximum 20.")]),annotations:.init(readOnlyHint:true)),
        Tool(name:"bind_project",description:"Bind the evidence project once. Subsequent app actions and observations automatically retain history; evidence tools can omit project. No UI input.",inputSchema:schema(["project":prop("string","Absolute project directory.")],required:["project"])),
        Tool(name:"ui_to_text",description:"Inspect a UI as compact structured JSON: fresh app observation or immutable snapshot. Filter roles, IDs, labels, states, subtree/depth and fields. Long strings become leapAsset references. Historical IDs require fresh validation before input. Bind a project first.",inputSchema:schema(["app":appProp,"window":prop("string","Optional window title for fresh observation."),"project":prop("string","Optional bound-project override for historical reads."),"snapshot":prop("integer","Historical snapshot; omit and supply app for a fresh observation."),"types":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"ids":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"fields":.object(["type":.string("array"),"items":.object(["type":.string("string")])]),"contains":prop("string","Label/value substring."),"root":prop("string","Subtree key from this snapshot."),"depth":prop("integer","Maximum rendered depth relative to root."),"enabled":prop("boolean","Filter enabled state."),"selected":prop("boolean","Filter selected state."),"visible":prop("boolean","Frame intersects window; not occlusion."),"after":prop("integer","Exclusive ordinal cursor."),"limit":prop("integer","Maximum 100 nodes; default 20."),"max_bytes":prop("integer","Item budget, 2048–32000; default 8000.")]),annotations:.init(readOnlyHint:true)),
        Tool(name:"leap_asset",description:"Retrieve retained content without escaped JSON blobs. info returns metadata; text returns a bounded plain-text chunk; file materializes exact captured text; auto chooses small text or file. References never fetch newer live values. Capture limits remain explicit.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"asset_id":prop("string","leapAsset.assetId from UI query."),"mode":prop("string","Default auto.",enumValues:["auto","info","text","file"]),"offset":prop("integer","Character offset for text chunks."),"limit":prop("integer","Characters, max 4000; default 2000.")],required:["asset_id"])),
        Tool(name:"ui_diff",description:"Compare two retained snapshots from the same app session/window title. Bounded added/changed/removed controls and changed field names; independent cursor, no live baseline consumption. Partial observations cannot prove disappearance.",inputSchema:schema(["project":prop("string","Optional bound-project override."),"before":prop("integer","Earlier snapshot."),"after_snapshot":prop("integer","Later snapshot."),"after":prop("integer","Exclusive result cursor."),"limit":prop("integer","Default 20, maximum 100."),"max_bytes":prop("integer","Default 8000.")],required:["before","after_snapshot"]),annotations:.init(readOnlyHint:true)),
        Tool(name: "recording_review", description: "Explain recorded activity without dumping trees: overview highlights issues and counts; actions lists input attempts and checks; issues lists errors, unmet postchecks and capture limitations; events groups repeated notifications. Historical evidence, not a fresh app read. Bounded excerpts, evidence references and stable pagination. Project can be omitted while recording one project.", inputSchema:schema(["project":prop("string","Optional project; defaults to the sole active recording project."),"session_id":prop("string","Optional session filter."),"interaction_id":prop("string","Optional interaction: what happened during this action?"),"view":prop("string","Default overview.",enumValues:["overview","actions","issues","events"]),"after":prop("integer","Exclusive page cursor; default 0."),"through":prop("integer","Return this value from the first page to keep subsequent pages consistent."),"limit":prop("integer","Page size 1–50, default 10.")]),annotations:.init(readOnlyHint:true)),
        Tool(name: "recording_start", description: "Attach durable AX event recording to an app before acting. Explicit absolute project path required; creates project-local .leap SQLite journal and Git local exclusion. Records supported notifications between calls while this server runs. Not a complete app event log. Returns session ID and initial state.", inputSchema: schema(["app":appProp,"project":prop("string","Absolute caller project directory, never the target app bundle."),"window":prop("string","Optional exact window title substring to pin.")],required:["app","project"])),
        Tool(name: "recording_stop", description: "Stop this app's recording; retain historical evidence. No app input is sent.", inputSchema:schema(["app":appProp],required:["app"])),
        Tool(name: "recording_query", description: "Read retained session events/actions/snapshots without replaying app input. Historical read-only; does not create a missing store. after is a global record cursor; bounded output. Large snapshot payloads require recording_nodes. Notifications are receipt envelopes, not guaranteed prior values or causal proof.", inputSchema:schema(["project":prop("string","Absolute recorded project root."),"session_id":prop("string","Filter session."),"interaction_id":prop("string","Filter interaction."),"kind":prop("string","Exact kind: ax_notification, subscription, snapshot, action_intent, action_result, capture_gap, session_start, expectation_result."),"contains":prop("string","Case-insensitive substring in retained JSON payload."),"after":prop("integer","Exclusive record cursor, default 0."),"limit":prop("integer","Maximum records, 1–100, default 20.")],required:["project"]),annotations:.init(readOnlyHint:true)),
        Tool(name: "recording_nodes", description: "Read a retained snapshot's nodes with optional label/value text filter and pagination. Does not refresh the app. Stored acquisition can be partial; missing nodes do not prove absence.", inputSchema:schema(["project":prop("string","Absolute recorded project root."),"snapshot":prop("integer","Snapshot sequence ID from state footer or query."),"outline":prop("boolean","Tree structure/labels only; omit values, geometry and actions. Default false."),"contains":prop("string","Optional case-insensitive node JSON text filter."),"after":prop("integer","Exclusive node ordinal cursor, default 0."),"limit":prop("integer","Maximum nodes, 1–100, default 20.")],required:["project","snapshot"]),annotations:.init(readOnlyHint:true)),
        Tool(name: "verified_action", description: "Execute one existing action once, then observe and check a bounded current-state expectation. Never retries ambiguous input. API outcome and expectation are reported separately. This checks current state, not durable saving or event history. To prove persistence, reopen and compare. Supports the wait_for conditions.", inputSchema:schema(["app":appProp,"action":prop("object","Existing action arguments plus tool, e.g. {tool:click,label:Save}. No app required inside."),"expect_label":prop("string","Unique expected element label."),"condition":prop("string","Expected current state.",enumValues:["appears","disappears","enabled","disabled","value_contains"]),"value":prop("string","Expected substring for value_contains."),"timeout":prop("number","Bounded seconds, default 5.")],required:["app","action","expect_label","condition"])),

        Tool(name: "list_apps",
             description: "List running GUI apps (frontmost first, with window counts) and optionally installed apps. Not needed to target an app you already know by name.",
             inputSchema: schema(["include_installed": prop("boolean", "Also list apps in /Applications that are not running (default false).")]),
             annotations: .init(readOnlyHint: true)),

        Tool(name: "get_app_state",
             description: "Read the target app's key window as an indexed accessibility tree (roles, titles, values, extra actions; coordinates only with include_frames). Text by default — the tree is the observation, like a screen reader; no screenshot unless include_screenshot=true. Indices are stable across calls; by default only the diff since the previous state is returned. Call this before acting on an app and after actions whose result you need to see.",
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
            return try await engine.serialized {
                let interaction = await engine.beginInteraction()
                Diagnostics.shared.setContext(["interaction":interaction,"tool":name,"app":args.string("app") ?? ""])
                defer { Diagnostics.shared.setContext([:]) }
                guard Diagnostics.shared.record(level:"info",kind:"tool_started",detail:"Dispatch requested; not evidence of input delivery") != nil else {
                    await engine.endInteraction()
                    return .init(content:[.text(text:"Error: Diagnostic logging unavailable; tool was not dispatched. Check diagnostic store permissions/free space.",annotations:nil,_meta:nil)],isError:true)
                }
                Diagnostics.shared.record(level:"debug",kind:"dispatch_context",detail:"Argument names only: \((params.arguments ?? [:]).keys.sorted().joined(separator:", ")). Values omitted.")
                var result: CallTool.Result
                do { result = try await dispatch(name, args, engine) }
                catch {
                    Diagnostics.shared.record(level:"error",kind:"tool_error",detail:String(describing:error))
                    var message = "Error: \(error)\ninteraction=\(interaction)"
                    if let app = args.string("app"), Self.actionTools.contains(name) || name == "batch" || name == "verified_action" {
                        do { let state = try await engine.state(app:app); message += "\nFresh evidence (does not imply action failed):\n" + state.text }
                        catch { Diagnostics.shared.record(level:"error",kind:"post_error_observation_failed",detail:String(describing:error)); message += "\nPost-error observation unavailable: \(error). Do not blindly repeat prior input." }
                    }
                    result = .init(content:[.text(text:message,annotations:nil,_meta:nil)],isError:true)
                }
                // Successful single-action calls return the recorded outcome/delta rather
                // than duplicating the entire rendered tree. Preserve full errors and batches.
                if result.isError != true && (Self.actionTools.contains(name) || name == "verified_action"),
                   args.bool("then_state") != false {
                    do { if let summary = try await engine.interactionResult() {result = summary.result} }
                    catch { Diagnostics.shared.record(level:"warning",kind:"summary_fallback",detail:"Returning original response; summary failed: \(error). Input not replayed.") }
                }
                await engine.endInteraction()
                Diagnostics.shared.record(level:result.isError == true ? "error":"info",kind:"tool_completed",detail:result.isError == true ? "Returned error; inspect per-operation dispatch evidence. Read-only operations send no input." : "Returned without tool error; does not establish expected app state.")
                if name != "diagnostic_query", let warning=Diagnostics.shared.warningSummary(interaction:interaction) {
                    result = .init(content:result.content + [.text(text:warning,annotations:nil,_meta:nil)],isError:result.isError)
                }
                if let failure=Diagnostics.shared.health() {result = .init(content:result.content + [.text(text:failure,annotations:nil,_meta:nil)],isError:result.isError)}
                return result
            }
        } catch {
            return .init(content: [.text(text: "Error: \(error)", annotations: nil, _meta: nil)], isError: true)
        }
    }

    static func dispatch(_ name: String, _ a: Args, _ engine: Engine) async throws -> CallTool.Result {
        if ["target_list","session_open","session_close","ui_observe","ui_perform","session_history","evidence_read"].contains(name) {
            let encoded = try JSONEncoder().encode(a.raw)
            return try await engine.automation(name,json:String(decoding:encoded,as:UTF8.self)).result
        }
        switch name {
        case "diagnostic_query":
            return try Diagnostics.shared.query(interaction:a.string("interaction_id"),session:a.string("session_id"),level:a.string("level"),kind:a.string("kind"),after:a.int("after") ?? 0,limit:a.int("limit") ?? 10).result
        case "interaction_timeline":
            return try Evidence(project:await engine.recordingProject(a.string("project"))).timeline(session:a.string("session_id"),after:a.int("after") ?? 0,through:a.int("through"),limit:a.int("limit") ?? 10,group:a.string("group_id")).result
        case "interaction_delta":
            guard let id=a.string("interaction_id") else {throw LeapError.unsupported("interaction_id required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).interactionDelta(id).result
        case "interaction_result":
            guard let id=a.string("interaction_id") else {throw LeapError.unsupported("interaction_id required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).interaction(id).result
        case "recording_group":
            guard let action=a.string("action") else {throw LeapError.unsupported("action required")}
            return try await engine.recordingGroup(action:action,name:a.string("name"),id:a.string("group_id")).result
        case "recording_sessions":
            return try Evidence(project:await engine.recordingProject(a.string("project"))).sessions(view:a.string("view") ?? "recordings",group:a.string("group_id"),after:a.int("after") ?? 0,limit:a.int("limit") ?? 10).result
        case "bind_project":
            guard let project=a.string("project") else {throw LeapError.unsupported("project required")}
            return try await engine.bindProject(project).result
        case "ui_to_text":
            let project=try await engine.recordingProject(a.string("project"))
            let snapshot:Int
            if let id=a.int("snapshot") {snapshot=id} else {
                let bound=try await engine.recordingProject(nil)
                guard project==bound else {throw LeapError.unsupported("Fresh UI evidence must use the bound project")}
                snapshot=try await engine.observeSnapshot(app:try a.app(),window:a.string("window"))
            }
            return try Evidence(project:project).ui(snapshot:snapshot,types:a.strings("types"),ids:a.strings("ids"),fields:a.strings("fields"),contains:a.string("contains"),rootKey:a.string("root"),depth:a.int("depth"),enabled:a.bool("enabled"),selected:a.bool("selected"),visible:a.bool("visible"),after:a.int("after") ?? 0,limit:a.int("limit") ?? 20,maxBytes:a.int("max_bytes") ?? 8000).result
        case "leap_asset":
            guard let id=a.string("asset_id") else {throw LeapError.unsupported("asset_id required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).asset(id:id,mode:a.string("mode") ?? "auto",offset:a.int("offset") ?? 0,limit:a.int("limit") ?? 2000).result
        case "ui_diff":
            guard let before=a.int("before"),let after=a.int("after_snapshot") else {throw LeapError.unsupported("before and after_snapshot required")}
            return try Evidence(project:await engine.recordingProject(a.string("project"))).diff(before:before,after:after,cursor:a.int("after") ?? 0,limit:a.int("limit") ?? 20,maxBytes:a.int("max_bytes") ?? 8000).result
        case "recording_review":
            let project = try await engine.recordingProject(a.string("project"))
            return try RecordingStore.query(project:project,session:a.string("session_id"),interaction:a.string("interaction_id"),kind:nil,contains:nil,after:a.int("after") ?? 0,limit:a.int("limit") ?? 10,review:a.string("view") ?? "overview",through:a.int("through")).result
        case "recording_start":
            guard let project=a.string("project") else {throw LeapError.unsupported("project required")}
            return try await engine.startRecording(app:try a.app(),project:project,window:a.string("window")).result
        case "recording_stop": return try await engine.stopRecording(app:try a.app()).result
        case "recording_query", "recording_nodes":
            if name == "recording_nodes", a.int("snapshot") == nil {throw LeapError.unsupported("snapshot sequence ID required")}
            guard let project=a.string("project") else {throw LeapError.unsupported("project required")}
            return try RecordingStore.query(project:project,session:a.string("session_id"),interaction:a.string("interaction_id"),kind:a.string("kind"),contains:a.string("contains"),after:a.int("after") ?? 0,limit:a.int("limit") ?? 20,snapshot:name == "recording_nodes" ? a.int("snapshot") : nil,outline:a.bool("outline") ?? false).result
        case "verified_action":
            guard var obj=a.raw["action"]?.objectValue, let tool=obj["tool"]?.stringValue, Self.actionTools.contains(tool), tool != "wait_for" else {throw LeapError.unsupported("action must name a supported input tool")}
            obj["app"] = .string(try a.app())
            guard let label=a.string("expect_label"), let condition=a.string("condition"), let parsed=Engine.WaitCondition(rawValue:condition) else {throw LeapError.unsupported("expect_label and valid condition required")}
            guard !label.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else {throw LeapError.unsupported("Expectation label must be nonempty; no input sent")}
            if parsed == .valueContains && (a.string("value") ?? "").isEmpty {throw LeapError.unsupported("value_contains requires a nonempty value; no input sent")}
            var before="unknown", beforeMet=false
            do { before = try await engine.waitFor(app:try a.app(),label:label,condition:parsed,value:a.string("value"),timeout:0.1);beforeMet=true } catch { before="not established: \(error)" }
            try await engine.recordCheck(app:try a.app(),phase:"before",label:label,condition:condition,met:beforeMet,detail:before)
            var actionResult="", actionError=false
            do { actionResult=try await performAction(tool,Args(obj),engine) } catch {actionResult="Action outcome uncertain/rejected: \(error)";actionError=true}
            var check="", checkFailed=false
            do {check=try await engine.waitFor(app:try a.app(),label:label,condition:parsed,value:a.string("value"),timeout:a.double("timeout") ?? 5)} catch {check="Expectation not established: \(error)";checkFailed=true}
            try await engine.recordCheck(app:try a.app(),phase:"after",label:label,condition:condition,met:!checkFailed,detail:check)
            let state=try await engine.state(app:try a.app())
            let summary=try await engine.interactionResult() ?? "Before: \(before)\nAction: \(actionResult)\nCurrent-state check: \(check)\nNo input retry occurred."
            return .init(content:[.text(text:summary+"\n"+state.text,annotations:nil,_meta:nil)],isError:actionError || checkFailed)
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
        let app=try argsIn.app()
        let action=try await engine.beginRecordedAction(app:app,tool:name)
        guard Diagnostics.shared.record(level:"info",kind:"input_attempt",detail:"Invoking \(name); actionId=\(action ?? "unrecorded"). Not proof of delivery.",fields:["app":app]) != nil else {throw LeapError.unsupported("Diagnostics unavailable before input; not dispatched")}
        let result:String
        do { result=try await dispatchAction(name,argsIn,engine) }
        catch {
            let original=error
            Diagnostics.shared.record(level:"error",kind:"input_error",detail:"\(name): \(error). Dispatch may have occurred; do not replay.",fields:["app":app])
            do {try await engine.endRecordedAction(app:app,action:action,tool:name,message:String(describing:original),error:true)}
            catch {throw LeapError.unsupported("Input may already have been sent. Original: \(original). Recording failure: \(error). Do not replay.")}
            throw original
        }
        Diagnostics.shared.record(level:"info",kind:"input_returned",detail:"\(name) API returned; expected application effect requires separate check. actionId=\(action ?? "unrecorded")",fields:["app":app])
        do {try await engine.endRecordedAction(app:app,action:action,tool:name,message:result,error:false)}
        catch {throw LeapError.unsupported("Operation returned: \(result). Recording failed after operation: \(error). Do not replay.")}
        return result + (action.map { " [action=\($0)]" } ?? "")
    }

    static func dispatchAction(_ name: String, _ argsIn: Args, _ engine: Engine) async throws -> String {
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

    func strings(_ k:String)->[String] {raw[k]?.arrayValue?.compactMap{$0.stringValue} ?? []}
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
