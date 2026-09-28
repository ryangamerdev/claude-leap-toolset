# 2026-09-28 — Agent retest: alert windows, disambiguation limits, window following

## Outcome and evidence

Input: docs/followup/2026-09-28-gameday-route-authoring-retest.md (other agent; fresh test play EARLY 52
X-MERCEDES T-FLAT; five of six cases passed, all data verified: routes 187, formations 64). Remaining:
hidden-layer `{"label":"Save"}` still ambiguous in the nested route editor (covered Save disabled); a single
hidden match pressed without warning; coordinate clicks inside the Mac alert did nothing; selector errors in
before/expect lacked the step index. Gameday's Mac Create-scenario alert has swapped AX names (app bug).

Harness (dev build) findings:
- With an alert up, the focused window is the alert sheet (bounds 669,402 496×304): observation coordinates
  are sheet-relative. After routing pointer events to the front-most app window at the point, a coordinate
  click at the top-drawn alert button dismissed it (plays 179 → 179), consistent with the swapped names.
- The session had pinned the sheet as its window; after the sheet closed the next step failed "Selected
  window changed". Sky's handle follows the key window.
- Hit-test probe (read-only AXUIElementCopyElementAtPosition at control centers, editor open): the visible
  editor Cancel hit-tests to the hidden "Route library" tab button; the hidden "Edit play" hit-tests to the
  editor's notes text area. SwiftUI AX hit-testing reports hidden layers at visible points, so hit-test
  disambiguation (added in 641be0b) could pick the hidden duplicate, and the single-match occlusion flag gave a
  false positive on the visible Cancel. Both removed.
- Operator error: a second harness call reused sheet coordinates without checking that the first call (which
  opened the play editor instead of the alert) had passed; the click landed in the main window. Save/Revert
  were disabled afterwards (no pending change); a later Cancel raised Gameday's "Route Info" alert, dismissed
  via its Cancel (AX press returned -25205; Leap reported uncertain dispatch without retry; alert gone).
  Counts after: plays 179, routes 187, formations 64; "5yd Mesh" intact.

## Sky reference

Sky resolves the pointer target window from ordered windows at the event point
(target(forMouseEventAt:with: orderedWindows)); its app handle follows the key window (SKY-BEHAVIOR §2);
it shows only the sheet while one is up (§3) and prunes empty disabled elements; it does no occlusion
inference, leaving duplicates to the agent.

## Changes

- Pointer delivery (click/drag/scroll) routes to the front-most on-screen app window containing the point.
- Automation sessions without an explicit window follow the key window; observations report `windowChanged`.
- Disambiguation: modal sheet, then only-enabled match; hit-test disambiguation and occlusion flag removed.
- before/expect validation errors name the step index.

## Validation and delivery

`swift test`: 64 tests, 0 failures. Skill intent-workflows reference corrected. Install identity below.

Installed 2026-09-28T23:38:11Z via `make install` from a0bd013. SHA256 `ab3a61d6a091878bd348ca8cc7edcd35222da17a9ba95f436dabb75124877615`. Signature verified; skills match; registration unchanged. Restart pending.
