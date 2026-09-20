# Recording v1 implementation checkpoint

2026-09-20. First deployable slice of REC-01/02. Native verification is pending session restart; compilation and signing are not acceptance evidence.

## Implemented surface

- `recording_start(app, project, window?)` explicitly binds a project and captures initial state. Recording continues between calls for the life of this MCP process. It is opt-in; ordinary app operations do not silently choose a storage directory.
- Project `.leap/leap.db` uses SQLite WAL, a schema version, a single-writer project lock, and locally resolved Git `info/exclude`. Missing-store queries are read-only and create nothing. Prior unfinished sessions are marked interrupted on the next writer attachment.
- Session UUIDs, tool-interaction UUIDs, action UUIDs, and monotonic record cursors connect immutable snapshots, action intents/results, subscription results and received AX notifications. Intent is committed before dispatch. A failed store prevents subsequent recorded actions; uncertain actions are never automatically replayed.
- AXObserver runs on a dedicated thread. Notification envelopes retain receipt time, ephemeral element hash and notification name, **not historical attribute values**. Application/window subscriptions and up to 64 candidate controls are attempted; registration errors, subscription ceilings and queue overflow are retained. A notification associated with an interaction is temporal evidence, not causal proof.
- State reads and pre-action observations retain trees without screenshots. `recording_query` filters historical records by session, interaction, kind and substring; `recording_nodes` retrieves filtered snapshot nodes with independent ordinal cursors. Responses have byte/record limits and retrieval hints; acquisition truncation is a separate fact.
- `verified_action` performs one action and checks a named current-state condition before/after it. It reports the action error separately even if the expected state is present. Errors from ordinary actions also attempt a fresh state read. `wait_for` no longer renders internal polls or consumes the displayed diff baseline; ambiguous selectors and incomplete disappearance evidence fail rather than pass.
- `recording_stop` retains history. There is no daemon recording while MCP is disconnected. Storage budget is 256 MiB checked every 128 writes; reaching it latches failure and preserves evidence, rather than silently pruning.

## Native validation after restart

1. Confirm new tool definitions, then start recording Gameday with project `/Users/ryan/src/claude-leap` before any diagnostic input.
2. Capture state, perform a reversible ordinary action with a meaningful expected result, query its interaction, and retrieve a snapshot node. Confirm received notifications and actual state changes; a returned API result alone is insufficient.
3. Exercise stop/start and retained historical reads; inspect local Git exclusion and session identity. Recheck the installed AXPress guard through the existing Gameday Save case, preserving any uncertain result without replay.
4. Add a repo-local controlled transient-event fixture to verify capture during blocking actions, then storage/overflow/restart failure cases. Native MCP tools remain the acceptance interface.
5. Continue the bounded Gameday → Simulator → paired Blender campaign from PLAN.md.

## Still required

REC-01/02 are partial, not complete. No automatic attachment after explicit project binding, fully typed dispatch/result contract, armed temporal expectations, persisted expectation verdicts, general compound predicates, selected-field/subtree projections, parent links, explicit multi-consumer diff baselines, automatic screenshot linkage, retention rotation/export, or independent user-defined interaction groups yet. Recording is per app process; snapshots include window title/geometry but no durable window identity. Batch captures before steps and final state, not a guaranteed dedicated after-snapshot for every intermediate step. Snapshot values can contain ordinary app content; action arguments are omitted and existing secure-field redaction is retained.

Notification delivery depends on the target app and macOS. Capture does not recover events emitted before attachment, unsupported notifications, or transient values the app never exposed. Large individual node values remain in SQLite when omitted from bounded tool output. The observer and storage failure behavior must be verified before promoting any row to TESTED.

## Build and installation evidence

Build/signing log and install identity: `artifacts/test-runs/20260920-recording-v1/`. Previous installed bundle is retained under `artifacts/backups/`. Registration remains `leap`.

Installed binary SHA-256: `d6b28927cb83f7c76c1f314afaa5a6dd5ac4fb832e1da2155f8de4ef1ffcb45d`. [Install metadata](../../artifacts/test-runs/20260920-recording-v1/install.json). Build/signing passed; no native pass claimed.
