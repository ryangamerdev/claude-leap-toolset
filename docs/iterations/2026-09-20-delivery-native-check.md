# 2026-09-20 — Native recovery result and continuous Git delivery

## Outcome and evidence

The user confirmed a restart and explicitly required commit/push after each build/install
iteration. Tested installed build `2ff924fb96fddfe1451953c59b81af6ec808e195833a0ed2da8ce0df7832cdd3`
through native Leap tools: bind_project, iPad ui_to_text, iPhone ui_to_text, recording_stop.
[Retained native responses](../../artifacts/test-runs/20260920-ax-batch-recovery/native-after.json).

The iPad returned the intended Freshman 2026 playbook and 105 nodes, but the two individual
AXSubrole reads still failed with -25200. Counters show two retries and zero recoveries.
No deadline or node cap was reached. The iPhone returned Phone parity and 31 nodes without
failures or retries. Thus diagnostic reporting works; the fallback did not fix the iPad issue.
No UI input or play edits occurred. Recording stopped cleanly; raw SQLite data stays local-only.

## Rationale and alternatives

Commit the accumulated diagnostic, skill and acceptance work with its honest failure status.
Do not hide the generic failure or repeat the same build/restart with no causal change.
Next diagnosis must identify affected node roles and examine whether these are optional
metadata failures versus missing structure/state needed by a requested predicate. This may
justify more precise completeness semantics, but no such relaxation is implemented here.

The user has now authorized ongoing Git delivery, superseding the earlier per-task-only rule.
AGENTS.md and the current handoff record this explicitly so the instruction survives restarts.
Historical entries retain the authorization that applied when they were written.

## Changes

Record native failure evidence, correct the current handoff/checklist/plan, and require
commit/push of relevant work after each build/install. The checkpoint also includes the
previously installed bounded read diagnostics/retry, concise skill/reference, dual-host skill
synchronization, and the earlier scoped Gameday and Simulator discovery results. No new
binary changes are introduced during this acceptance/delivery iteration.

## Validation and delivery

Prior build/signature and installation results are retained in the batch-recovery install
metadata. This turn uses native acceptance rather than another protocol harness. Validate
staged whitespace, Python syntax, source/installed skill equality, and excluded-artifact scope
before committing. No new build or restart is needed for this checkpoint. Git delivery follows
the user's explicit instruction; no force-push or unrelated work is included.

## Remaining work

Resolve iPad acquisition semantics using retained error evidence, then integrate action-scoped
deltas and timestamped interaction discovery and continue Simulator/Blender comparisons.
The failed recovery candidate does not establish full Simulator or Sky parity.

Checkpoint checks passed: 24 staged files, no databases/logs/cache files or nested Git links, Python syntax valid, and both installed Leap skill copies match source. Trimmed a trailing blank line in the UI reference and resynchronized the skill/hash evidence. Staged whitespace validation passed.
