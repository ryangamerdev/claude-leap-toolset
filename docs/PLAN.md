# Execution plan and current checkpoint

Updated 2026-09-20 with the first recording implementation. This file owns execution order; [FEATURES.md](FEATURES.md) owns acceptance statuses; [SESSION-CONTINUATION.md](SESSION-CONTINUATION.md) owns the concise handoff; [design](research/observation-session-design.md) owns proposed architecture. Trial reports are chronological evidence, not instructions to repeat superseded work.

## Objective and boundaries

Demonstrate practical Sky-or-better native app operation through Gameday, its iPhone/iPad Simulator variants, and paired editable Blender Mickey-head artifacts. Sky first, equivalent state, Leap second; fix → build/install → user restart → focused native verification. Preserve user work and the visible pointer overlay. Never rename `leap`. No blanket certification from a successful API response or a single app.

Durable recording is an immediate foundation: preserve received events and observations before they disappear, return compact results, and permit investigation without repeating input. Runner informs summaries/query cursors; Tracer informs project-local storage/provenance; macOS AX provides partial notification evidence. A database alone does not capture events. `leap-cli`, Unity gameplay, rigs, advanced sculpting and broader platform certification are deferred.

## Current state

- Gameday field/scroll/navigation, historical query pagination, ambiguous -25204 recovery and mirrored-route Save/reopen have scoped historical passes. Retained before/after checks passed native transitions. No broad feature is certified.
- The integrated candidate adds budgeted/quality-aware acquisition, structured UI queries, text assets, snapshot comparisons, joined interaction results and automatic recording after binding. [Exact scope and native acceptance](research/integrated-observation-layer.md).
- Latest install identity is in artifacts/test-runs/20260920-ax-batch-recovery/install.json after installation. Confirm user restart before native acceptance. Supporting code tests do not establish app behavior.
- Next: run the integrated acceptance cases after restart; fix concrete failures together where they share a cause. Then finish bounded Gameday work, exercise iPhone/iPad Simulator and prioritize paired Blender construction.
- Temporal expectations, controlled blocked/delayed observation coverage, durable window identity, binary evidence ingestion and compound workflows remain incomplete. leap-cli stays deferred.

## Immediate increments

| Checkpoint | Status | Scope and exit evidence |
|---|---|---|
| REC-00 | TESTED | Scoped -25204 native recovery passed (see recording-save-native-trial.md).  Existing AXPress guard: after a confirmed restart, verify normal semantic clicks and Save recovery. An ambiguous response must preserve sent/uncertain status and send no fallback click. If not naturally reproduced, use controlled fault injection; do not claim the branch passed from an ordinary successful Save. |
| REC-01 | PARTIAL | First slice: explicit recording_start, journal and dedicated observer implemented; native validation and remaining contract work follow. Full target:  Project-bound SQLite journal plus observer lifecycle and typed dispatch records together. Automatic attach, session/interaction/action IDs, intent committed before dispatch, initial/before/after observations, supported AX subscriptions, separate observer delivery while calls block, explicit capture gaps. Query stored events by interaction without replay. No TUI/daemon/general query language required. |
| REC-02 | PARTIAL | Historical queries/current-state action checks implemented; temporal predicates and projections remain. Full target:  Compact outcomes and bounded history/snapshot queries. Preserve original errors and fresh post-error evidence, external diff baselines, provenance, source coverage and response omissions. Arm temporal predicates before dispatch and distinguish already-true/current/ever-observed/unknown. |
| REC-03 | PENDING | Install and validate the foundation using a controlled transient-event fixture and Gameday Save. Demonstrate retained evidence after a transient UI state is gone, native tool retrieval, failure-aware results and no duplicate dispatch. Export reproducible evidence into this repo. |

REC-00 is a focused verification of the already-installed fix, not a reason to postpone REC-01 planning/implementation. A newer foundation build may include and verify that guard in the same restart checkpoint. Do not repeatedly request restarts without a new installation or a concrete stale-connection condition.

After REC-03: finish CAM-03 changed-route/notes/save/reopen, then CAM-04–07 Simulator, then CAM-08–11 paired Blender construction/save/reopen and CAM-12 repeatability. Build only the capture/query/verification surface needed by these tests; do not defer Blender until every inventory feature is certified.

## Foundation acceptance cases

1. **Storage ownership:** explicit project binding, normal Git repo, linked worktree and non-Git directory. Unrelated MCP cwd cannot silently become the project. Exclusion is idempotent and effective; tracked `.gitignore` stays unchanged. Historical reads on a missing store create nothing.
2. **Continuity:** session history survives restart, old AX handles cannot act, and the unobserved interval is visible. Concurrent initialization/writers preserve ordering and evidence; incompatible schemas are refused without destructive migration.
3. **Capture:** repo-local fixture emits a transient notification while an action blocks. Later query retrieves the received envelope without replay. Attribute reads made later retain their own timestamps and are not mislabeled as the event's original payload. Unsupported subscriptions and recording gaps remain visible.
4. **Loss accounting:** queue overflow, pruning, capture limits, virtualized/unsupported nodes and response truncation are separately represented. A bounded response still points to retained evidence; an uncaptured value cannot be retrieved and is never fabricated.
5. **Storage failure:** if the intent cannot be committed, refuse dispatch in recording mode. If storage fails after dispatch, retain sent/uncertain semantics, stop further workflow dispatch and report capture failure—never say nothing happened or silently retry. No implicit degraded recording mode.
6. **Verification:** ordinary success, ambiguous reply with completed effect, unmet expectation, already-true condition, lost observation, duplicate selectors and delayed update. Unknown checks stop dependent workflow steps. Transient-event checks and current-state checks are distinct.
7. **Context cost:** compare returned text bytes, image attachments, call count and latency on the same cases. A smaller response must not hide warnings or change correctness. No estimated token savings presented as measured results.

## Storage and testing rules

Future raw recordings: `<project>/.leap/leap.db` and `.leap/sessions/<id>/`, automatically locally excluded via Git. For this campaign, project root is `/Users/ryan/src/claude-leap`. Curated exports: `artifacts/test-runs/`; scenarios: `Tests/`; tools/fixtures: `scripts/`; reports: `docs/research/`; Blender assets: `artifacts/blender/mickey-head/`. No scratch evidence outside the repository. Do not move/delete prior evidence merely to conform to the new layout.

Honor the user's short install cycle: focused build checks, install, then meaningful native verification after restart. Controlled fixture tests are necessary for ambiguous/loss paths that cannot be reliably induced through Gameday; they supplement rather than replace actual app testing. Keep detailed build and test logs, surface exit status and failures, and query retained evidence for detail.

## Insights increment

Runner/Tracer-inspired review and tree outline are implemented. After the next restart validate recording_review against retained session A16C3242-997E-4E00-946D-F07E234DF73F and the prior uncertain Save interaction, including frozen grouped pagination. [Scope, evidence and remaining work](research/insights-layer.md). Treat Leap as the layer that performs actions and supplies relevant outcomes; keep storage mechanics internal. Do not declare the recorder complete while strict AX deadlines and controlled transient capture remain open.

## Readiness correction

[Timing/readiness review](research/timing-and-readiness-review.md) identifies inconsistent normal-state versus expectation waits, synchronous deadline overrun and missing acquisition-failure metadata. Next implementation should unify readiness, enforce remaining acquisition budget where possible, and treat incomplete absence as unknown. Fixed sleeps or maximum poll counts alone do not solve the observed Save case. Preserve one input dispatch and retry observations only.

Current acceptance order is the integrated checklist linked above; older increment descriptions retain historical context and do not require repeating already-passed cases wholesale.

Current restart check: first bound app observation must attach automatically, then compare historical snapshots 370/380 (34 changes, no frame changes). See [integrated native trial](research/integrated-native-trial.md). Several integrated functions now have scoped native passes; do not restart their implementation.

2026-09-20 update: first-bound-app observation, corrected historical diff, subtree/button pagination and grouped event pagination passed. CAM-04 read-only discovery passed for both controllers. Next restart case is the repeated iPad read failure: inspect bounded failure details before attempting absence-based expectations. See [iteration rationale](iterations/2026-09-20-postrestart.md).

User direction: DATA-20 makes the ordinary action result an interaction-scoped delta, with unchanged controls omitted and full retained snapshots available on demand. Reuse ui_diff and existing pre/post recording, but make baseline identity and incomplete observations explicit; current rendered diffs alone do not fulfill this entire contract.

Current next native case: iPad generic per-field AXSubrole failure recovery, using retry/recovery counts and error details. After acquisition is understood, integrate DATA-20 action deltas and DATA-21 timestamped interaction discovery using existing retained snapshots, before continuing Simulator and Blender acceptance.

Delivery requirement: maintain source skills with behavior changes and refresh Claude/Codex copies using `python3 scripts/install.py --skills-only` during development installs. Keep detailed usage conditional and native acceptance status separate.

Current 2026-09-20 result: individual retries did not resolve the two iPad AXSubrole failures. Investigate affected roles/keys and attribute-specific completeness before further retry changes. User now authorizes/requires commit and push after every build/install iteration; no new restart is needed for the Git checkpoint alone.

Latest paired iPad result: Sky and Leap both toggled information/field successfully; Sky independently verified Leap restored the field. Leap global read-failure gating and sparse final-deadline observations remain the gap, not demonstrated input failure. Next correction should use attribute/predicate-specific coverage and preserve usable timed observations. [Evidence and rationale](iterations/2026-09-20-sky-subrole.md).

Current candidate: [field-specific quality](iterations/2026-09-20-field-quality.md) adds conservative advisory subrole errors on known non-text controls, blocking coverage checks and explicitly retained earlier observations. IMPLEMENTED, native verification pending; broader predicate-specific dependencies remain incomplete. Next restart test is the same paired iPad transition, then DATA-20/21.

Current update: [interaction timeline/deltas](iterations/2026-09-20-interaction-deltas.md). Field-quality native iPad toggles passed with two checkbox metadata warnings and zero blocking errors; iPhone clean. DATA-20/21 now have implemented timeline/delta tools and automatic successful single-action summaries; native acceptance pending. Error/batch responses retain existing behavior.

Retention audit: older records remain intact; no reset fix is indicated. Track DATA-22 logical campaign grouping and storage discoverability separately from per-app recording sessions. Check empty-interaction filtering during timeline acceptance. [Audit](iterations/2026-09-20-storage-audit.md).

Latest increment: DATA-22 grouping/discovery implemented with additive schema migration; empty-interaction timeline filtering fixed. Native acceptance after restart: inspect retained inventory, create a named Simulator task, exercise grouped app captures and automatic deltas, then verify explicit group resume across a later restart. [Rationale](iterations/2026-09-20-logical-sessions.md).

Latest native checkpoint: [grouped evidence acceptance](iterations/2026-09-20-group-native.md). DATA-20/21 scoped native tests passed; DATA-22 same-process grouping and discovery passed, cross-process resume remains pending. Next restart resumes group E02D3027-C127-4760-A280-7E2FC74244C4. Delta verbosity/key churn remains an open quality gap; no token savings claimed.

Indicator correction: invalid/offscreen/out-of-window semantic-action coordinates now suppress the visual marker while retaining AX dispatch. IMPLEMENTED; two geometry tests passed, native placement/valid-marker checks pending restart. This does not solve Simulator coordinate transforms. [Rationale](iterations/2026-09-20-indicator-geometry.md).
