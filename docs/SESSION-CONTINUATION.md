# Session continuation — current handoff

Updated 2026-09-20. Workspace: `/Users/ryan/src/claude-leap`.

Read [PLAN.md](PLAN.md) for execution order, [FEATURES.md](FEATURES.md) for status, and [observation-session-design.md](research/observation-session-design.md) for architecture. Older handoff archived under [research/archive](research/archive/session-continuation-before-20260920-review.md); its paths, process IDs, assertions and instructions are superseded.

## Current objective

Sky-or-better native app operation, demonstrated with Gameday, iPhone/iPad Simulator and separate paired Blender basic-shape Mickey-head artifacts. Immediate direction: durable session/event capture plus accurate action outcomes, then complete the remaining app campaign. `leap-cli` deferred. Preserve the same user-level operations for Sky then Leap; scripts must not bypass the UI modeling benchmark.

## Resume checkpoint

- Installed build remains `444130a908e54dff63cb2a618a60bde37c75121fc33713da4334e98ecf8521db`. Native tools now loaded and tested. No binary changes this iteration.
- Native retention/migration passed: all previous 589 records unchanged, schema2, integrity ok. Historical delta brackets563/572 and575/582 correct; fixed-through timeline pagination passed.
- Both background iPad toggles returned one input, met postcheck and automatic deltas608/617 and620/627. Field restored. iPhone629 and Gameday664 clean. Two advisory iPad subrole warnings remain, zero blocking failures. No play edits.
- Group `E02D3027-C127-4760-A280-7E2FC74244C4` (Simulator grouped timeline and delta acceptance) spans captures E06BFE93-9927-4CD7-A3D5-0F0FA666ECEC, 5A361A0B-D335-468F-B813-0CAB3455B19F and CCCEB510-006B-4398-997F-E0438116D368. Group end/resume within same process passed. Last Simulator capture stopped cleanly; group retained.
- NEXT after requested restart: bind_project, recording_group(action:resume,group_id above), get_app_state(Simulator,window:iPad), recording_sessions/group timeline must show new capture alongside old six interactions. This verifies actual cross-process continuity; do not repeat in-process tests instead.
- Delta noise remains: AX ordinal/key churn yields false added/removed matches; repeated before/after quality metadata is verbose. Do not claim measured token savings. Preserve diagnostics and avoid ambiguous label matching when improving it.
- Then continue Simulator/paired Blender; no Blender artifacts yet. Retained-earlier timeout and temporal checks still need controlled acceptance.
- [Native evidence and rationale](iterations/2026-09-20-group-native.md). Skills refreshed; commit/push before handoff. Restart requested for continuity test, not a new binary.

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
