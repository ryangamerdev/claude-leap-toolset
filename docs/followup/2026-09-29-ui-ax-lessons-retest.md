# Open Leap issues from Gameday testing (2026-09-29)

This is the complete list of open items from the Gameday follow-ups. Every other item in the earlier `2026-09-28-gameday-*` files is resolved or retracted. Each item below was reproduced against the current build. Project: `/Users/ryan/src/gameday`; use `diagnostic_query(interaction_id)` for evidence.

Verified fixed in this build: "New playbook" press inside a sheet (re-resolve before press); `ui_inspect`; the Save pair under the route editor (`disambiguated: "only enabled match"`); pointer clicks inside a Mac sheet.

## 1. `press_key` with `foreground: true` is refused while a sheet is open
- **Repro:** Gameday Mac, session opened with `window: "Gameday"`. Open the Playbooks sheet, then `press_key` `{"key":"Escape","foreground":true}`.
- **Result:** `dispatch: "uncertain"`: "Keyboard input would go to Gameday's key window, not to the selected window "Gameday", and the app refused to make it key from the background… Use … foreground=true." Nothing is sent. Session `DFFE9062-1732-4F0E-AD97-35D3D9A5FBB2`, interaction `832B3003-938E-4148-A47F-B0090A37988D`.
- **Needed:** when the key window is a sheet attached to the selected window, deliver the key to it. At minimum, don't tell the caller to set a flag it already set.

## 2. A single covered match is pressed without warning
- **Repro:** Gameday Mac with the full-window play editor open. `click` `{"role":"AXButton","label":"Create scenario"}`. The only match is the browse button at `[851,819.5,93,45]`, underneath the editor.
- **Result:** `pressed [51] via accessibility`, no warning, no visible effect. Interaction `83429694-F3E0-4FBD-AED4-3A74CB46E4DC`.
- **Needed:** apply the covered/topmost check to single matches too, and refuse or flag the press when the target is covered by another layer.

## 3. Simulator waits are not fast
iPad Air simulator, session `6FB0B2EF-0EBA-4404-89D3-146B64891E60`:

| Wait | Duration |
| --- | --- |
| Condition already true at start | 2 s (interaction `B70C3DE2-33AB-4CB5-A822-BFB1669D59FE`, step 0) |
| Condition true within about 1 s | 4 s (same interaction, step 2) |
| `timeout: 10`, never true | 13 s (`263B2C94-41D7-418A-A215-AA1C62EBD758`, step 2) |
| `timeout: 5`, never true | 7 s (`DFBB8A4B-AAA9-48F4-9938-DD7C67514F40`, step 3) |

Each wait step still records a `before_snapshot` and an `after_snapshot`.
- **Needed:** return within the 250 ms poll once the condition holds, and don't overrun `timeout`.

## 4. An uncertain dispatch fails the step even when its expectation passes
- **Repro:** Mac, the New playbook alert's Cancel returned AXError -25205. The step reported `dispatch: "uncertain"`, `verification: "passed"` (the Name field was gone), `execution: "failed"`, and the workflow stopped. Session `1829B7BA-B64F-4DEE-9D98-B2E77FCE0532`, interaction `8CF7225A-6DFB-44BD-9CB7-467BE6555F6B`. The -25205 did not recur on retry, but the handling is deterministic.
- **Needed:** when the expectation passes, continue the workflow and keep `dispatch: "uncertain"` in the record.

## 5. A positive expectation reports `unknown` when the delta proves it
- **Repro:** iPad, a pointer click with expectation `Revert enabled`. The step delta contains `Revert enabled false→true`, but the observation had `complete: false` and the step's verification was `unknown`. Interaction `7D257BD8-C2A3-4B45-AE4F-467B12526574`.
- **Needed:** positive conditions (`exists`, `enabled`, `value_*`) observed in a partial observation should pass. Only absence needs a complete observation.
