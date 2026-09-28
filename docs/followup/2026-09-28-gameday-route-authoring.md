# Leap follow-up: Gameday route-authoring checks (2026-09-28)

Context: Gameday hybrid route-authoring checks (edit a play's shared route in context, Cancel/Revert, New route replacement warning, scenario copy) on the installed Mac app (`mac_ax`, `local.gameday.mac`) and on the iPad Air 11-inch (M2) and iPhone 16 simulators (`mac_ax` against `Simulator`, window-scoped). Every UI outcome was independently checked against the app's SQLite records. Leap sessions: Mac `05E1FC1D-71DD-4EF1-8A58-8916F2B5489C`, iPad `5A94ADAC-3CF9-4E9F-B9A7-A120EB7BB6D2`, iPhone `EBB38F47-85CD-4785-8327-60BEB97BAF53` (project `/Users/ryan/src/gameday`).

Outcome: Leap completed the whole flow on the Mac. On the iPad it completed steps 1–4; on the iPhone it completed steps 1 and 4. This includes text entry, canvas drawing, alerts and nested full-screen editors. The persisted data matched the intended app behavior every time. No keyboard/text-input failures occurred in this run.

## Issues and gaps (most impactful first)

### 1. Mac alert button: reported target label disagrees with the pressed button
- Create-scenario sheet (`AXSheet[alert]`), buttons Cancel (top) and Create scenario (bottom). Pressing `id: …/AXSheet[alert]#0/AXButton[action-button-1]#0` returned `target.label: "Cancel"`, but its frame `[560,542,240,40]` was the Create button and the effect was Create: the scenario was created and saved, as the persisted record confirms.
- Earlier alerts in the same session mapped `action-button-1` to the destructive/primary action ("Discard changes", "Change Route"), so IDs of the form `action-button-N` are not a stable way to refer to a button across alerts.
- Risk: an agent reads the result, believes it pressed Cancel, and retries (a double create) or abandons. This matches an earlier report of an alert press "dismissing without performing the intended action".
- Suggest: re-read the label at dispatch time and report it. Flag a mismatch when an id selector's recorded label differs from the live label or its frame position. Prefer label selectors for alert buttons in the guide.

### 2. Hidden SwiftUI content stays in the Mac AX tree
- Inactive tab content and the screen underneath a full-window editor remain in the tree: the hidden Route library "Search routes" field, the browse "Edit play" button under the editor, a second Save/Cancel pair.
- Effects: expectations are already true before input (Leap correctly reports `expectation_met_before`), so they cannot prove the action worked. Selectors become ambiguous ("matches 2 elements"), which forced id selectors, and those led to issue 1.
- Suggest: an opt-in "frontmost layer" / hit-testable scope, or automatic scoping to the topmost sheet or modal group, plus an occlusion hint on observed nodes.

### 3. The first action after a Simulator screen transition fails with "Observation incomplete"
- Right after opening a full-screen editor on the iPad, the next `click` failed: "Observation incomplete (blocking read failures…); no input sent". Retrying, or putting a `wait` step first, always worked.
- Suggest: the action step should re-observe within its own timeout until the observation is complete before refusing, still never sending input on an incomplete observation.

### 4. On the iPad, field player buttons aren't reachable through the Simulator host
- The Mac exposes `Y. Select player` buttons on the football field. On the iPad simulator, the same SwiftUI `Button` with `.accessibilityLabel` is absent from the host tree. The app sets the label on all platforms.
- Workaround used: the app's player list ("Select layer: Y · Tight end").
- Worth checking with the WDA backend, which was not tried: target_list reports "requires local WDA runner endpoint".

### 5. Error messages don't say what was wrong
- `ui_perform` rejected a batch with "Unknown step field; no input sent" without naming the field. The causes were `fields` on an `observe` step (which `ui_observe` accepts) and `match` inside `selector`.
- "Invalid selector" also lists the allowed keys but not the offending one.
- Suggest: name the offending key and the step index. Consider accepting `fields` on observe steps for parity with `ui_observe`.

### 6. `root` selector with an observed container ID matched nothing
- `{"role":"AXButton","label":"Save","root":"w/AXWindow[Gameday]#0/AXGroup[]#0"}` returned "No element matches the selector in a complete observation" while that Save existed under that group. Selecting by the full id worked.
- Either the root semantics or the ID churn needs documenting, or the error should explain why the root didn't match.

### 7. Simulator geometry (known) and coordinate clicks (positive)
- Host AX frames are transposed or negative (for example the search field reported 23×613), so indicators are suppressed and semantic presses do the work. This matches the documented limitation.
- Clicks at screenshot-derived coordinates (window points = screenshot px at scale 1) worked for drawing on the iPad canvas, and `drag` worked on the Mac canvas. On both, the first canvas click only gave the canvas focus; the second placed a waypoint. That is app/OS focus behavior, but worth a line in the drawing guidance.

### 8. `set_value` on Simulator text fields: positive data point
- The direct-AX-value fallback ("Readback does not prove application persistence") was used for search, route name and scenario name/description on the iPad and iPhone. **All persisted**: the app's own bindings reacted (Create became enabled, search results changed), and the SQLite records contain the values.
- Mac `set_value` / `type_text` reported "(verified)" and persisted.
- Minor: `set_value` with a value identical to the current one reports success but causes no app-side change, so an expectation that depended on a change failed. A "value unchanged" note would help.

### 9. Useful behavior worth keeping
- `expectation_met_before` notes, per-step deltas, and failure screenshots.
- `diagnostics.db` made a cross-session audit possible: it proved every input in a 2-minute window went to the iPhone window (x=989) and none to the iPad window, which isolated an app issue (next section).

## Not a Leap issue (app): iPad scenario Save opens Team libraries
Saving a newly created scenario on the iPad simulator presents the full-screen Team libraries view immediately; the team card shows the new play count. Reproduced twice. The second time, only the iPad session was active, and the Leap diagnostics show no input to the iPad after Save. It does not happen on the Mac or iPhone. An earlier session saw the same thing with a different, pointer-based tool. It has been reported to the Gameday project.

## Not exercised
- The WDA backend.
- `type_text` on Simulator fields (`set_value` was used).
- iPhone Cancel/Revert and new-route drawing.
- Physical devices.
