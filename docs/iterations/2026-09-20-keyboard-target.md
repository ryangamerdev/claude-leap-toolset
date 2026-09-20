# 2026-09-20 — Trace app keyboard target and remove global delivery

## Outcome and evidence

User challenged incomplete use of Sky and provided full shard paths. Revisited full symbol manifest and traced app controller, target resolver, event factory/sender and completion. See research/sky-keyboard-controller-trace.md for exact addresses, coverage and uncertainty. f1ccb2a still produced Red from Read in snapshot3588; user saw a in ChatGPT. Subsequent append/read interrupted. No native actions during audit. Wrong-app event confirmed by user observation; attribution of all historical missing letters remains uncertain.

## Rationale and alternatives

Sky app keyboard branches use send(to:resolvedPID), not the global sender previously noticed elsewhere. Leap chose global .system whenever foreground=true. Copy the actual caller's route; activation does not require global delivery. A foreground check alone has a race. Public app-PID delivery removes that global-stream path; full hosted-process routing remains unimplemented, not guessed from private structs. Focus/responder changes inside target process remain possible. Background parity deferred.

## Changes

withInput now optionally activates, ensures target key window, resolves owner window and returns process-directed Delivery for all app keyboard actions. Input helper validates pid/window ownership. Chord/text/paste share it. Logs target PID/window. No global fallback, no timing change, insights remain false. Source/installed skills document restriction and remaining limitations. Added regression checking all modifier/down/up/restoration event target PIDs and ownership rejection. Retained reference index script/output.

## Validation and delivery

Focused AppKeyboardRoutingTests, TextKeyPlanTests, KeyboardSequenceTests run without input injection;9 tests passed. Build/install identity in artifacts/test-runs/20260920-keyboard-target/install.json. Logs/rollback local-only. Source skill sync required at install. No native candidate success claimed.

## Remaining work

Restart then fresh iPad state; foreground app and exact text trial with insights off. Do not issue system-wide key tests. Verify intended text, save/reopen, remaining iPad/desktop/Blender gates. Process targeting change is not full Sky focus/hosted parity. User acceptance allows foreground operation. Preserve all history and name leap, commit/push before restart.

Final delivery2026-09-20T17:28:57Z SHA256 `f3e621d9231c10ed167e0650313b4be50acd03a1d934e077b90870f0ef2aece2`. Signature verified; tool description and source/installed skills synchronized. Insights false; registration leap unchanged. Native restart/test pending. Reference index covers134750 names across90 shards; body review limited to documented path.
