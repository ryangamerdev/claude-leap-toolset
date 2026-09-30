# Leap issues from Gameday testing: current status (2026-09-29)

This file is the only open list from the Gameday follow-ups. Everything in the earlier `2026-09-28-gameday-*` files is either resolved or retracted. The status below was checked against Leap at commit `b00a8f4` and on macOS 27 / Xcode 27.

Test app: Gameday, project `/Users/ryan/src/gameday`. The Mac app runs as `GamedayMac`, window "Gameday". The simulators are the iPad Air 11-inch (M2) `C2CC7242-41E7-4EB3-BDA9-758D00DF5CDD` and the iPhone 16 `08385748-DE3D-45D0-A0DA-75F69B0191B5`, running Gameday (`local.gameday.ios`). Gameday is landscape-only. Use `diagnostic_query(interaction_id)` for the evidence listed below.

## Open: needs a fix

Fixes for A, C and B are in the commit that updated this file (2026-09-29, entry
`docs/iterations/2026-09-29-device-hub-waits-hit-test.md`). Each item below keeps its original
report and gains a **Fix** and a **Retest** line. Status: fixed in code and checked with the harness,
awaiting native retest.

### A. Device Hub (Xcode 27 simulator host) windows aren't found
- **Background:** Xcode 27 replaced Simulator.app with Device Hub (`com.apple.dt.Devices`, `Xcode.app/Contents/Applications/DeviceHub.app`). `open -a Simulator` fails. Show a device with `open "devices://device/open?id=UDID"`; if no device window appears, run `open -b com.apple.dt.Devices`. Each device gets its own window, titled with the device name (e.g. "iPhone 16").
- **Problem:** `NSWorkspace.runningApplications` lists Device Hub with `processIdentifier` -1, while its windows belong to the real process (CGWindowList `kCGWindowOwnerPID`).
- **Repro:** with the iPhone 16 window visible, `screenshot` `{"app":"com.apple.dt.Devices","window":"iPhone 16"}`.
- **Result:** "No window of Device Hub matches… Windows: none". Interaction `65A7D2A7-BF6D-464E-8068-C6908476AC01`.
- **Needed:**
  - When the app's PID is ≤ 0, resolve it from the window owner PID. Gameday's `scripts/ui-ax.swift` does this; with that fallback, AX dump, press and wait inside Device Hub work.
  - Check every Simulator-specific path (process name, bundle ID `com.apple.iphonesimulator`, window lookup, geometry handling) against Device Hub.
- **Also note:**
  - Device Hub opens devices upright, which draws the landscape-only app sideways. Its toolbar has a "Rotate Left" button.
  - The same window also contains Device Hub's own buttons ("Home", "Screenshot", "Record", "Rotate Left").
  - An AX dump lists each guest app element twice.
- **Fix:**
  - Leap resolves the real process when `processIdentifier` is ≤ 0: the running process whose executable is the app's executable (`proc_pidpath`), else the owner PID of a window named like the app (`kCGWindowOwnerPID`). Sky models processes the same way (`SAIRunningProcess.executablePath` via `proc_pidpath`; `SystemSoftware.CGWindow.ownerPID`).
  - Every Simulator-specific path (keyboard plan, multiline value-write refusal, capabilities line) now treats `com.apple.dt.Devices` like `com.apple.iphonesimulator`. `"Simulator"` resolves to Device Hub when Simulator.app is absent. Frontmost checks use the resolved PID.
  - Each accessibility element is walked once per read (Device Hub exposes the guest content group under two parents; same element by `CFEqual`), so guest elements are listed once.
  - A failed `AXServesAsTitleForUIElements` read (Device Hub buttons return -25200) no longer makes the whole observation incomplete; it only loses label folding for that element.
  - Rotated-guest handling (`[rotated]`, press by accessibility) works unchanged: Device Hub keeps the `iOSContentGroup` subrole.
  - Harness evidence: `screenshot` and `get_app_state` on `{"app":"com.apple.dt.Devices","window":"iPhone 16"}` return the window; iPad `ui_observe` complete (blocking failures 0); `ui_perform` clicks on Route library then Playbook passed their expectations; the Simulator regression scenarios `ios-type-text`, `menu-bar`, `simulator-offscreen-press` pass against Device Hub.
- **Retest:** the original repro (`screenshot` with `window:"iPhone 16"`), then a `ui_perform` click plus wait on the iPad. Check each guest control is listed once and `complete` is true.

### B. Misleading hit_test note on a visible, topmost control
- **Repro:** Gameday Mac with the full-window play editor open. `click` the editor's Cancel (`{"role":"AXButton","label":"Cancel"}`, frame `[1160.5,45.5,94,45]`).
- **Result:** the press worked, but the step's hit_test note named AXButton "Route library", the header button underneath the editor. Interaction `52BA3E2D-F8D0-44C5-9E9B-2533A2DE17C9`, step 1.
- **Needed:** no covered note when the target itself is the top element at that point.
- **Fix:** the hit-test now probes the center and four interior points (25%/75% of width and height). If any point reaches the target, no note is given. A live read-only probe with the editor open: Cancel's center returned "Route library", but three of the five points reached Cancel. Create scenario missed at all five points (all hit the Coaching notes text area), so its correct covered note is kept. Sky asks what is under a point only to resolve coordinates and never reports covering, so this is a Leap-only advisory. Harness: editor Cancel click, interaction `49C7C0BF-4FA7-42E6-82F6-FCAE4F30CAE8` (harness project), `pressed [12]`, no `hit_test`, expectation passed.
- **Retest:** the original repro (editor Cancel: no `hit_test`), and the "Create scenario" case under the editor (the note should still appear).

### C. Simulator waits are still slow and overrun their timeouts
- **Repro:** iPad Air, wait steps (session `AB0BF3D2-3440-4533-BAF0-75DF2DCB07E4`).
- **Result:**

  | Wait | Duration | Interaction |
  | --- | --- | --- |
  | Condition already true | 1689 ms | `FACB13CF-7F91-41D5-9D5C-4BE15D640FDC` |
  | Condition already true | ~1 s | `73EE4A49-12DC-4011-B6EB-401AAA96D53D`, step 0 |
  | `timeout: 5` | 6924 ms | `C29B7B2A-46F7-4639-A42F-1454E364F03A` |
  | `timeout: 10` | 11036 ms | `F9140EC9-E03F-45B2-A990-A115CA0D21E4` |

- **Needed:** return within one 250 ms poll once the condition holds, and stop at `timeout`.
- **Cause:** after the quick polls, every check took a second, full observation for evidence (about 1 s on Simulator host trees). A quick read started just before the deadline could also run past it. Both evidence snapshots (`7752`, `7770`) started more than a second after the condition was decided.
- **Fix:** the read that decided the verdict is saved as the evidence snapshot; no second read. Each read is limited to the time left. Steps report `check_ms` (time spent judging); a failure screenshot is taken afterwards and is not included. Sky has no wait step (it settles about 1 s plus up to 5 s after actions), so this is Leap-only behavior.
- **Harness evidence (iPad, Device Hub):** already-true waits `check_ms` 278 and 403; `timeout: 5` gave `check_ms` 5007 and 5008, step total 5.07 s including the failure screenshot.
- **Retest:** the four waits in the table; compare `check_ms`.

## Fixed and verified (no action)
- `press_key` Escape reaches an open sheet, with and without `foreground`. Interactions `3AF50BCF-C2CE-4691-B9CF-0C92B4F3533F` and `441E6CD5-7926-4FDD-B49A-316D05EFC8EE`.
- A covered single match now carries an accurate hit_test note. "Create scenario" under the play editor is reported as covered by the Coaching notes text area. Interaction `E9E27CA4-19FB-4D9A-A753-C5E534482FCC`, step 2.
- Wait steps no longer record `before_snapshot` or a delta.
- A positive expectation passes after a pointer click: `Revert enabled` returned `passed`. Interaction `ADD627BB-471B-4E06-BF5D-9571DB7180A5`.
- Earlier fixes:
  - "New playbook" press inside a sheet;
  - `ui_inspect`;
  - the overlapping Save pair (`disambiguated: "only enabled match"`);
  - pointer clicks inside a Mac sheet.

## Implemented but not yet exercised (verify when it occurs)
- An uncertain dispatch with a passing expectation should give `execution: "completed"`, `dispatch: "uncertain"` and `dispatch_error`, and the workflow should continue. No AX error occurred during the retest, so this path wasn't hit.
- A positive expectation on a **partial** observation should pass. The retest observation was complete, so this path wasn't hit.

## Not Leap issues (don't fix)
- Mac text-field alert buttons with swapped accessibility names: a Gameday bug, fixed in Gameday.
- The iPad "Team libraries" screen appearing after an AX press on Save: a Simulator AX artifact, which also happens with other AX tools.
