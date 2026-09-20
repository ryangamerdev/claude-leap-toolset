# Session continuation — current handoff

Updated 2026-09-20. Workspace: `/Users/ryan/src/claude-leap`.

Read [PLAN.md](PLAN.md) for execution order, [FEATURES.md](FEATURES.md) for status, and [observation-session-design.md](research/observation-session-design.md) for architecture. Older handoff archived under [research/archive](research/archive/session-continuation-before-20260920-review.md); its paths, process IDs, assertions and instructions are superseded.

## Current objective

Sky-or-better native app operation, demonstrated with Gameday, iPhone/iPad Simulator and separate paired Blender basic-shape Mickey-head artifacts. Immediate direction: durable session/event capture plus accurate action outcomes, then complete the remaining app campaign. `leap-cli` deferred. Preserve the same user-level operations for Sky then Leap; scripts must not bypass the UI modeling benchmark.

## Resume checkpoint

- Installed interaction timeline/delta candidate SHA-256 `beb4b0b373f57b352c08f9cca50df423d35178c26853bbba28749239eb317e73`. Release/signature and five EvidenceTests passed. Skills synchronized. [Install identity](../artifacts/test-runs/20260920-interaction-deltas/install.json). User restart required for new tools.
- Native field-quality acceptance passed: two iPad failures are AXCheckBox subrole metadata, advisory=2/blocking=0. Both verified information/field toggles settled and met postconditions; iPhone clean. [Results](iterations/2026-09-20-interaction-deltas.md). No need to repeat the earlier read-retry investigation.
- NEXT after restart: bind_project(repository). interaction_timeline(session_id:03CD56CA-9730-4122-803D-FC4BB36DE8C4,limit:2), paginate with fixed through. interaction_delta for 2ED5EA8E-0C89-4A74-92F8-932D6B328A7C and E0224AF5-A319-4CB9-B591-3B1B48DC4B03 must select pre-input and post-input snapshots, not precheck baseline. Then a reversible iPad view toggle must return compact joined outcome/observation delta; restore field view.
- New tools: interaction_timeline, interaction_delta; ui_diff now includes shortened beforeValues/afterValues. Successful recorded single inputs with default then_state use summary/delta; errors, batches, unrecorded and explicit then_state:false preserve prior paths. Delta missing/incompatible evidence is unavailable, no replay. Full captured controls remain in ui_to_text. Native acceptance pending.
- iPad remains on field view; iPhone Phone parity read last. Recorder 03CD56CA-9730-4122-803D-FC4BB36DE8C4 stopped cleanly. No play data changed.
- Retained-earlier timeout handling still needs controlled native coverage. Temporal predicates and broader Simulator/Blender trials remain. No Blender artifacts yet. Continue campaign after this focused query/response verification.
- Every build/install refreshes source/installed skills, logs rationale and commits/pushes. Use TOOLCHAINS=org.swift.640202609131a for supporting tests; default Xcode compiler cannot build current MCP dependency.

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
