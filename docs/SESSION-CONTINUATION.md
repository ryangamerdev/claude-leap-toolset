# Session continuation — current handoff

Updated 2026-09-20. Workspace: `/Users/ryan/src/claude-leap`.

Read [PLAN.md](PLAN.md) for execution order, [FEATURES.md](FEATURES.md) for status, and [observation-session-design.md](research/observation-session-design.md) for architecture. Older handoff archived under [research/archive](research/archive/session-continuation-before-20260920-review.md); its paths, process IDs, assertions and instructions are superseded.

## Current objective

Sky-or-better native app operation, demonstrated with Gameday, iPhone/iPad Simulator and separate paired Blender basic-shape Mickey-head artifacts. Immediate direction: durable session/event capture plus accurate action outcomes, then complete the remaining app campaign. `leap-cli` deferred. Preserve the same user-level operations for Sky then Leap; scripts must not bypass the UI modeling benchmark.

## Resume checkpoint

- Installed field-quality candidate SHA-256 `a0ec8c9ead9dbd0315f9e212c3504a335127604745be9143a119586e101b2678`. Release/signature passed; two ObservationQualityTests passed using TOOLCHAINS=org.swift.640202609131a. Default Xcode toolchain failed in an SDK dependency; use the configured toolchain. [Install metadata](../artifacts/test-runs/20260920-field-quality/install.json). Native verification requires restart.
- NEXT after restart: bind_project(repository), ui_to_text(app:Simulator,window:"iPad Air 11-inch (M2)",contains:"Playbook"). Inspect failure roles/impact and advisory/blocking counts. Only generic AXSubrole failure on known non-text controls is advisory; other failures remain blocking. Do not expand classification merely to pass.
- Repeat verified_action Show play information → expect Show field, then reverse → expect Show play information. Check settling, partial flags and retainedEarlierObservation. An earlier retained capture is explicitly not latest state. Check iPhone identity/clean read afterwards. [Rationale](iterations/2026-09-20-field-quality.md).
- Sky and Leap both already performed the iPad view clicks successfully; missing metadata/readiness was the demonstrated gap. iPad was restored to field view; no play data changed. Recorder was stopped. Earlier Gameday first-attach, diff, subtree/pagination and reversible-action passes remain valid for their scoped builds.
- Next implementation after native quality acceptance: DATA-20 automatic action-scoped deltas and DATA-21 timestamped interaction timeline; then Simulator/Blender acceptance. Neither feature is yet fully implemented. No Blender artifacts exist.
- Each build/install includes source skill updates, skills-only sync, iteration rationale and commit/push. Both installed skill copies match this candidate's source. Do not repeat prior campaigns wholesale.

## Working constraints

- Keep registration `leap`, installed bundle `~/Applications/claude-leap.app`; no rename workaround.
- Fix/build/install promptly and request restart for native validation. A build is not a live pass. Announce before foreground activation; authorized when needed for comparison/recovery.
- Keep visible pointer/ripple. Background/foreground pointer delivery shares process/window targeting; keyboard fallback can differ. Sky does synthesize targeted input: old absence-of-import inference was wrong; dynamically resolved APIs exist in the extracted reference.
- Source reference: `/Users/ryan/src/sky`; Runner and Tracer references: `/Users/ryan/src/runner-mcp`, `/Users/ryan/src/tracer-mcp`. External reference projects are read-only unless separately authorized.
- All scripts, fixtures, logs, screenshots, backups and outputs stay in this repo. Opt-in automatic records in `.leap/`; curated exports in `artifacts/test-runs/`; existing `Tests/` capitalization. Never revive `/tmp/astra` workflows from the historical handoff.
- Commit/push after build/install is now explicitly authorized; follow AGENTS.md. Preserve unrelated working-tree changes. No currently active delegated review work remains after the recorded peer review.
- Native tools are the acceptance path. `scripts/mcp-call.py` can diagnose the installed binary through stdio; label harness evidence separately. Build with `scripts/bundle.py`, retain logs, stage and atomically replace installed app with a repo-local rollback bundle.

## Evidence to retain

[Scroll](research/trial-scroll-details.md), [navigation](research/trial-navigation-details.md), [editor incident](research/trial-editor-details.md), [field](research/trial-field-details.md), [coach baseline](research/trial-sky-details.md), [Leap replay](research/trial-leap.details.md). The full historical pass is not a substitute for the specific changed-route or ambiguous-error tests still pending.

Latest paired iPad result: Sky and Leap both toggled information/field successfully; Sky independently verified Leap restored the field. Leap global read-failure gating and sparse final-deadline observations remain the gap, not demonstrated input failure. Next correction should use attribute/predicate-specific coverage and preserve usable timed observations. [Evidence and rationale](iterations/2026-09-20-sky-subrole.md).
