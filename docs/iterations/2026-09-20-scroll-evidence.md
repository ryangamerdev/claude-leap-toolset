# 2026-09-20 — Scroll-effect evidence

## Outcome and evidence

User correctly distinguished viewport movement from application-content changes and requested implementation whenever investigation produces a supported solution. Prior native sidebar drag visibly worked; wheel calls had no confirmed visible effect. Zero AX delta alone cannot prove scroll failure. Sky's inspected JS scroll interface acknowledges an action without an effect verdict; native settling symbol includes scroll events, but universal displacement verification was not established. This iteration improves observation, not wheel event delivery.

## Rationale and alternatives

Separate delivery, explicit expectation checks, and observed effects. Requiring label/value changes would miss scrolling. Treating any changed screenshot as successful scrolling would mistake cursor movement/animation for success. Automatically retrying or silently switching to drag could apply duplicate input. Chosen design collects scoped position evidence and retained visual evidence, reports uncertainty and never replays input. Boundary status remains unknown because lack of movement does not establish an edge.

## Changes

Scroll actions return scroll_effect. Two descendants moving coherently in the requested direction inside the selected subtree or explicit observation_region can report movement_observed. Incomplete reads or changed target geometry invalidate that verdict. Coordinate targets without a region do not infer a scroll container from unreliable Simulator AX geometry. The optional [x,y,width,height] observation_region uses session coordinates and must fit bounds; region can scope screenshot evidence without trusting the tree.

Before/after screenshots are saved automatically; comparison samples128x128 grayscale pixels, difference threshold12 and more than32 changed pixels. It reports visual_change_observed or no_visual_change_observed separately from movement status. Full saved images remain available for inspection; response contains compact statistics/references, not images inline. Unscoped images compare the whole window and explicitly say so. Sampling can miss subtle movement and include animations/cursor effects; it is not optical-flow verification.

Up to four additional observations200ms apart, within a0.8-second scheduling budget and workflow deadline, allow delayed changes. Blocking OS acquisition is not hard-cancelled. This is bounded effect sampling, not a guarantee of settled UI. Existing explicit expectation verdicts remain separate. Capture/comparison failures appear in scroll_effect.errors and independent diagnostics; input is not silently replayed. Generic deltas now include offscreen state changes. Capture latency can exhaust the deadline before dispatch; that condition refuses input explicitly.

## Validation and delivery

Three focused ScrollEvidenceTests passed: coherent directional displacement versus unchanged/unscoped/unrelated/wrong-direction data; region bounds and exclusion; retained native screenshot comparison showing unchanged images versus actual sidebar movement. These are harness/unit checks using retained evidence, not native acceptance of the installed feature. Build/signature verification passed. Installed SHA2561667ba6a99632d29412b635f83d45f072011bd10c794f658fac899f8fa10af9a; [install metadata](../../artifacts/test-runs/20260920-scroll-evidence/install.json). Test/build logs and rollback bundle are ignored local-only under artifacts/test-runs/20260920-scroll-evidence and artifacts/backups/20260920-scroll-evidence. Skills-only installer ran; source and both installed skill directories matched. Registration leap unchanged; all .leap history preserved. Loaded MCP has not restarted onto this build.

Updated skill reference, FEATURES, PLAN and continuation. Recorded user's investigation-to-implementation preference in AGENTS.md. Commit/push before restart handoff.

## Remaining work

Restart, open fresh iPad mac_ax session, capture current landscape window and scope the sidebar with observation_region. Wheel once, inspect reported effect plus retained images; foreground comparison if needed. Use an explicit drag as a visible control. Verify no-movement never becomes a boundary claim, history references work, and capture overhead is acceptable. No wheel-delivery fix, native acceptance or automatic canvas semantic verification claimed. Then iPhone, desktop save/reopen and paired Blender gate.
