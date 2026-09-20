# Integrated observation and evidence layer — 2026-09-20

This increment implements the shared observation/query layer rather than another isolated primitive. Build, installation and native acceptance are distinct. The installed candidate must be tested after restart before any new live pass is claimed.

## Agent-facing workflow

1. `bind_project(project)` once per MCP process. Subsequent app observations/actions automatically attach a recorder. Existing recording_start/stop remain; stop suppresses automatic recording for that app until explicitly resumed.
2. Use ordinary action tools or `verified_action` for one input with a declared current-state check. Read the compact result; never replay an ambiguous acknowledgement. Recorded verified_action responses now include a joined interaction result.
3. `ui_to_text(app)` obtains fresh structured UI evidence. Alternatively give `snapshot` for historical evidence. Filter types, IDs (snapshot keys/ordinals), label/value substring, enabled/selected/frame-visible state, subtree root, depth, fields, count and item-byte budget. JSON coordinates are screen points; action coordinates remain window-relative.
4. Long strings/structured fields become asset references. `leap_asset` supports info, raw text chunks, automatic small-text/large-file selection, and explicit file materialization. Values come from the named immutable snapshot, never a later live read.
5. `ui_diff` returns bounded added/removed/changed nodes and field names for two observations. `interaction_result` joins intent/acknowledgement with interaction-level checks and observation references. `recording_review` remains the paginated full-history overview/actions/issues/grouped-events surface.

## Acquisition and readiness

Accessibility reads now carry a synchronous, thread-local monotonic budget. Window resolution and tree walking stop starting new reads when the budget expires; messaging timeout is bounded to at most 250 ms or remaining budget while acquiring, then restored to Leap's normal timeout. Read failures, capture start/end, deadline exhaustion and node-limit status are retained. Optional unsupported/no-value attributes are distinguished from transport/element errors. Attribute failures within a batch are tracked.

Both normal state and expectation paths now use budgeted acquisition. Expectations apply a settling grace after recent actions and retry observations only; incomplete or late snapshots cannot establish a predicate. Reaching the deadline with usable observations is distinguished from inability to determine the condition. Normal state retains its two-observation stability heuristic and rejects incomplete snapshots as proof of stability. Generic stillness is not business success. API-level strict cancellation of a synchronous AX call is still not guaranteed; no process-isolation worker was added.

Snapshot records include raw AX string values up to 65,536 characters, a valueLimited marker, capture quality, rendered parent/ancestor keys, and captured action index. Secure text remains redacted. The normal live text representation keeps its compact values; query/asset access uses the retained value. Older snapshots retain their original acquisition limits and cannot recover previously omitted content.

Recorded ordinary responses suppress unchanged disabled lines and cap displayed text around 10 KB, then append coverage and snapshot/query references. Full captured nodes remain available. This is deterministic size/disabled-control filtering, not a learned relevance ranking. Default internal observations no longer capture screenshots unless requested.

## Meaningful supporting checks

EvidenceTests covers filtered UI projection, node cursor advancement, large Unicode/quoted/multiline text without escaped-JSON output, exact file materialization, invalid asset references, missing subtrees, partial-comparison metadata and preserving API uncertainty alongside a met expectation. All fixture stores, scripts and results live under artifacts/test-runs/20260920-integrated/. These are code-level checks; native MCP acceptance remains required.

## Native acceptance after restart

- Confirm bind_project, ui_to_text, leap_asset, ui_diff and interaction_result definitions.
- Bind this repository, inspect Gameday via ui_to_text, filter buttons/selected fields, retrieve a subtree and paginate without losing nodes. Confirm coordinates/index distinction and omitted-value references.
- Exercise a reversible view transition with verified_action. Retrieve the joined result and compare before/after snapshots. Re-query a historical snapshot after another UI change; its content must remain unchanged.
- Retrieve/materialize a retained large-value fixture through MCP, checking raw characters and limits. Avoid interpreting a fixture/code-level pass as real-app acquisition proof.
- Recheck Gameday Save's ambiguous acknowledgement without replay, record acquisition duration/completeness, and test a controlled delayed/partial-read scenario. Incomplete absence must be unknown. Confirm normal controls still work with the shorter read budget.
- Continue remaining Gameday, iPhone/iPad Simulator and paired Sky/Leap Blender benchmark. Do not postpone Blender until every general inventory row is certified.

## Explicit remaining limits

No temporal-event predicates, hard cancellation of arbitrary blocking OS calls, automatic screenshot/binary-asset ingestion, arbitrary JSONPath/jq engine, retention rotation, or general compound transactional workflows were added. Assets currently expose captured text and serialized node fields; inaccessible application internals are not recoverable. Raw string capture is capped and marked. Comparisons require the same recorded session/window title, but durable window identities across replacement remain incomplete. Keys are content-derived; label changes can appear as remove/add. Legacy snapshots lack some new completeness and parent metadata. Binding is explicit after restart. Text asset offsets count characters, not bytes. Queries parse a bounded recorded snapshot locally; further large-store performance work remains possible.

Installed candidate SHA-256: `c2775ef3377f90e7d7dc1459a3c9968fabd9795ed77c19078cd3747a7e4c8eb4`. Release/signing passed. Four EvidenceTests passed with zero failures; native validation pending restart.
