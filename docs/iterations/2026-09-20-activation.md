# 2026-09-20 — Verify public activation and test foreground geometry

## Outcome and evidence

Ryan correctly noted that no explicit foreground comparison had been made. Calling public activate(Simulator) returned "activated Simulator", but the next read remained background. Source inspection found the public method called NSRunningApplication.activate without checking its result, bypassing Engine's existing verified activation routine.

A native press_key(Escape, foreground:true, then_state:false) used that existing verified routine and returned successfully. Subsequent state reads reported frontmost; the full tree still placed Show play information at relative(418,969) outside1006x780 window(377,58). Therefore actual foreground activation did not correct the geometry in this case. This is stronger evidence than the earlier Window-menu selection, which did not establish frontmost status. Escape was sent once; no play content edited. Simulator is left foreground.

## Rationale and alternatives

Reuse the verified activation path already used for foreground input: AX frontmost/raise, wait, logged LaunchServices fallback when needed, explicit refusal if still inactive. Do not invent a second activation implementation or treat an API request as success. This addresses false-success reporting independently of the unresolved Simulator coordinate-space issue.

## Changes

Public activate now requires Accessibility permission, awaits the existing verified activation routine, records activation_verified and returns success only after verification. Source skill documents the contract. Geometry unchanged; hiding inaccurate markers remains containment.

## Validation and delivery

[Native comparison](../../artifacts/test-runs/20260920-activation/native-results.json) retains the false-success public path and successful verified foreground path plus full frame evidence. This validates the reused routine, not the new public entrypoint until restart. Release build/signature/install identity will be retained in install.json; local rollback bundle and build log stay ignored. Skills-only synchronization required. No redundant mock test substitutes for the native frontmost check.

## Remaining work

After restart call activate from a background Simulator and verify success/frontmost; then investigate coordinate-space mismatch. If user has kept Simulator foreground, the already-frontmost path alone cannot validate activation transition. Previous diagnostics and group continuity scoped passes remain valid. Do not repeat the whole campaign unnecessarily.

## Sky coordinate comparison and delivery

Sky screenshot-coordinate click(910,625) opened information; fresh AX state showed Show field. Restored via element click. Leap screenshot1006x780 at1 point/pixel then click(924,634) also opened information, restored via AX Show field. [Leap baseline](../../artifacts/test-runs/20260920-activation/ipad-coordinate-baseline.png) and [result](../../artifacts/test-runs/20260920-activation/leap-coordinate-result.json). Simulator window origin later changed to(130,99); cause not established, so do not attribute that move to input or user.

Reference /Users/ryan/src/sky/node/sky/dist/project/cua/sky_js/src/targets/mac/client.js click() dispatches elementID or coordinate through helper h(); no Simulator conversion in that client. The native disassembly has stripped function identities; strings convertPoint:toView: and windowUsesFlippedCoordinates do not prove a Simulator mapping. The ipc/Click.d.ts screenshotId contract belongs to another interface and is not evidence of the Mac implementation. Paired behavior demonstrates screenshot-coordinate targeting works in both; AX geometry interpretation remains unresolved.

Installed SHA-256 `13379976548abecfbb7ac433fcaa8a7174e2fb473894b8974091fa73b8a6aa9b`; [identity](../../artifacts/test-runs/20260920-activation/install.json). Signed release and skill synchronization passed; public activate acceptance requires restart.
