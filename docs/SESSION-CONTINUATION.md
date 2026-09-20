# Session continuation — current handoff

Updated 2026-09-20. Workspace: `/Users/ryan/src/claude-leap`.

Read [PLAN.md](PLAN.md) for execution order, [FEATURES.md](FEATURES.md) for status, and [observation-session-design.md](research/observation-session-design.md) for architecture. Older handoff archived under [research/archive](research/archive/session-continuation-before-20260920-review.md); its paths, process IDs, assertions and instructions are superseded.

## Current objective

Sky-or-better native app operation, demonstrated with Gameday, iPhone/iPad Simulator and separate paired Blender basic-shape Mickey-head artifacts. Immediate direction: durable session/event capture plus accurate action outcomes, then complete the remaining app campaign. `leap-cli` deferred. Preserve the same user-level operations for Sky then Leap; scripts must not bypass the UI modeling benchmark.

## Latest research checkpoint

Read [native test stack review](research/native-test-stack-review.md) before choosing the Simulator fix. Evaluated seven proposals against code and primary sources. XCTest/WDA is a candidate device backend, not implemented or proven. Add explicit target/coordinate provenance and typed outcomes; preserve Mac AX backend and no-replay protection. Current request was evaluation only. No binary changed; prior activation install still awaits restart/native acceptance. Older “no restart needed” text below belongs to earlier checkpoints.

## Resume checkpoint

Newest candidate: public activate verification correction, identity artifacts/test-runs/20260920-activation/install.json. User prompted actual foreground test: old activate falsely said success, state background. press_key(Escape,foreground:true) used verified path; state frontmost, but button still relative418,969 outside1006x780. Geometry NOT fixed by foreground. Public activate now reuses that verified routine and logs activation_verified. After restart verify public activate from background (Simulator currently foreground). [Iteration](iterations/2026-09-20-activation.md).

- Installed b3c359b5c8d86319897ef0b1b5cc285d3b18947a0e1df592629cb45910be779f has now passed scoped native diagnostics: before binding, invalid read-only query retained errors, per-interaction suppression/capture/check audit. Config ~/.config/leap/leap.json; logs ~/.leap/logs/diagnostics.db, info level. No new binary this iteration.
- Group E02D3027-C127-4760-A280-7E2FC74244C4 resumed across MCP restart successfully; new capture081006C4-A5E8-4823-855A-DC70B668B454 alongside prior3. Last capture stopped cleanly; recording_start required to resume Simulator in this connection, new connection automatic after binding.
- Two iPad AX toggles met postchecks with explicit marker suppression; restored field. Short precheck deadlines are unknown, not failure of input. Diagnostic interactions73F9C5CA-CE52-4683-9D8F-D2182AC6252C andE93484AD-7C09-4374-AA14-4DDF6B39AFB1.
- Sky rotation test: landscape window1006x780, button relative418,969; rotated-left window727x1059, button917,625; screenshot sideways. Right rotation restored original landscape field at(377,58). Final snapshot744. This supports coordinate-space mismatch but supplies no validated transform. AXTree.swift uses AXPosition/AXSize directly; reference strings do not prove a correction.
- NEXT investigate Simulator raw/batched coordinate values and orientation/source-space metadata before implementing a transform. Also fix generic read-only tool error wording (currently says input may have been sent), and reduce diagnostic repetition. No restart needed now. Then Simulator/Blender campaign; no Blender artifacts yet.
- [Native evidence](iterations/2026-09-20-diagnostics-native.md). Source/installed skills synced; commit/push documentation checkpoint.

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

Storage audit: 11 sessions/589 records/82 snapshots retained; four older backups have zero missing or changed records. Empty session folders are expected because payloads are in SQLite. No clearing performed. DATA-22 logical grouping remains planned. Check empty interaction IDs in timeline pagination. [Audit](iterations/2026-09-20-storage-audit.md).
