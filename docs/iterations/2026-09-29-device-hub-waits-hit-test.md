# 2026-09-29 — Device Hub (Xcode 27), fast bounded waits, multi-point hit_test

## Outcome and evidence

The three open items in docs/followup/2026-09-29-ui-ax-lessons-retest.md, fixed in the order the
other agent gave (A, C, B).

- **A. Device Hub.** On macOS 27 / Xcode 27, Simulator.app is replaced by Device Hub
  (`com.apple.dt.Devices`). Probe: `NSRunningApplication` reports processIdentifier -1, even when
  looked up by pid, while its windows and AX server belong to pid 27091. Leap built its session from
  -1, so no windows were found (interaction 65A7D2A7). With that fixed, three more Device Hub issues
  appeared:
  - Guest elements were listed twice. A probe showed the same element (`CFEqual`) reachable under
    two parents.
  - Every Device Hub read was incomplete. The retained details showed `AXServesAsTitleForUIElements`
    failing with -25200 on a Device Hub button, and that attribute was classified as blocking.
  - The "Simulator" name no longer resolved to anything.
- **C. Waits.** Retained snapshots 7752 and 7770 (Gameday project) started more than a second after
  their wait was decided. After the quick polls, the check took a second, full observation for
  evidence, and a quick read started near the deadline could run past it.
- **B. hit_test.** A live read-only probe with the Gameday editor open: at Cancel's center the AX
  hit-test returns the hidden "Route library", but three of four interior points reach Cancel.
  Create scenario (genuinely covered) misses at all five points: all hit the Coaching notes text area.
  Local-only: artifacts/test-runs/20260929-devicehub/hit-probe.txt.

## Sky reference and rationale

- **Process id.** Sky models processes by pid, with `SAIRunningProcess.executablePath` via
  `proc_pidpath` (decompiled part-0008.c:30562) and window ownership through
  `SystemSoftware.CGWindow.ownerPID` (`kCGWindowOwnerPID`, part-0008.c:51886). Sky has no Device
  Hub strings. Leap follows the same two sources: first the process whose executable matches, then
  the owner of a window named like the app.
- **Walk each element once.** Sky's Device Hub behavior is not observable (its traces predate
  Device Hub). This is a Leap-specific fix, based on the probe.
- **Title relation.** Sky reads this relation in associateTitleUIElements and has no notion of a
  complete read, so a failure cannot block anything. Treating the failure as affecting that element
  only matches Sky's effect.
- **Waits.** Sky has no wait step; it settles for about 1 s plus up to 5 s after actions
  (SKY-BEHAVIOR §8, §10). This is a Leap-only feature, so Leap sets its own contract: return within
  one poll of the condition holding, and end at the timeout.
- **hit_test.** Sky uses a single-point `element(at:)` only to resolve coordinates (part-0025.c:11121)
  and never reports covering. Leap's advisory stays, and becomes multi-point to avoid SwiftUI's
  hidden-layer false positive while still catching truly covered controls.

## Changes

- `AppResolver.pid(of:)` returns the real process id: executable match via `proc_pidpath` (cached,
  revalidated), else the window owner. `isFrontmost(pid)` compares resolved pids. AppSession,
  Engine sessions, activation and pointer focus checks use the resolved pid.
- `simulatorHostBundles` includes `com.apple.dt.Devices`; the keyboard plan, the multiline refusal
  and the capabilities line use it. "Simulator" / `com.apple.iphonesimulator` resolve to Device Hub
  when Simulator.app is not installed.
- `VisitedElements`: each AX element is walked once per snapshot.
- `AXServesAsTitleForUIElements` is now a node-scoped (advisory) attribute.
- `automationCheck`: the deciding quick read becomes the evidence snapshot; each read is limited to
  the remaining time; `check_ms` is recorded per expectation. Observation building is split into
  `automationObservation` and `automationSaveObservation`.
- `hitTestReport` probes five points and stays silent if any reaches the target.
- The `indicator_suppressed` diagnostic joins the echo kinds; the result line already says
  "location indicator hidden".
- Scenarios updated for Device Hub and current Gameday data: menu item title format; navigate
  Home before Flashcards; read the value with a full read after typing; drop the SLIDE=4 data
  assumption (77 plays now).
- Skill: Device Hub notes in ui-details; wait timing and hit_test in intent-workflows.

## Validation and delivery

- `make test`: 69 tests, 0 failures (new: element visited once, Device Hub host bundle, title
  relation advisory).
- Harness, dev bundle, Device Hub (local-only logs in artifacts/test-runs/20260929-devicehub/):
  - The follow-up repro (`screenshot` with window "iPhone 16") and `get_app_state` both work.
  - Each guest element is listed once; iPad `ui_observe` complete with 0 blocking failures.
  - `ui_perform` clicks on Route library then Playbook passed, `check_ms` 360 and 290.
  - Already-true waits: `check_ms` 278 and 403. `timeout: 5`: `check_ms` 5007 and 5008 (was 6924 ms).
- Harness, Gameday Mac: editor Cancel `pressed [12]` with no `hit_test`, expectation passed
  (interaction 49C7C0BF, harness project).
- `make scenarios` desktop 7/7. Simulator set: ios-type-text, menu-bar and simulator-offscreen-press
  pass against Device Hub.
- share-indicator fails on macOS 27 for Gameday too: `check-indicator` lists no Control Center items
  at all. Recorded as open; not investigated here.
- Not native acceptance; the installed build needs a session restart.

## Remaining work

- Native retest of A, C and B per the follow-up file.
- macOS 27 screen-recording indicator detection (the check-indicator script, possibly ShareIndicator
  itself).
- Gameday data drift: the SLIDE search no longer matches plays; scenarios no longer assume counts.

Installed 2026-09-30T00:21:24Z via `make install` from the commit containing this entry. Binary SHA256 `637e6ee8c0db87865ec8c2a4ce63fcd39b8dcdb5db7d31449fbdcbb4987a5417`. Signature
verified; source and installed claude-leap skill trees match (Claude and Codex); registration `leap`
unchanged. Loaded MCP not yet restarted onto this build.
