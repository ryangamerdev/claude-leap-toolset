# 2026-09-28 — Resume: objective reset, first review checkpoint

## Outcome and evidence

User resumed the paused project with a reset objective: Leap gives agents x-ray vision into
desktop applications (efficient, complete, compact observation plus reliable actions) for
complex workflows. Minor typing glitches are accepted: ChatGPT Sky shows the same missing-`a`
behavior, so the 09-20 keyboard campaign chased a symptom that is not Leap-specific. Priorities:
review/cleanup/close gaps across the rest of Leap, frequent `make install` checkpoints, forward-only
commits (never revert; evolve), push often.

Evidence gathered this session (installed build 7faa53f, dev build via scripts/mcp-call.py):
- Desktop Gameday `get_app_state` complete and compact; AX insertion and desktop keystrokes exact.
- **Invalid as usage evidence:** all live Simulator/foreground typing runs this session. The user was
  actively switching screens and typing on the same machine; foreground activation interrupted them
  and their input interleaved with ours (an iPad Spotlight search appeared). Numbers from
  artifacts/test-runs/20260928-keycode-rotation/step3/step4/trial are recorded only as confounded.
- Code/record-derived (not dependent on those runs):
  1. `flagsChanged` events were built with `CGEvent(source:)`, leaving keycode 0 = kVK_ANSI_A.
  2. Landscape Simulator: `AXGroup/iOSContentGroup` has true landscape screen geometry while its
     descendants report unrotated portrait frames that can fall inside the window on a different
     control (search field reported 36×783). A coordinate click opened the wrong route editor.
     Raw AX shows iOS elements do support AXPress (Leap hides it in rendered action lists).
  3. Settle loop in `Engine.state` started re-scans with `max(0.01, remaining)` budget; retained record
     5274 shows a 0.01 s, 8-node truncated scan that marked the earlier complete observation
     incomplete → `ui_perform` verification `unknown` and a delta of `not_observed` noise.
  4. `ui_perform` deltas embedded full ancestor-path arrays and action lists per node (~12 KB for
     two clicks).

## Rationale and alternatives

Fix supported defects without reopening the typing campaign. Keycode fix is a two-line correctness
change (real keyboards emit per-modifier flagsChanged with the modifier's keycode). For rotated
Simulator, a coordinate transform was rejected: iPad and iPhone windows rotate differently and scale,
so a guessed transform could click wrong controls; detection plus AXPress is exact. Settle: never start
a scan that cannot finish, rather than enlarging timeouts. Deltas: summaries, not ancestry.

The broader churn review (18–19 Sep small Sky-like tool set vs ~20k lines added 20 Sep) is the next
work item; this checkpoint only lands the defects above.

## Changes

- Input.keyboardSequence: flagsChanged only for modifiers actually pressed, with their keycodes
  (55/56/58/59/63), released in reverse; unmodified keys are plain down/up.
- AXNode.untransformedFrame for descendants of a landscape iOSContentGroup; rendered `[rotated]` with
  one explanatory line per state. Clicks on such elements use AXPress in any mode (iOS text fields
  focus via activation); coordinate derivation from their frames is refused (click/drag/scroll).
- Engine.state settle loop stops when less than 0.75 s remains instead of starting a truncated scan.
- AutomationModel.delta: added nodes summarized (index/role/label/value/state/frame); incomplete-scan
  disappearances counted as `notObserved` instead of listed.
- Makefile: `make install` = bundle + install.py --no-build (skills synced by installer).

## Validation and delivery

`swift test`: 56 tests, 0 failures (new: modifier keycodes never 0, no flagsChanged for plain keys,
delta summary without ancestry, notObserved count). Dev-build harness (background, before the user
flagged interference): rotated elements tagged; foreground index click refused with no input;
AXPress focused the iPad and iPhone search fields. Install identity recorded at install time.

## Remaining work

Restart, then native checks with the user's agreement on timing: desktop Gameday ui_perform
navigate/expect (verification should be passed/failed, not unknown), delta size, rotated-Simulator
click by label. Then churn review of the 20 Sep commits for desktop regressions/simplification.
