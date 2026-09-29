# Intent workflow API (version 2)

Installed candidate; native acceptance is pending. Capabilities are not certification.

Open one `session_open(project, app, backend:mac_ax, window?)`. `project` is an existing absolute directory. The response provides session_id. Use `target_list` for discovery. For Simulator guest apps use backend:wda and endpoint from the repo-local WDA runner; app is the guest bundle ID, not Simulator. Opening WDA may launch/activate the guest app but does not reset its data. Unavailable backends fail explicitly.

`ui_observe(session_id)` returns a snapshot ID, complete flag, coordinateSpace, bounds and bounded normalized nodes. Exact selector fields are identifier, label, role and id; contains is explicit; root scopes descendants by observed ID; within scopes by an ancestor's own label (for example `{"role":"AXTextArea","within":"Coaching notes"}`), so full-path IDs need not be copied. Fields, depth, after, limit and max_bytes control output. Paginate with snapshot fixed. A returned file is retained JSON, not a request to repeat input. Historical reads after restart also require project. IDs are observation handles, not durable locators.

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

Synthesized keyboard input now brackets down/up with modifier-state events and restores prior session flags. App keyboard input now remains process-directed in both foreground and background modes. Posted events receive current timestamps. This is transport behavior, not proof of focused-field selection or text persistence. Native validation is pending; never replay an uncertain chord or replacement without checking state.

Consolidated input safeguards: element-directed keyboard typing now requires live focus after app/window preparation. If refused, inspect fresh state and deliberately click the editable control; do not type blindly. Simulator multiline append cannot use raw AXValue either. Unknown key names reject; use type_text for literal strings. Ambiguous semantic action or changed value-write outcomes stop without keyboard replay. Selection readback and text readback are scoped checks, not evidence of saved model persistence. Hosted-window routing and full background focus parity remain unaccepted.

Literal keyboard text now uses current-layout physical keys plus text payload, because Simulator can ignore Unicode payload and interpret keycode0 as A. Simulator characters without a single-stroke layout mapping are rejected before text dispatch; do not retry them. Other apps retain Unicode fallback. CRLF becomes one Return. This candidate needs native acceptance; keyboard layout/focus and saved model state still require verification.

Foreground-first acceptance is the current development baseline. Config `~/.config/leap/leap.json` accepts `insights.enabled` (boolean, default true, read at MCP startup). When false, automatic AX recording/subscriptions, post-action scans/deltas, scroll analysis and failure captures are disabled. Explicit observations, captures and requested expectations still run and retain their evidence; fresh pre-action target validation and diagnostic logs remain. An action without expect returns not_evaluated, no after_snapshot and an explicit disabled-insights marker. This is a diagnostic performance mode, not verified success. Existing history is preserved. Restart after changing config. For the controlled test, observe once, issue foreground input without expect, then explicitly observe its outcome. Avoid repeated polling while comparing load.

Text input prebuilds/routs the whole event sequence and freezes restoration flags before any dispatch. This avoids sampling its own in-flight modifier events between characters. Native validation is pending. Insights-off testing still reproduced missing text, so disabling insights is not an established fix for input reliability.

App keyboard routing is independent of foreground policy: foreground=true activates first, then keys/text/paste use the selected app PID and validate window ownership. No system-wide fallback. This does not establish full hosted-process or same-app responder isolation; inspect actual outcome. Native acceptance pending.

Current development campaign scope: insights restored to enabled (host restart required after config changes). Simulator typing acceptance is deferred at user request; use Simulator clicks/navigation and desktop Gameday editing for the next gates. Do not repeat unresolved Simulator typing trials. This scope decision does not imply typing parity.

Observe steps with a selector return `matched` and up to 20 `items`. Coordinate steps need the referenced snapshot's window, bounds, orientation and coordinate space to still hold; screen content may change (as with Sky's coordinate clicks), so pair them with an expectation.

Follow-up behaviors (2026-09-28):
- `root` scopes by id-path prefix, so any container id (rendered or elided) works; `within` scopes by an
  ancestor's own label.
- When a selector matches several elements, Leap prefers the match inside a modal sheet (as Sky shows only
  the sheet), then the only enabled match. Results report `disambiguated`. Otherwise the step fails and lists
  the matches. Leap does not infer occlusion: SwiftUI keeps hidden layers in the tree and its AX hit-test can
  report hidden elements at visible points, so scope with `within`, `root` or `role`, and use expectations that
  only the new state satisfies (`expectation_met_before` flags ones that already held).
- Sessions opened without `window` follow the key window (a sheet opening or closing sets `windowChanged`);
  with an explicit `window`, a change is an error. While a sheet/alert is the key window, observation
  coordinates are relative to it, and pointer events go to the front-most app window containing the point.
- Before input, the element behind the index must still have the observed id and label; if not, nothing is
  sent ("Target identity changed…"). Prefer label selectors for alert buttons: SwiftUI `action-button-N`
  identifiers are not stable across alerts.
- Action steps with a selector re-observe (up to the step timeout) while a new screen is still loading;
  input is never sent on an incomplete observation. `observation_retries` reports the extra reads.
- Validation names the offending step index and key. Observe steps accept `fields`.
- `set_value` with the current value reports "value unchanged" and sends nothing.
- Canvases: the first click often only focuses the canvas; the second acts. Plan for it rather than retrying
  blindly.
- Simulator host trees omit some SwiftUI controls on canvases (e.g. iPad field player buttons; Sky shows the
  same). Use another route (a list) or the WDA backend.

Combining methods (2026-09-28):
- Selector actions re-resolve the target from a fresh walk just before input; a vanished target sends nothing.
- `ax_result: cannotComplete (-25204)` with `dispatch: uncertain` means the press may have applied (SwiftUI
  often replaces a control while acting). Let the expectation decide; never press again blindly; look for side
  effects such as unexpected navigation.
- Waits poll a cheap read every 250 ms and record one full observation when they resolve.
- `ui_inspect(session_id, selector)` shows raw, unnormalized accessibility attributes, actions and parents.
  Use it to decide whether odd behavior is the app's (e.g. swapped alert labels) or Leap's. Read-only.

Retest fixes (2026-09-29):
- Keys to a window whose sheet/alert is key go to the sheet (process-directed, like Sky).
- `hit_test` on a step names what the accessibility hit-test reports at the target's center when it is not the
  target. Treat it as a hint that the control may be covered; SwiftUI hit-tests can also be imprecise.
- Wait/assert steps poll quickly and stay within their timeout; they record one evidence snapshot, no delta.
- If an input call errors but the expected outcome is observed, the step completes with `dispatch: uncertain`,
  `dispatch_error` and a side-effect note; the workflow continues. Never replay.
- Partial observations: an observed match proves `exists`/positive state and disproves `absent`; absence of a
  match, failing states and counts need a complete read.
