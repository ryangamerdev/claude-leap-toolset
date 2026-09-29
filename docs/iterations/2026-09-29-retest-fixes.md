# 2026-09-29 — Gameday retest: sheet key window, hit-test report, fast waits, uncertain continuation, positive evidence

## Outcome and evidence

Input: docs/followup/2026-09-29-ui-ax-lessons-retest.md (the only open list; earlier 2026-09-28-gameday-*
items are resolved or retracted). Confirmed fixed there: New playbook press in a sheet, ui_inspect, the
route-editor Save pair (only enabled match), pointer clicks in a Mac sheet.

Harness (dev build, Calculator — Gameday/Simulators left to the other agent): action with expectation plus
an already-true wait ≈1 s together; a never-true wait with timeout 3 took 3.0 s (earlier: 2 s for
already-true, 7 s for timeout 5). Items 1, 2 and 4 need the other agent's Gameday reproductions.

## Sky reference and changes

1. press_key foreground refused while a sheet is open. Sky sends keys to the process, which routes them to
   its key window. ensureKeyWindow accepts a key window that is a sheet attached to the selected window
   (parent or child relation); the refusal message no longer recommends foreground=true when it was set.
2. Single covered match pressed silently. Sky does no occlusion check; SwiftUI's AX hit-test was shown to
   report hidden elements at visible controls, so it cannot gate input. Selector actions now include
   `hit_test` when the element at the target's center is not the target, a descendant or a close container,
   naming it and stating the uncertainty. Never refuses or chooses.
3. Slow Simulator waits. Wait/assert steps no longer take a full pre-observation (whose post-action settle
   cost up to 5 s); they poll quick reads every 250 ms and take one evidence observation without settle,
   reserving 0.3 s so the timeout is not overrun. They record no delta or before_snapshot.
4. Uncertain dispatch fails the step despite a passing expectation. Sky's timeouts "had already applied".
   On an input error after dispatch, the expectation is checked (quick polling within the step timeout); if it
   passes, the step completes, the workflow continues, `dispatch` stays "uncertain", the raw error moves to
   `dispatch_error`, and a note asks to check side effects.
5. Positive expectations unknown on partial observations. An observed match is positive evidence:
   `exists` passes, `absent` fails, a unique match satisfying enabled/disabled/selected/value_* passes; a
   failing state, absence of a match and counts stay unknown until a complete read. The earlier test that
   encoded "all unknown when incomplete" was updated to the new policy.

## Validation and delivery

`swift test`: 65 tests, 0 failures (new: partial-observation positive evidence). Install identity below.

Installed 2026-09-29T00:39:16Z via `make install` from b00a8f4. SHA256 `bd30a68915df58071987e5b175d059d5660ec06fea1dea18ca57e98dab2fc5c6`. Signature verified; skills match; registration unchanged. Restart pending.
