# Current handoff — intent rebuild

Updated 2026-09-20. Read [SPECIFICATION.md](SPECIFICATION.md), [PLAN.md](PLAN.md), [FEATURES.md](FEATURES.md), then the source skill. Older handoff is [archived](research/archive/session-continuation-before-intent-rebuild.md).

User authorized aggressive replacement with a complete spec and implementation, not preserving existing architecture. Spec and new orchestration are implemented; full release acceptance remains open. No new subagents used. Preserve name leap and user history; commit/push after each install.

## Latest Sky-derived pointer candidate

Read [native reference audit](research/sky-native-input-audit.md) and [iteration](iterations/2026-09-20-sky-pointer.md). [Install identity](../artifacts/test-runs/20260920-sky-pointer/install.json). Changes: target-window activation metadata, no raw-pointer fallback or silent allocation failure, prebuilt click/drag, coordinate scroll via Mac intent API. Requires restart; native session_open returned Transport closed before this install.

NEXT: open explicit mac_ax Simulator session, iPad Air11-inch(M2); fresh capture supplies image scale and snapshot. Repeat Sky's successful field double-click zoom and reset through Leap, then drag; inspect screenshot for field motion and window stability. If background fails, explicitly foreground and compare. Sky sidebar wheel and drag showed no confirmed movement this trial, so they are not a successful baseline. Gameday is upright/landscape, original5 of11 play, default field view. No active Leap sessions known. Do not use stale screenshot coordinates after window changes.

The audit index's AX-only/no-synthesis claim is incorrect: native factories synthesize mouse/scroll events and post to PID. Source has distinct same-process and hosted-process targets, per-target flipping and focus state tracking. This increment does not implement all of those branches; record remaining defects from native evidence. Do not return to repeated WDA taps or rotate Gameday to diagnose Mac input.

## Previous candidate and initial action

Installed executable SHA256 `b727dc103a5c7c4011ce92091c6e31443f0450933838c1208afa48d238db5a6d`, server version0.2.0, intent contract2. [Install metadata](../artifacts/test-runs/20260920-rebuild/install.json). Signed release, synchronized skills. Old native MCP connection cannot expose the new tools until user restarts. Do not mark native pass from this delivery.

New preferred tools: target_list, session_open, session_close, ui_observe, ui_perform, session_history, evidence_read. Legacy tools remain for compatibility. Read skills/claude-leap/references/intent-workflows.md for exact syntax. Actions/assertions share selectors; full snapshots retained; failed/unknown steps stop dependent input; uncertainty never triggers replay.

After restart, start with session_open(project:/Users/ryan/src/claude-leap, app:local.gameday.ios, backend:wda, endpoint:http://127.0.0.1:8100). The pinned WDA runner was built/launched on iPad UDID C2CC7242-41E7-4EB3-BDA9-758D00DF5CDD. Health endpoint ready; no actual guest UI action tested via the new adapter. Opening may foreground/launch the guest app, with no data reset. Discover/observe before choosing the reversible information/field toggle; assert its new state, restore and query history.

Runner source commit1892efc71cc6e5bc8a20b083acc2753ea2288b62 (WebDriverAgent16.12.9). scripts/wda.py status <UDID> checks readiness. Local-only manifest/log/builds: artifacts/test-runs/wda/<UDID>/. On missing runner, inspect logs before starting a duplicate. iPhone UDID08385748-DE3D-45D0-A0DA-75F69B0191B5 is booted; separate runner/port still needs setup. No old app data erased.

## Evidence and gaps

Seven AutomationModel tests passed. Signed installed MCP protocol fixture passed failed-assertion stop, ambiguous-click single dispatch, retained changed state, skipped next input, historical snapshot and two-result history. [Results](../artifacts/test-runs/20260920-rebuild/contract-results.json) contain mock data, not native acceptance; referenced fixture files are ignored/local-only. WDA boot readiness is infrastructure evidence only.

Shared Mac input primitives and SQLite history were reused; orchestration/normalized result/query layer is new. Known gaps: globally unique WDA semantic re-resolution, limited guest keyboard/set-value, pre-armed transient expectations, hard cancellation of OS calls, asset file storage budgeting, native coordinate/focus coverage. No backend silently falls back. No Blender artifacts yet. Finish fixed R16 gate rather than widening platform scope.

Prior baseline: Sky/Leap screenshot-coordinate iPad toggles worked. Actual foreground did not fix invalid Mac AX rectangles. Public activate correction was installed previously but its direct native entrypoint still needs acceptance. Historical group E02D3027-C127-4760-A280-7E2FC74244C4 and old records remain intact.
