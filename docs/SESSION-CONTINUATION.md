# Current handoff — intent rebuild

Updated 2026-09-20. Read [SPECIFICATION.md](SPECIFICATION.md), [PLAN.md](PLAN.md), [FEATURES.md](FEATURES.md), then the source skill. Older handoff is [archived](research/archive/session-continuation-before-intent-rebuild.md).

User authorized aggressive replacement with a complete spec and implementation, not preserving existing architecture. Spec and new orchestration are implemented; full release acceptance remains open. No new subagents used. Preserve name leap and user history; commit/push after each install.

## Latest installed correction — Mac bounds

[Iteration](iterations/2026-09-20-mac-bounds.md), [install identity](../artifacts/test-runs/20260920-mac-bounds/install.json). The restarted Sky-pointer candidate opened/captured Simulator successfully. Native double-click interaction0BB5B5EC-F161-4419-ABB2-728B74E68A87 failed BEFORE input: live Mac bounds are CGFloat arrays, and the final range guard cast them to [Double]. Earlier equality check passed. Shared numeric normalization now fixes both paths;11 model tests passed. Needs restart/native acceptance. Session5CC6C6B5-1A67-4185-867E-7FE30F83C174 closed; history retained. No app changes from this trial.

NEXT: open mac_ax Simulator window iPad Air11-inch(M2), capture fresh screenshot and snapshot, double-click field center using window_points scaled from capture, then capture and visually verify zoom. Do not use an AX-only verdict for canvas content. Reset, drag, compare canvas motion and stable window bounds. Background first, explicit foreground if needed. Previous Sky zoom/reset passed; sidebar scroll lacked confirmed movement. Gameday stays landscape, original5 of11 play.

Read [Sky native audit](research/sky-native-input-audit.md) and [pointer iteration](iterations/2026-09-20-sky-pointer.md) for current transport. It is process-directed synthesis plus AX, not AX-only. Hosted-process routing/full synthetic focus tracking remain gaps. No speculative WDA rotation or repeated failed WDA information taps. WDA is optional additional capability. No Blender gate pass yet.

Historical architecture and native details are retained in docs/iterations and the archived handoff. Source skills describe the current API. Preserve .leap history, registration name leap and the commit/push-after-install workflow.
