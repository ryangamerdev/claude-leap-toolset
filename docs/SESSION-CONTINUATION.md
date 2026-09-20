# Session continuation — current handoff

Updated 2026-09-20. Workspace: `/Users/ryan/src/claude-leap`.

Read [PLAN.md](PLAN.md) for execution order, [FEATURES.md](FEATURES.md) for status, and [observation-session-design.md](research/observation-session-design.md) for architecture. Older handoff archived under [research/archive](research/archive/session-continuation-before-20260920-review.md); its paths, process IDs, assertions and instructions are superseded.

## Current objective

Sky-or-better native app operation, demonstrated with Gameday, iPhone/iPad Simulator and separate paired Blender basic-shape Mickey-head artifacts. Immediate direction: durable session/event capture plus accurate action outcomes, then complete the remaining app campaign. `leap-cli` deferred. Preserve the same user-level operations for Sky then Leap; scripts must not bypass the UI modeling benchmark.

## Resume checkpoint

- User requested commit/push of accumulated work on 2026-09-20. See [iteration baseline](iterations/2026-09-20-baseline.md); future iterations must follow [AGENTS.md](../AGENTS.md) and record rationale before handoff. This repository checkpoint does not add native acceptance passes.

- Installed correction build SHA-256 `42b0158bde583a211f1c6e7cf9334a1e5bb58bf8dcc58f51592fa5713f87658d`. [Install identity](../artifacts/test-runs/20260920-integrated-fixes/install.json). Build/signature and four EvidenceTests passed; user confirmed restart; native correction verification is still pending.
- [Native integrated trial](research/integrated-native-trial.md): filtered Gameday query, background verified transitions, joined results, immutable history, fixture raw-text/file assets and review overview passed scoped cases. First new-app auto-attach failed and ui_diff falsely reported identical arrays as changed; both corrected in installed candidate.
- FIRST after restart: bind_project(/Users/ryan/src/claude-leap), then ui_to_text(app:Gameday,types:[button],fields:[index,key,label,selected,screenFrame]). Must succeed on first attempt. Then ui_diff(before:370,after_snapshot:380,limit:100) should report 34 changes (23 added/11 removed) and zero bogus screenFrame changes. Inspect pagination too.
- Recorder DD5F7E9C-3E0E-4B51-8AF5-3489195B96DE stopped cleanly. Gameday restored to information view; no play data changed this turn. Trial player 1 retains Mirrored from earlier Save test. Reobserve before acting.
- Evidence under artifacts/test-runs/20260920-integrated-fixes (native-results.json, native-evidence.db, comparison-reference.json). Asset fixture used: artifacts/test-runs/20260920-integrated/fixtures/9877B20F-64AF-4273-BAEB-C3AC8C3ADE13, snapshot1 node2 value. Database backups and generated fixture paths are local-only ignored artifacts; tracked JSON/reports retain the summaries. Raw retrieval is native-tested; actual huge app-field acquisition still pending.
- Continue [integrated acceptance](research/integrated-observation-layer.md): subtree/depth filtering, grouped pagination, Save timing/partial observations, then Simulator and paired Blender. No Blender artifacts yet. Do not mistake scoped passes for full parity.
- Remaining limits: hard OS-call cancellation, temporal predicates, binary/image ingestion, durable window identity, compound workflows. Bind once per MCP process; ordinal is a query cursor, index is an action target; historical indices require freshness validation. JSON coordinates are screen-relative, actions window-relative.

## Working constraints

- Keep registration `leap`, installed bundle `~/Applications/claude-leap.app`; no rename workaround.
- Fix/build/install promptly and request restart for native validation. A build is not a live pass. Announce before foreground activation; authorized when needed for comparison/recovery.
- Keep visible pointer/ripple. Background/foreground pointer delivery shares process/window targeting; keyboard fallback can differ. Sky does synthesize targeted input: old absence-of-import inference was wrong; dynamically resolved APIs exist in the extracted reference.
- Source reference: `/Users/ryan/src/sky`; Runner and Tracer references: `/Users/ryan/src/runner-mcp`, `/Users/ryan/src/tracer-mcp`. External reference projects are read-only unless separately authorized.
- All scripts, fixtures, logs, screenshots, backups and outputs stay in this repo. Opt-in automatic records in `.leap/`; curated exports in `artifacts/test-runs/`; existing `Tests/` capitalization. Never revive `/tmp/astra` workflows from the historical handoff.
- Do not infer permission to commit/push from old handoff text. Preserve unrelated working-tree changes. No currently active delegated review work remains after the recorded peer review.
- Native tools are the acceptance path. `scripts/mcp-call.py` can diagnose the installed binary through stdio; label harness evidence separately. Build with `scripts/bundle.py`, retain logs, stage and atomically replace installed app with a repo-local rollback bundle.

## Evidence to retain

[Scroll](research/trial-scroll-details.md), [navigation](research/trial-navigation-details.md), [editor incident](research/trial-editor-details.md), [field](research/trial-field-details.md), [coach baseline](research/trial-sky-details.md), [Leap replay](research/trial-leap.details.md). The full historical pass is not a substitute for the specific changed-route or ambiguous-error tests still pending.
