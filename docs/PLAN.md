# Leap completion plan

Updated 2026-09-20. [SPECIFICATION.md](SPECIFICATION.md) is the release contract; existing implementation is replaceable. [FEATURES.md](FEATURES.md) distinguishes implementation from native acceptance. Earlier evolving plans are [archived](research/archive/plan-before-intent-rebuild.md).

## Objective and finish line

Reliable native app operation at least as effective as Sky, demonstrated by desktop Gameday, iPhone/iPad Gameday and separate paired editable Blender basic-shape Mickey-head artifacts. MCP performs targeting, waits, checks and evidence handling; the agent supplies task intent and necessary visual judgment. Do not expand into physical devices, other desktop platforms or a TUI before this gate passes.

## Execution

1. iPad mac_ax field zoom/reset/pan and foreground sidebar drag scrolling now passed native visual checks; window bounds remained stable. Wheel input had no effect even foregrounded. Continue paired Sky/Leap iPhone landscape navigation and scrolling from fresh observations, then desktop coach/create/save/reopen. Use explicit drag when testing touch-style scroll; retain wheel limitation separately. The last Sky field drag had no confirmed movement, so it is not a successful comparison baseline. See [native checkpoint](iterations/2026-09-20-ipad-pointer-native.md). WDA remains optional; no speculative rotation experiments.
2. Correct any shared orchestration/backend defects together; build/install, update skills, commit/push, then restart once for the consolidated candidate. Do not declare success from the runner health check or protocol fixture.
3. Complete both Simulator landscape scroll/tap/drag scenarios and Mac Gameday coach/create/save/reopen through the preferred intent API. Fix unsupported operations only when needed for the fixed gate. Use old primitives diagnostically, labeling bypasses as such.
4. Finish the paired Blender modeling/save/reopen trial without bypassing UI modeling through a construction script. Keep the simple object and equivalent operations; compare outcome and intervention requirements.
5. Execute saved regression scenarios and uncertainty/target-change cases on the accepted build. Close R01–R16 only for stated scope and retained evidence; publish remaining nonblocking limitations.

## Design decisions

New session/observation/workflow orchestration replaces the old agent-managed sequence model. Shared selectors, preconditions, assertions and evidence operate over Mac AX and device-native WDA adapters. Native event/capture primitives and storage are reused for their demonstrated utility, not as an architectural constraint. Legacy tool dispatch remains during native migration; remove redundant surface after equivalent preferred workflows pass.

Record every iteration in docs/iterations. Keep name leap, preserve history, and keep scripts/downloads/builds/evidence under the repository. Runtime artifacts stay ignored with tracked summaries. Configuration and independent logs remain in the user-requested ~/.config/leap and ~/.leap/logs locations.
