# 2026-09-20 — Restarted iPad pointer acceptance

## Outcome and evidence

Native mac_ax MCP testing after the user restart resolved the previous before-input bounds rejection. Session E79E97BB-3B80-4436-B937-402A07377555 targeted Simulator iPad Air11-inch(M2), landscape Gameday. Double-click field zoom, click reset, field pan, second reset and foreground sidebar drag scrolling all produced visible effects. User independently reported seeing the sidebar move. Thirty retained snapshot bounds were identical: [130,99,1006,780]. The field moved, not the Simulator window.

Coordinate wheel scrolling produced no visible effect both without foreground:true and after explicit activation with foreground:true. Early successful actions omitted foreground:true; OS frontmost state was not independently recorded, so this is not certified background acceptance. Sky zoom/reset had passed previously; the current Sky field drag600,445→675,490 showed no confirmed movement. Do not claim a paired drag pass.

## Rationale and alternatives

Evidence supports the numeric normalization fix and useful targeted pointer behavior, not universal focus/input parity. A touch-style sidebar drag178,595→178,345 worked where wheel events did not. This distinguishes the gesture paths but does not establish why wheel events had no effect. Preserve the wheel limitation rather than add an unverified automatic fallback. Use explicit gestures and visual verification while progressing through the fixed release gate.

## Changes

No implementation or binary change. Updated FEATURES, PLAN, continuation and skill reference to replace stale restart instructions with scoped acceptance and limitations. Curated screenshots and complete workflow results retain evidence outside the ignored runtime store. Original .leap records remain untouched.

## Validation and delivery

Installed SHA256339a3ebcc4abdd2115d19575cabe7f292b210cf3dba2849d5f67afabe61e00dd (commit879b575); native MCP was restarted before this trial. [Results and snapshot metadata](../../artifacts/test-runs/20260920-ipad-pointer-native/native-results.json). Images: [baseline](../../artifacts/test-runs/20260920-ipad-pointer-native/baseline.png), [zoom](../../artifacts/test-runs/20260920-ipad-pointer-native/zoom.png), [pan](../../artifacts/test-runs/20260920-ipad-pointer-native/pan.png), [sidebar scroll](../../artifacts/test-runs/20260920-ipad-pointer-native/sidebar-scrolled.png), [restored](../../artifacts/test-runs/20260920-ipad-pointer-native/restored.png). Original paths inside results are local-only ignored .leap files.

Zoom interaction C909957B-26AF-433C-A2FB-BCC6BF7C0F0B; pan BEA8CDD4-B7E2-47B1-9EF3-069D7BFCFC4F; wheel961D0F69-3CAF-46A4-97D8-D5B384E9C891 and8397614E-25CB-4D6E-8D8C-72B0304444BA; sidebar drag929C9165-D346-4BEC-965E-BE183CF1490A and restoreB47F9A1B-5BB4-4265-B177-A8D0AB81FDC7. Actions acknowledged; verification remains not_evaluated because no automatic canvas postcondition was supplied. Passes above are agent visual judgments, not automatic assertion passes. Sidebar deltas57/50 changes were bounded to12 in responses; retained results preserve the references. Two advisory AX read failures persisted with no blocking failures; geometry remains unreliable for host-derived control coordinates.

Session closed without terminating app. Original play5 of11 and default field restored; sidebar returned to top range, not pixel-identical state. No filter selections intentionally changed. No retention pruning. Skills-only installer ran; quick_validate passed; source and both installed claude-leap skill directories matched via diff -qr. No rebuild or restart required for this documentation/evidence checkpoint. Commit/push follows repository workflow.

## Remaining work

Next: fresh paired Sky/Leap iPhone landscape navigation and scrolling, then desktop coach/create/save/reopen and paired Blender modeling/save/reopen. Wheel effect, full background focus/coexistence, hosted-process routing, WDA information touch and exact orientation acceptance remain open. No release certification or complete parity claim.
