# Current handoff — intent rebuild

Updated 2026-09-20. Read [SPECIFICATION.md](SPECIFICATION.md), [PLAN.md](PLAN.md), [FEATURES.md](FEATURES.md), then the source skill. Older handoff is [archived](research/archive/session-continuation-before-intent-rebuild.md).

User authorized aggressive replacement with a complete spec and implementation, not preserving existing architecture. Spec and new orchestration are implemented; full release acceptance remains open. No new subagents used. Preserve name leap and user history; commit/push after each install.

## Latest orientation fix and backend decision

See [orientation iteration](iterations/2026-09-20-wda-orientation.md) and [install identity](../artifacts/test-runs/20260920-wda-hit-diagnostics/install.json). WDA protocol translation and exact rotation provenance corrected; install requires restart/native acceptance. Prior loaded binary6df9b406 had native Mac successes: information toggle interaction55CD79A1-DAC5-4B0E-9554-C7D6214BEAF1 and Previous play C35F72A5-4A26-4C4A-97C3-97C825EE8681. Sky semantic and coordinate toggles also passed. WDA Next play passed; information touch remains failed. App restored upright, field visible, original5 of11 play. Both live sessions closed; history remains.

NEXT: open WDA only to verify exact orientationIdentity/orientationStable on the installed build without rotation. Then open mac_ax Simulator/iPad session and pair Sky then Leap landscape filter scroll and field double-click/drag, using fresh screenshots when host AX geometry is invalid. The user challenged spending time on a different backend despite having Sky reference; prioritize behavioral parity through the same host accessibility route. WDA is optional additional capability, not a prerequisite. No repeat portrait or speculative orientation experiments. Scope-limited source inspection found no proven Gameday defect; no Gameday edits made.

## Previous candidate and initial action

Installed executable SHA256 `b727dc103a5c7c4011ce92091c6e31443f0450933838c1208afa48d238db5a6d`, server version0.2.0, intent contract2. [Install metadata](../artifacts/test-runs/20260920-rebuild/install.json). Signed release, synchronized skills. Old native MCP connection cannot expose the new tools until user restarts. Do not mark native pass from this delivery.

New preferred tools: target_list, session_open, session_close, ui_observe, ui_perform, session_history, evidence_read. Legacy tools remain for compatibility. Read skills/claude-leap/references/intent-workflows.md for exact syntax. Actions/assertions share selectors; full snapshots retained; failed/unknown steps stop dependent input; uncertainty never triggers replay.

After restart, start with session_open(project:/Users/ryan/src/claude-leap, app:local.gameday.ios, backend:wda, endpoint:http://127.0.0.1:8100). The pinned WDA runner was built/launched on iPad UDID C2CC7242-41E7-4EB3-BDA9-758D00DF5CDD. Health endpoint ready; no actual guest UI action tested via the new adapter. Opening may foreground/launch the guest app, with no data reset. Discover/observe before choosing the reversible information/field toggle; assert its new state, restore and query history.

Runner source commit1892efc71cc6e5bc8a20b083acc2753ea2288b62 (WebDriverAgent16.12.9). scripts/wda.py status <UDID> checks readiness. Local-only manifest/log/builds: artifacts/test-runs/wda/<UDID>/. On missing runner, inspect logs before starting a duplicate. iPhone UDID08385748-DE3D-45D0-A0DA-75F69B0191B5 is booted; separate runner/port still needs setup. No old app data erased.

## Evidence and gaps

Seven AutomationModel tests passed. Signed installed MCP protocol fixture passed failed-assertion stop, ambiguous-click single dispatch, retained changed state, skipped next input, historical snapshot and two-result history. [Results](../artifacts/test-runs/20260920-rebuild/contract-results.json) contain mock data, not native acceptance; referenced fixture files are ignored/local-only. WDA boot readiness is infrastructure evidence only.

Shared Mac input primitives and SQLite history were reused; orchestration/normalized result/query layer is new. Known gaps: globally unique WDA semantic re-resolution, limited guest keyboard/set-value, pre-armed transient expectations, hard cancellation of OS calls, asset file storage budgeting, native coordinate/focus coverage. No backend silently falls back. No Blender artifacts yet. Finish fixed R16 gate rather than widening platform scope.

Prior baseline: Sky/Leap screenshot-coordinate iPad toggles worked. Actual foreground did not fix invalid Mac AX rectangles. Public activate correction was installed previously but its direct native entrypoint still needs acceptance. Historical group E02D3027-C127-4760-A280-7E2FC74244C4 and old records remain intact.
