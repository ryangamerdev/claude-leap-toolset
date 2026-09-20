# 2026-09-20 — Native Mac coordinate bounds correction

## Outcome and evidence

User restarted for native Sky-pointer acceptance. Native mac_ax Simulator session5CC6C6B5-1A67-4185-867E-7FE30F83C174 opened and captured the landscape iPad window:1006×780 pixels,1 point/pixel, snapshot892. Field double-click612,450 using that snapshot was rejected before input: Coordinate bounds unavailable, interaction0BB5B5EC-F161-4419-ABB2-728B74E68A87, before897/after899. Subsequent capture step skipped; failure image saved automatically. No pointer action or app state change. Session closed with history retained. [Native results](../../artifacts/test-runs/20260920-mac-bounds/native-results.json); referenced .leap files are local-only.

## Rationale and alternatives

Mac automationObserve constructs bounds from CGRect's CGFloat components. Equality already normalized via NSNumber, but the following range check directly cast the live array to [Double], producing an empty array. This is an adapter-boundary type bug, not failed click delivery, focus, stale geometry or Simulator coordinate rotation. Normalize numeric bounds once and use that function in both equality and range checking; retain provenance protections. No input-path workaround or alternate backend needed.

## Changes

AutomationModel.coordinateBounds accepts live CGFloat/Double and JSON NSNumber arrays; requires four finite non-boolean numbers with positive dimensions and returns Double components. sameBounds and AutomationEngine range guard both use it. Regression test covers live CGFloat and JSON round trip, boolean, zero dimension and infinity. Source skill checkpoint and progress docs updated; handoff condensed to remove superseded next-step instructions while preserving historical iteration links.

## Validation and delivery

Eleven AutomationModel tests passed. Search found no remaining [Double] array casts in LeapCore. Signed release build and signature verification passed. Installed SHA256339a3ebcc4abdd2115d19575cabe7f292b210cf3dba2849d5f67afabe61e00dd; [metadata](../../artifacts/test-runs/20260920-mac-bounds/install.json). Skills-only install synchronized Claude/Codex copies and source bytes matched. Registration leap unchanged. Build/test logs and rollback app are local-only under artifacts/test-runs/20260920-mac-bounds and artifacts/backups/20260920-mac-bounds. New binary has not been loaded/tested through native MCP; restart required.

## Remaining work

Repeat fresh-capture Mac field double-click/zoom/reset then drag after restart. Prior pointer/focus correction remains unverified because this guard blocked dispatch. Confirm field motion and stable Simulator window; compare explicit foreground if background fails. No blanket Sky parity, scroll or Blender acceptance claim.
