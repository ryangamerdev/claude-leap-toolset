# Current handoff — intent rebuild

Updated 2026-09-20. Read [SPECIFICATION.md](SPECIFICATION.md), [PLAN.md](PLAN.md), [FEATURES.md](FEATURES.md), then the source skill. Older handoff is [archived](research/archive/session-continuation-before-intent-rebuild.md).

User authorized aggressive replacement with a complete spec and implementation, not preserving existing architecture. Spec and new orchestration are implemented; full release acceptance remains open. No new subagents used. Preserve name leap and user history; commit/push after each install.

## Latest native trial and installed correction

Native WDA session A8A182F5-52D5-4388-950F-50018F4A252D is closed. Observation619 nodes and history/evidence retrieval passed. Information control frame1120,679,20,20 within1180×820 landscape matches screenshot. Two semantic taps produced no expected change, including after activate(Simulator) verified frontmost. Device-coordinate attempt was NOT sent: false bounds mismatch from String(describing:) comparison. Snapshots763/767 identical. Numeric equality fix now installed SHA2566df9b4060129ea9fb5f49758bc2114ef24f454e4582570436298514366f1d7a9; [iteration](iterations/2026-09-20-wda-native.md), [identity](../artifacts/test-runs/20260920-wda-native/install.json). Eight focused tests passed; native fix acceptance awaits restart.

NEXT after restart: open new WDA session, observe fresh information button and try one coordinate tap at its current center using current snapshot and device_points. Do not blindly repeat failed semantic tap. Then inspect effect and compare orientation if necessary. Guest input failure remains unresolved; do not call WDA superior yet. Old candidate details below are historical.

## Previous candidate and initial action

Installed executable SHA256 `b727dc103a5c7c4011ce92091c6e31443f0450933838c1208afa48d238db5a6d`, server version0.2.0, intent contract2. [Install metadata](../artifacts/test-runs/20260920-rebuild/install.json). Signed release, synchronized skills. Old native MCP connection cannot expose the new tools until user restarts. Do not mark native pass from this delivery.

New preferred tools: target_list, session_open, session_close, ui_observe, ui_perform, session_history, evidence_read. Legacy tools remain for compatibility. Read skills/claude-leap/references/intent-workflows.md for exact syntax. Actions/assertions share selectors; full snapshots retained; failed/unknown steps stop dependent input; uncertainty never triggers replay.

After restart, start with session_open(project:/Users/ryan/src/claude-leap, app:local.gameday.ios, backend:wda, endpoint:http://127.0.0.1:8100). The pinned WDA runner was built/launched on iPad UDID C2CC7242-41E7-4EB3-BDA9-758D00DF5CDD. Health endpoint ready; no actual guest UI action tested via the new adapter. Opening may foreground/launch the guest app, with no data reset. Discover/observe before choosing the reversible information/field toggle; assert its new state, restore and query history.

Runner source commit1892efc71cc6e5bc8a20b083acc2753ea2288b62 (WebDriverAgent16.12.9). scripts/wda.py status <UDID> checks readiness. Local-only manifest/log/builds: artifacts/test-runs/wda/<UDID>/. On missing runner, inspect logs before starting a duplicate. iPhone UDID08385748-DE3D-45D0-A0DA-75F69B0191B5 is booted; separate runner/port still needs setup. No old app data erased.

## Evidence and gaps

Seven AutomationModel tests passed. Signed installed MCP protocol fixture passed failed-assertion stop, ambiguous-click single dispatch, retained changed state, skipped next input, historical snapshot and two-result history. [Results](../artifacts/test-runs/20260920-rebuild/contract-results.json) contain mock data, not native acceptance; referenced fixture files are ignored/local-only. WDA boot readiness is infrastructure evidence only.

Shared Mac input primitives and SQLite history were reused; orchestration/normalized result/query layer is new. Known gaps: globally unique WDA semantic re-resolution, limited guest keyboard/set-value, pre-armed transient expectations, hard cancellation of OS calls, asset file storage budgeting, native coordinate/focus coverage. No backend silently falls back. No Blender artifacts yet. Finish fixed R16 gate rather than widening platform scope.

Prior baseline: Sky/Leap screenshot-coordinate iPad toggles worked. Actual foreground did not fix invalid Mac AX rectangles. Public activate correction was installed previously but its direct native entrypoint still needs acceptance. Historical group E02D3027-C127-4760-A280-7E2FC74244C4 and old records remain intact.
