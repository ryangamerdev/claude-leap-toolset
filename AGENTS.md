# Leap development workflow

The objective is native app operation at least as effective as Sky, with reliable actions,
compact observations and evidence retrieval. Read docs/PLAN.md, docs/FEATURES.md and
docs/SESSION-CONTINUATION.md before resuming the acceptance campaign.

## Required iteration history

For every implementation/test/install iteration, add a dated entry under docs/iterations/
and update its README index. Record this before handing the task back or committing:

- User outcome and observed problem; separate evidence from hypotheses.
- Root cause or uncertainty, alternatives considered, and why the chosen change fits.
- Concrete implementation and agent-facing behavior; compatibility and tradeoffs.
- Validation commands, results, native versus harness evidence, and retained references.
- Build/install identity when applicable; whether the loaded MCP was restarted and tested.
- Known limitations, regressions, unresolved questions, and the exact next acceptance case.

Use docs/iterations/TEMPLATE.md. Do not invent missing history or call a build a native pass.
Correct later conclusions with a new entry or clearly dated addendum; preserve earlier findings.
Keep FEATURES, PLAN and the continuation handoff consistent with the iteration entry.

## Artifacts and delivery

Keep all scripts, tests, outputs and rollback bundles in this repository's directory tree.
Commit source, reusable tests, reports, curated evidence and small install/result metadata.
Keep runtime .leap stores, generated fixture repos, databases, caches, build logs, downloads
and app bundles ignored and local. A reference to an ignored artifact must say it is local;
retain a tracked summary so the rationale is available from a fresh clone.

Preserve registration name leap. Build/install meaningful increments, then ask for a session
restart and use native MCP calls for acceptance. Supplement with focused regression tests;
do not substitute harness results for the paired Gameday/Simulator/Blender trials. No commit
or push is implied for future tasks unless the user authorizes it.
