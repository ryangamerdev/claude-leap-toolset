# Intent workflow API (version 2)

Installed candidate; native acceptance is pending. Capabilities are not certification.

Open one `session_open(project, app, backend:mac_ax, window?)`. `project` is an existing absolute directory. The response provides session_id. Use `target_list` for discovery. For Simulator guest apps use backend:wda and endpoint from the repo-local WDA runner; app is the guest bundle ID, not Simulator. Opening WDA may launch/activate the guest app but does not reset its data. Unavailable backends fail explicitly.

`ui_observe(session_id)` returns a snapshot ID, complete flag, coordinateSpace, bounds and bounded normalized nodes. Exact selector fields are identifier, label, role and id; contains is explicit; root scopes descendants by observed ID. Fields, depth, after, limit and max_bytes control output. Paginate with snapshot fixed. A returned file is retained JSON, not a request to repeat input. Historical reads after restart also require project. IDs are observation handles, not durable locators.

Example verified workflow:

```json
{
  "session_id": "<session>",
  "steps": [
    {
      "type": "action", "action": "click",
      "selector": {"role": "button", "label": "Save"},
      "before": {"selector": {"label": "Save"}, "condition": "enabled"},
      "expect": {"selector": {"label": "Saved"}, "condition": "exists"},
      "timeout": 5
    },
    {"type": "capture"}
  ]
}
```

`ui_perform` supports action/assert/wait/observe/capture, maximum50 steps. `assert` evaluates once; `wait` polls. Conditions: exists, absent, enabled, disabled, selected, value_equals, value_contains, count. Value/count use `value`. Preconditions use `before`. No dependent step runs after failure or unknown. An already-true postcondition is current-state evidence, not proof of change or persistence. Reopen to verify saved content.

Action arguments:
- click/double_click: selector; or x/y plus snapshot and space from the observation. Mac button/modifiers optional.
- type_text/set_value: selector and arguments.text. set_value Mac only.
- press_key: arguments.key; device backend supports Return, Enter, Backspace, Tab only.
- scroll: selector for control/container plus direction up/down/left/right; Mac pages optional. Mac also accepts x/y with snapshot and space for screenshot-derived targeting when AX geometry is unusable. WDA still requires a selector.
- drag: arguments.from_x/from_y/to_x/to_y, snapshot, space; Mac modifiers optional.
- activate: selected application. Mac foreground:true may be supplied to input actions.
- rotate: device backend only; arguments.orientation PORTRAIT, PORTRAIT_UPSIDEDOWN, LANDSCAPE, LANDSCAPE_RIGHT. These select physical device direction, not a guarantee of an upright host Simulator display. Respect app orientation support. WDA observations retain orientationIdentity and orientationStable because the coarse orientation string merges opposite directions.

Read each step's execution, dispatch, acknowledgement and verification separately. Attempted input is not proof of effect. Uncertain input is never automatically replayed. A failed API acknowledgement may coexist with a satisfied postcondition. The workflow stops either way; inspect retained evidence. Unknown means insufficient observation, not a failed app assertion. Workflow scheduling deadlines do not promise hard cancellation of blocking OS calls.

Coordinates are rejected if the source observation and fresh target/tree/bounds disagree. Reobserve after resize, rotation or user intervention. Device points and screenshot pixels are distinct; do not feed image pixels into device coordinates without a validated scale. Screenshot captures are saved files; use an image viewer for visual questions. Custom canvases need visual verification.

`session_history` lists results and retained JSON file references; kind automation_step/automation_intent/automation_artifact/automation_session narrows discovery. `diagnostic_query` audits backend errors by interaction. `session_close` preserves history and leaves app running. Live sessions expire at server restart; open a new live session and use old evidence for comparison only.

Development regression scenarios: scripts/run-scenario.py executes {session,steps,timeout?} through stdio MCP and records a JSON run result. This is harness evidence, not the native-host acceptance gate. scripts/wda.py provisions the pinned local Simulator runner; consult --help for build/start/status. Runtime artifacts stay ignored in the repository.

`evidence_read(session_id,record,path?,offset?,max_bytes?,project?)` retrieves raw retained JSON or a nested value. path is an array of object keys/array indices, e.g. ["nodes","2","value"]. offset is in characters; max_bytes bounds chunk size. Follow nextOffset; reads never reacquire UI.

Native development checkpoint (2026-09-20): use the explicit mac_ax Simulator session for the Sky-equivalent acceptance path. Information/field toggle and Previous play passed native postconditions. Host AX geometry can remain invalid despite working semantic actions; do not infer valid pointer coordinates from semantic success. WDA observation/history/navigation passed, but the information-toggle touch still had no effect. Neither backend silently substitutes for the other. Gameday is landscape-only; use its existing orientation. Exact WDA rotation tracking and protocol translation are installed candidates awaiting restart acceptance. See the development handoff for next cases rather than repeating failed taps.

Pointer construction errors are surfaced; delivery acknowledgement does not prove effect. Native iPad mac_ax field zoom/reset/pan and foreground sidebar drag scrolling passed visual inspection on 2026-09-20. The window remained stationary. Coordinate wheel scrolling had no visible effect, including after explicit activation; a deliberate drag gesture worked. Do not silently equate wheel delivery with scrolling success or substitute a drag without identifying it. Canvas verification still requires screenshots. These scoped passes do not certify background focus handling, hosted-process routing or other apps. See the development handoff for current acceptance evidence.

Scroll actions now return scroll_effect independently of verification. A scoped scrollbar value change in the requested direction or two coherent descendant displacements intersecting the viewport before OR after can report movement. Full-page motion need not leave the same items visible. Scope uses the selected subtree or explicit arguments.observation_region [x,y,width,height] can report movement_observed; otherwise status is unverified. The region uses the session observation coordinate space and must fit its bounds. For screenshot-derived coordinate scrolling, supply the visible scroll area as observation_region to scope evidence; without it the image comparison covers the whole window and geometry does not infer a target area. Before/after screenshots are retained automatically and compared as bounded grayscale samples, returning visual_change_observed or no_visual_change_observed—not proof of scrolling. Cursor/animation can contribute. Up to four additional observations at200ms intervals (0.8s scheduling budget, bounded by workflow deadline) allow delayed changes; OS calls are not hard-cancelled. No retries or drag fallback. Boundary remains unknown, and capture failures are explicit in scroll_effect.errors and diagnostics. Native iPad negative-case reporting and nested evidence retrieval passed after restart: wheel produced unverified, no_visual_change_observed and boundary unknown in both tested focus modes. Positive movement_observed detection remains pending native acceptance; successful drag control does not exercise scroll_effect.

Text-area AXIdentifier/AXDescription provider failures are retained as unavailableFields metadata, not global state failure. ui_observe.selectorComplete tells whether the selector's coverage is reliable. Prefer role-qualified selectors or observed IDs when optional labels are unavailable. Actions/assertions depending on missing metadata remain uncertain; value/children/security/transport failures still block. This editor-metadata correction awaits native acceptance.

Native 2026-09-20: desktop creation/save/reopen passed with both routes and notes. iPad route/title/player-note persistence passed scoped checks, but an unsupported direct AXValue write displayed coaching notes without persisting them. set_value now refuses direct writes when the provider does not advertise a settable value, after selection replacement is unavailable/unchanged. It returns an explicit error rather than guessing keyboard focus. For such editors, focus the control and use normal type_text; verify save/reopen. A matching immediate value is not evidence of model binding or disk persistence. The guard awaits restarted native acceptance. Sky normal typing retained coaching notes in a subsequent duplicate, but both tools unexpectedly reached Team libraries after Save; that navigation remains unexplained.

Intent action results now retain action, resolved target (ID/index/role/label/frame), and input_result from the backend. The description distinguishes accessibility press from pointer or text delivery; it is acknowledgement detail, never effect/persistence proof. WDA reports its acknowledgement explicitly without inventing a Mac input route. Failed calls may lack input_result; use their error and diagnostic evidence. Target frames remain provider geometry and can be unreliable in Simulator.

Element pointer clicks now use the live control rectangle's center and require that center to be inside the window/scroll viewports. A visible edge does not become a substitute click point; reveal is attempted before refusal. Explicit screenshot-derived coordinates remain supported with snapshot provenance. This cannot repair malformed Simulator AX rectangles. Simulator AXTextArea direct value replacement is refused even when advertised settable if selection replacement cannot complete: repeated native readback matched while saved binding stayed unchanged. Use normal text input and save/reopen checks; native keyboard delivery still needs acceptance.
