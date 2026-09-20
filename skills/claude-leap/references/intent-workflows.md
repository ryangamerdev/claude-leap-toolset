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
- scroll: selector for control/container plus direction up/down/left/right; Mac pages optional.
- drag: arguments.from_x/from_y/to_x/to_y, snapshot, space; Mac modifiers optional.
- activate: selected application. Mac foreground:true may be supplied to input actions.
- rotate: device backend only; arguments.orientation PORTRAIT, PORTRAIT_UPSIDEDOWN, LANDSCAPE, LANDSCAPE_RIGHT.

Read each step's execution, dispatch, acknowledgement and verification separately. Attempted input is not proof of effect. Uncertain input is never automatically replayed. A failed API acknowledgement may coexist with a satisfied postcondition. The workflow stops either way; inspect retained evidence. Unknown means insufficient observation, not a failed app assertion. Workflow scheduling deadlines do not promise hard cancellation of blocking OS calls.

Coordinates are rejected if the source observation and fresh target/tree/bounds disagree. Reobserve after resize, rotation or user intervention. Device points and screenshot pixels are distinct; do not feed image pixels into device coordinates without a validated scale. Screenshot captures are saved files; use an image viewer for visual questions. Custom canvases need visual verification.

`session_history` lists results and retained JSON file references; kind automation_step/automation_intent/automation_artifact/automation_session narrows discovery. `diagnostic_query` audits backend errors by interaction. `session_close` preserves history and leaves app running. Live sessions expire at server restart; open a new live session and use old evidence for comparison only.

Development regression scenarios: scripts/run-scenario.py executes {session,steps,timeout?} through stdio MCP and records a JSON run result. This is harness evidence, not the native-host acceptance gate. scripts/wda.py provisions the pinned local Simulator runner; consult --help for build/start/status. Runtime artifacts stay ignored in the repository.

`evidence_read(session_id,record,path?,offset?,max_bytes?,project?)` retrieves raw retained JSON or a nested value. path is an array of object keys/array indices, e.g. ["nodes","2","value"]. offset is in characters; max_bytes bounds chunk size. Follow nextOffset; reads never reacquire UI.

Native development checkpoint (2026-09-20): WDA iPad observation/history/raw retrieval worked, but the information-button tap returned without the expected UI change both before and after verified host foregrounding. Do not infer effect from acknowledgement. Numeric bounds comparison now fixes false stale-coordinate rejection; native coordinate acceptance awaits restart.
