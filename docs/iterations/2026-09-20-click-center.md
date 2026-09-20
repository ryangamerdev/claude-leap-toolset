# 2026-09-20 — Live control centers and multiline persistence

## Outcome and evidence

Restarted93eefa2 input_result passed native: SaveCB54A752-0C9D-4727-AC0C-169F0F95EABF targeted Save index9 and returned pressed via accessibility; marker hidden, no pointer event. Save rectangle window-relative[895.56,941.50,35.08,63.17] outside780-point window. Team libraries appeared after35.6s, verification unknown. This reproduction is not a coordinate misclick; cause still unresolved.

Session2A065054-1BC5-4E36-A38A-07FF853E581B, local-only raw evidence.1188A4EF-1E68-4A97-BFA1-96B27D3D3B68 dismissed Done, searched and reopened saved LEAP IPAD INPUT0920 - Slant Flat. Coaching retained original Halftime text, not prior replacement. This proves advertised settable is insufficient for Simulator AXTextArea direct-value binding. Title persisted. Pointer click450,666 in notes followed by super+a foreground produced an accent popup rather than select-all; type_text stopped before dispatch because selector unavailable. Interaction7E893397-EF21-4212-A575-09D5148BD232. Do not repeat that chord blindly. Keyboard delivery/focus remains unresolved. Initial text workflow with missing selector was rejected before all actions (95C8496F-21EE-4E8F-8DFD-791A68CB61FB).

User observed incorrect-looking click location and proposed center targeting. Exact Sky clickablePoint midpoint/containment reference confirms a real Leap difference: center of clipped sliver vs original control midpoint; reveal reused indexed rather than live geometry.

## Rationale and alternatives

Read part-0027.c0x1007833a4/0x1007833c4/0x100783668 in local Sky reference. Use fresh rectangle midpoint if inside allowed visible bounds; otherwise existing reveal/recheck path. No screen-coordinate transform guessed. Explicit screenshot coordinates remain explicit. Rejecting all semantic actions would remove working navigation and is not justified. Pointer fix does not explain AXPress Save. For multiline persistence, scope raw-value refusal to Simulator text areas after selection path fails; do not disrupt supported selection editing or other native apps based on one provider.

## Changes

ClickGeometry.center rejects invalid/invisible centers; visibleClickPoint reads live AX frame and keeps actual control midpoint instead of center of clipped remainder. Three regression cases: clipped edge, partially visible center/negative display coordinates, malformed Simulator frame. setValue refuses Simulator AXTextArea raw writes even if settable; logs reason, sends no raw value or fallback keystrokes. Skill updated. Database/history unchanged.

## Validation and delivery

TOOLCHAINS=org.swift.640202609131a swift test --filter ClickGeometryTests:3 passed,0 failures. Existing toolchain duplicate Objective-C class warnings present; exit0. TOOLCHAINS=org.swift.640202609131a python3 scripts/bundle.py builds signed candidate. Install identity artifacts/test-runs/20260920-click-center/install.json; local-only logs/backups. Curated screenshots tracked alongside metadata. Source/installed skills synchronized. New behavior requires restarted native acceptance; no claim geometry tests prove real clicking.

## Remaining work

iPad editor currently open LEAP IPAD INPUT0920 - Slant Flat with original notes and unexpected accent popup from super+a; potential unsaved text/caret mutation. Reobserve and dismiss popup deliberately. Verify new center/reveal behavior in reliable native controls, then solve Simulator focused typing and Save→Team libraries with Sky reference actual dispatch. Keyboard reference0x10072a86c and0x10072ab20 uses event sequences and timestamp refresh; not yet translated/validated, no causal claim. iPad player2 persistence and clean creation gate remain; then Blender and remaining requirements.
