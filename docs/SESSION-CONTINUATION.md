# Session continuation — current handoff

Updated 2026-09-20. Workspace: `/Users/ryan/src/claude-leap`.

Read [PLAN.md](PLAN.md) for execution order, [FEATURES.md](FEATURES.md) for status, and [observation-session-design.md](research/observation-session-design.md) for architecture. Older handoff archived under [research/archive](research/archive/session-continuation-before-20260920-review.md); its paths, process IDs, assertions and instructions are superseded.

## Current objective

Sky-or-better native app operation, demonstrated with Gameday, iPhone/iPad Simulator and separate paired Blender basic-shape Mickey-head artifacts. Immediate direction: durable session/event capture plus accurate action outcomes, then complete the remaining app campaign. `leap-cli` deferred. Preserve the same user-level operations for Sky then Leap; scripts must not bypass the UI modeling benchmark.

## Resume checkpoint

- Installed per-attribute batch-recovery candidate SHA-256 `2ff924fb96fddfe1451953c59b81af6ec808e195833a0ed2da8ce0df7832cdd3`. Release build and signing passed. [Install identity](../artifacts/test-runs/20260920-ax-batch-recovery/install.json). User restarted; native verification completed, but the iPad failure remains unresolved.
- [Latest iteration](iterations/2026-09-20-postrestart.md) records rationale and native evidence. Previous first-attach and false-frame-diff fixes passed. Subtree depths, 139-button pagination, 101-notification grouped pagination and reversible background transitions passed. Do not repeat these wholesale.
- NEXT: investigate failed AXSubrole reads by identifying the affected node roles/keys and separating optional metadata quality from required tree/expectation coverage. Do not simply suppress generic errors. Native snapshot 506 has 105 nodes, two individual retries, zero recoveries, and the same two AXSubrole -25200 failures; snapshot 508 identifies iPhone Phone parity with 31 nodes and zero failures/retries. [Native after evidence](../artifacts/test-runs/20260920-ax-batch-recovery/native-after.json). The retry hypothesis did not fix this provider behavior. No UI input was sent; recorder F8A8BA2C-6115-4106-B0FC-18199879BBA9 stopped cleanly.

- CAM-04 read-only discovery passed: Sky-backed cua_repl Window menu found iPad Air 11-inch (M2) – iOS 18.0 / Freshman 2026 and iPhone 16 – iOS 18.0 / Phone parity. Leap explicit windows match, and omitted-window read stays pinned to iPhone despite iPad being reference-selected. Screenshot, keyboard and gestures remain unverified. Leap and reference last returned to iPad.
- Gameday restored to information view, no play data changed. Recorders 5BB1B560-B14A-47D7-BEAB-4EBA02CFDF82 (Gameday) and 9CD75491-EF28-4FDD-A7D9-C5A8D2278BF0 (Simulator) stopped cleanly. A new process clears the stopped flag after binding. Reobserve before input.
- Latest user direction: action responses should return deduplicated before/after deltas. Ordinary text diffs already exist but use last rendered baseline; add action-scoped bounded structured changes with explicit before/after IDs, completeness, omissions and continuation. See DATA-20 and DATA-21 for the requested timestamped interaction timeline and snapshot references. Never mistake changed state for causality or duplicate an uncertain action.
- Continue controlled partial/delayed evidence, remaining Gameday route replacement and Simulator interactions, then prioritize paired Blender. No Blender artifacts yet. Native fixture text retrieval passed; huge real-app value acquisition remains pending.
- Follow AGENTS.md iteration history requirement. User now requires commit and push after every build/install iteration. Record scope and validation honestly, including failed candidates.

- Skill guidance was shortened and synchronized to Claude/Codex; details are now optional references. Run `python3 scripts/install.py --skills-only` after every development app install. See [skill iteration](iterations/2026-09-20-skill-sync.md). The batch-recovery restart and scoped native test completed; no extra restart is needed for this repository checkpoint.

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
