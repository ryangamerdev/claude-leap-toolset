# Current handoff — native acceptance

Updated 2026-09-20. Read SPECIFICATION.md, PLAN.md, FEATURES.md and the source skill. Preserve registration leap, .leap history and commit/push after build/install.

## Latest native checkpoint

[Iteration](iterations/2026-09-20-ipad-pointer-native.md), [tracked results](../artifacts/test-runs/20260920-ipad-pointer-native/native-results.json). Installed build SHA256339a3ebcc4abdd2115d19575cabe7f292b210cf3dba2849d5f67afabe61e00dd, implementation commit879b575. Restarted and tested via native MCP. Mac bounds rejection resolved: iPad field zoom/reset/pan and foreground sidebar drag scrolling passed visual inspection, window stationary. Wheel scroll had no effect even foregrounded. Sky zoom/reset previously passed; latest Sky drag had no confirmed movement. No blanket parity claim.

Session E79E97BB-3B80-4436-B937-402A07377555 closed; history retained. Field default, ANY OSCAR VICK ·3-4,5 of11. Sidebar returned to top range, not identical pixels; no filters intentionally changed. Simulator explicitly activated and may remain foreground. Gameday stays landscape-only. Two advisory AX read failures persist, no blocking failures in trial; host AX geometry still unsuitable for deriving coordinates. Use fresh screenshots and window_points.

NEXT: paired Sky/Leap iPhone landscape navigation/scroll trial, then desktop Gameday coach/create/save/reopen and paired Blender basic-shape head UI modeling/save/reopen. Open a new native session; use fresh device/window identity and screenshots. Explicit foreground if needed, report actual observed focus separately from omitted foreground flag. Wheel route remains an unresolved limitation; touch-style drag works on iPad and is an explicit alternative. Do not silently fallback.

No binary changes in this checkpoint; no restart needed. Skill reference updated and synchronized. Read research/sky-native-input-audit.md for reference limitations: hosted-process routing and full synthetic focus tracking remain gaps. WDA information touch still ineffective; orientation correction awaits scoped native acceptance. Do not repeat speculative rotation or failed taps.
