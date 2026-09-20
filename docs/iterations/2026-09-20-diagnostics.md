# 2026-09-20 — Durable MCP diagnostics and visible recovery

## Outcome and evidence

Ryan identified that hiding unreliable marker coordinates can obscure conditions useful for debugging. The source audit found a silently discarded interaction-summary error, asynchronous recording append/finish errors, and recovery paths without durable diagnostic events. Add an independent diagnostic journal rather than relying on the recording database that may itself fail. This increment does not resolve Simulator geometry; it preserves evidence for that investigation.

## Rationale and alternatives

A stderr-only log is host-dependent and awkward to query; the UI recorder alone cannot diagnose failures before binding or failures of its own store. Use a separate SQLite WAL journal with process IDs, timestamps, interaction/session correlation where known, severity, event kind, tool/app and bounded detail. No raw arguments or full UI trees; debug adds argument names without values. A separate store can still fail on the same full/unwritable disk: explicitly report this through stderr and tool responses, and refuse dispatch if an input-attempt record cannot be persisted. Never replay after a post-dispatch diagnostic failure. No automatic pruning/deletion introduced. The initial proposal embedded a development log path in the bundle; rejected by the user and removed before final installation. Configured severity may intentionally exclude lower-level events; response warnings disclose this and queries expose the effective level.

## Changes

- diagnostic_query filters interaction_id/session_id, severity (issues means warning/error), kind and sequence cursor. At most20 rows/12KB per page, details capped1200 characters. Error excerpts may contain application text; this is not a secure-input archive or complete trace of every optional AX attribute lookup.
- All dispatched tools record start/completion; actions record attempts/API returns separately from expected-state checks. Diagnostic references and up to three warning excerpts accompany responses. Late warnings are queried separately from info events so a long action cannot hide them behind the first20 normal events.
- Replaced summary try? with a recorded warning and explicit original-response fallback. Observer append/gap/finish failures and snapshot recording failures use the independent journal. Capture-quality warnings record blocking/advisory/deadline/truncation/retained-earlier status with snapshot detail remaining in evidence queries.
- Instrumented marker suppression with element/window geometry; AX-to-pointer/reveal, activation, keyboard/text/value and wheel routes disclose alternate transport. Screenshot failures and post-error observation failure are logged. Returned API acknowledgement remains distinct from app effect.
- Diagnostics work before bind_project. Following Ryan's explicit correction, configuration is ~/.config/leap/leap.json and logs are ~/.leap/logs/diagnostics.db. logging.level supports debug/info/warning/error (default info). Installer creates defaults only if missing; existing configuration is preserved. Invalid configuration blocks dispatch with an explicit error rather than silently selecting defaults. Warnings excluded by the log level remain visible in tool responses and say they were not retained. User explicitly requested these global paths, superseding the campaign repo-only runtime-artifact rule for diagnostics. Tests/fixtures/reports remain repo-local. No embedded repo path or cwd-based project inference. Configuration is loaded once at process startup; restart after changes.

## Validation and delivery

Five initial focused tests passed (DiagnosticsTests, IndicatorGeometryTests, RecordingGroupTests). New tests verify persistence after reopening, filtering/pagination, a warning after25 info events, and explicit write failure when a file blocks the diagnostic directory. First compile exposed immutable MCP result content; corrected by constructing a new result preserving isError. Build/signing/install identity retained in artifacts/test-runs/20260920-diagnostics/install.json; logs/fixtures local-only. Source skill documents diagnostic queries and limits; skills-only sync and installed comparisons required. No native MCP pass claimed before restart.

## Remaining work

After restart use diagnostic_query before binding, resume group E02D3027-C127-4760-A280-7E2FC74244C4 and observe iPad. Repeat/restored information toggle and query that interaction: expect capture-quality, marker-suppression geometry, API-return and expectation-after evidence, without a pointer dispatch. Verify an invalid read-only request produces a durable error and warning reference. Check group continuity across restart. Then investigate rotated Simulator geometry using reference/paired observation; suppression is containment only. Broad low-level optional AX capability probes remain represented by capture metadata rather than a log row per probe. Logs have no retention quota yet; no pruning silently discards events. Async errors outside a call are queryable by session/kind and stderr fallback rather than retroactively appended to a completed tool response.

Configuration validation adds coverage for error-only logging, visible but unretained warnings, conventional paths and malformed-config refusal. Three DiagnosticsTests pass after this correction.

## Installed checkpoint

SHA-256 `b3c359b5c8d86319897ef0b1b5cc285d3b18947a0e1df592629cb45910be779f`; [install metadata](../../artifacts/test-runs/20260920-diagnostics/install.json). Signed release verified. Config defaults created/preserved without overwriting settings. Both installed skill copies equal source. No native diagnostics pass yet; restart required.
