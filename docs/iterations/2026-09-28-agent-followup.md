# 2026-09-28 — Agent follow-up: route-authoring feedback resolved

## Outcome and evidence

Input: docs/followup/2026-09-28-gameday-route-authoring.md (another agent's Mac/iPad/iPhone Gameday
route-authoring run; every outcome checked against SQLite). Leap completed the Mac flow and most Simulator
steps; issues below. Harness (dev build, background, separate project): Playbook → Edit play → observe
Cancel (`fields` accepted) → Cancel, all `passed`; a step with an unknown field was rejected before any
input, naming "Step 3". The duplicate-Cancel screen did not recur in this state, so hit-test disambiguation
awaits the other agent's native rerun.

## Issues, Sky reference and changes

1. Alert press reported "Cancel" but pressed Create. Cause: the element table is keyed by content key; two
   nodes sharing a key share an index, and the later overwrites the earlier (render builds `table[idx]`).
   Sky rejects stale targets ("The element ID is no longer valid"). Changes: AXWalker.makeKeysUnique makes
   keys unique per snapshot (`~2` suffix, diagnostic `duplicate_key`); automationInput refuses input unless
   the indexed element has the observed id and label ("Target identity changed…").
2. Hidden SwiftUI layers make selectors ambiguous. Sky shows only the sheet while one is up (SKY-BEHAVIOR §3);
   otherwise it renders everything (pruneEmptyDisabledElements only). Changes: prefer matches inside a modal
   sheet; then keep the single match that is topmost at its own center via AXUIElementCopyElementAtPosition
   (Leap-only; unreliable geometry never judged). Result field `disambiguated`.
3. First action after a Simulator transition refused as incomplete. Sky waits ~1 s + up to 5 s while state
   changes. Change: selector steps re-observe every 250 ms until complete within the step timeout (≤10 s);
   still no input on incomplete observations; `observation_retries`.
4. iPad field player buttons absent from the Simulator host tree. Sky shows the same (iOS field canvas
   childless, SKY-BEHAVIOR §6). Documented; WDA or list routes.
5. Errors did not name the offending key. Changes: step validation names index and unknown fields (allowed
   list); selector validation names unknown/non-string keys; `fields` accepted on observe steps.
6. `root` with a container id matched nothing: elided containers are not in `ancestors`. Change: root also
   matches by id-path prefix.
7. Canvas first click focuses: guidance added.
8. set_value with the current value: now "value unchanged … nothing sent".

## Validation and delivery

`swift test`: 64 tests, 0 failures (new: unique keys, root prefix, named selector errors). Skill updated
(intent-workflows reference). Install identity below; native verification by the other agent pending.

Installed 2026-09-28T23:11:42Z via `make install` from 641be0b. SHA256 `5b2b1683c3e2d8e7b48b5b2f14ed6af3f52f9d2cea26b652f040cf0932bf3883`. Signature verified; skills match; registration unchanged. Restart pending.
