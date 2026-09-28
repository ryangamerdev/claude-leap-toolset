# 2026-09-28 — Checkpoint 5 native pass, iPad create/save/reopen gate, pre-met expectations

## Outcome and evidence

Native on 94d2992 (restarted, user hands-off):
- `observe` step returned `matched`/`items` (11 play buttons with index/label/state).
- Coordinate click from snapshot 5883 accepted under geometry-only provenance. Background delivery
  produced no change on Gameday (SwiftUI): with a discriminating expectation (`Edit routes` enabled)
  verification `failed`, delta 0 changes. The same click with `foreground:true` navigated (131
  changes) and `passed`. An earlier run "passed" falsely because `Edit routes`/`Edit play` exist in a
  disabled inactive view before the click: the expectation already held.
- iPad Simulator gate PASSED (mac_ax, landscape, AXPress for rotated elements): New play → Offense →
  set_value Play title "LEAP IPAD 0928 CP5" (verified) → AXPress Coaching notes (focused) →
  foreground type_text "Leap iPad note: read the flat defender." (exact, every `a`) → Save → search
  → Select play → Edit play → title `value_equals` and notes `value_equals` passed → Cancel.
  One step failed only because the agent guessed the wrong role for the search result (honest failure).

## Sky reference

Sky has no verification layer (agent re-reads state), so pre-met expectations and silent background
no-ops are Leap-specific concerns. Sky delivers pointer events process-directed (postToPid with window
fields and a background activation event; research/sky-native-input-audit.md) plus a prepareToInteract/
focus-enforcer stage Leap does not replicate; a read-only trace of that path is in progress.

## Changes

- ui_perform action steps evaluate the expectation against the pre-action snapshot; if it already held,
  the step reports `expectation_met_before: true` with a note (pass does not show the effect).
- Failed pointer actions in background mode with zero observed changes carry a `hint` suggesting
  `foreground:true`; no automatic replay.
- Delta drops frame-only changes for elements whose coordinates are already unreliable (offscreen/rotated).
- PLAN.md and SESSION-CONTINUATION.md: dated 2026-09-28 status/handoff sections added above preserved
  2026-09-20 text.

## Validation and delivery

`swift test`: 61 tests, 0 failures. Not yet installed (awaiting Sky pointer research to decide whether
background pointer delivery changes join this checkpoint).

## Remaining work

Background pointer delivery (Sky trace); duplicate labels; iPhone gate; Blender gate.
