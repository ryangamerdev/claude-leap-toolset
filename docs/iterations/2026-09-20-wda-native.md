# 2026-09-20 — First native WDA trial and numeric bounds correction

## Outcome and evidence

After confirmed host restart, native session_open attached to local.gameday.ios through WDA8100. Session A8A182F5-52D5-4388-950F-50018F4A252D retained619 normalized nodes, device bounds1180×820, landscape orientation. Information button frame(1120,679,20,20) agrees with the screenshot location; unlike the old host AX rectangle, this one lies within the intended device screen.

A selector-based tap returned acknowledgement but did not establish Show field; screenshot still displayed the field. Explicit activate(Simulator) returned verified frontmost, then a separate semantic tap also failed its postcheck. WDA runner trace shows XCTest tap and event synthesis, not a backend error. The location/effect of that synthesized event remains unresolved; foreground was not a demonstrated remedy. No automatic input replay occurred. These were deliberately separate diagnostic cases after observing unchanged state.

Coordinate click(1130,689), based on snapshot763, was rejected before dispatch. Stored763 and fresh767 have exactly equal bounds, orientation and all619 nodes. Source guard compared bounds through String(describing:), which differs between native Swift numeric arrays and deserialized Foundation arrays. This is a confirmed false stale-target rejection, separate from the unresolved semantic tap.

Native session_history returned all three results; evidence_read returned step0 from result766 without recapture. Session closed and app left running. [Curated evidence](../../artifacts/test-runs/20260920-wda-native/results.json), [failure screenshot](../../artifacts/test-runs/20260920-wda-native/ipad-after-tap.png). Full .leap snapshots/paths in the results are local-only.

## Rationale and alternatives

Compare four finite numeric components directly. Debug-format text is not a data equality contract. Preserve all remaining provenance checks (session, coordinate space, window, orientation, full normalized tree) rather than weakening stale-input protection to force the click through. Do not infer that this fixes XCTest tap behavior. Coordinate and portrait/landscape comparisons are the next diagnostic cases; do not add an unverified transform or silent Mac fallback.

## Changes

AutomationModel.sameBounds normalizes both arrays to numbers and rejects missing/malformed/nonfinite geometry. AutomationEngine uses it in the coordinate gate. Regression test covers JSON round-trip equality, changed orientation-sized bounds, missing component and NaN. Source skill records native WDA limitations and next acceptance, without claiming general success.

## Validation and delivery

Eight focused AutomationModel tests passed. Release build/signature passed. Installed SHA256 `6df9b4060129ea9fb5f49758bc2114ef24f454e4582570436298514366f1d7a9`; [identity](../../artifacts/test-runs/20260920-wda-native/install.json). Rollback bundle, build/test logs are ignored/local-only within repo. Skills-only synchronization run and byte equality checked. Loaded MCP still runs previous b727dc candidate; numeric correction requires restart/native verification.

## Remaining work

Restart, open a new WDA session on existing iPad endpoint, observe current information control, and make one explicit device-coordinate tap with current snapshot/space. Verify postcondition and screenshot; if unchanged, compare portrait/landscape and backend event coordinates before altering dispatch. WDA observation costs roughly9 seconds per full acquisition and emits noisy custom-action probe logs; performance remains an issue. Both semantic tap cases failed, not certified. Fixed Gameday/Simulator/Blender gate remains open.
