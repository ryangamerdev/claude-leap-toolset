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
do not substitute harness results for the paired Gameday/Simulator/Blender trials. After each build/install iteration, commit and push the relevant code, skills, documentation
and curated evidence before handing back for restart. The user explicitly authorized this
ongoing delivery workflow on 2026-09-20. Preserve unrelated changes and never force-push.

## Skill maintenance

When tool behavior, parameters or recommended usage change, update skills/claude-leap in the
same iteration. Keep SKILL.md concise; put conditional detail in linked references. Describe
installed capabilities separately from native acceptance and planned features. Source skills
are authoritative; do not edit only the installed copies.

Every development app installation must also run `python3 scripts/install.py --skills-only`.
This refreshes Claude and Codex skill copies without touching the app or MCP registration.
The standard installer does this automatically. Compare installed/source contents before
handoff; record skill changes and synchronization in the iteration history. A documentation-only
sync needs no binary rebuild; restart if the host cached skill discovery metadata.

## Investigation follow-through

When the user asks a question and investigation identifies a concrete, supported improvement
within Leap's objective, proceed to implement and deliver it under the build/install workflow;
do not stop at proposing the solution. Distinguish hypotheses from evidence and preserve the
native acceptance boundary. This standing preference was confirmed on 2026-09-20.

Continue the acceptance campaign across checkpoints without handing back until the objective is
complete or an installed build requires session restart. After the user confirms restart, resume
the next native case. Recorded at user request on 2026-09-20.

Gameday data in this acceptance campaign is test data. The user authorizes saving and changing
it freely; restoration to the original state is unnecessary. Repeat desktop and iPad play
creation/save/reopen before the remaining Blender gate (2026-09-20 steering).
