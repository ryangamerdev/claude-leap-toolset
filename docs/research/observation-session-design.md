# Durable observations and verified actions: evaluation

Implementation update: [Recording v1 checkpoint](recording-v1-checkpoint.md) distinguishes the deployed slice from this full design. The inventory below describes the pre-recording baseline.

2026-09-20. Design recommendation, not implemented. Evaluated the local Runner and Leap source, plus the recorded Sky AX wrapper research. Existing AXPress guard is installed but still awaiting native restart verification. This document does not change that status.

## Recommendation

Adopt Runner's retained-evidence, compact-result, drill-down pattern. **Build the durable session/event journal in the first increment, alongside action outcomes.** Capturing evidence only after a failure is too late to recover transient observations. Extend Leap's existing sessions into a versioned observation store and add a structured action/expectation pipeline. The agent should choose intent and success criteria; Leap should handle mechanical capture, bounded observation, comparison, and evidence retrieval. This revises the earlier recommendation to defer persistence until after expectations.

Do not start with a new mandatory init protocol, a general scripting language, or arbitrary jq-to-SQL translation. Those are not prerequisites for reducing context and improving correctness.

## What exists today

- `Engine.session` creates in-memory sessions by PID and detects replacement processes using application identity.
- `AXNode` already models roles, labels, values, identifiers, frames, enabled/focused/selected flags, actions, depth and keys; snapshots also indicate truncation. It is an observation model, not the app's complete internal state.
- `AppSession.render` assigns indices and generates full text/diffs with state generations. It retains the current table and previous rendered lines, not a durable queryable history. Its baseline is shared internal state, not a per-consumer acknowledged snapshot.
- Successful ordinary actions normally capture and return state (`then_state:true`); screenshots are off by default. `get_app_state` can include a screenshot and the screenshot tool supports save-only capture.
- `set_value` verifies read-back; `wait_for` supports bounded appearance/disappearance, enabled/disabled and value-contains checks. `batch` supports up to 50 steps and returns a final state.
- Action exceptions bypass the normal post-action state return. Batch failures report prior steps but do not normally attach fresh state. The recent Save incident illustrates this gap.
- `wait_for` currently updates the rendered baseline while polling. Observation used internally should not consume the caller's diff baseline. Its timeout wording also says “Nothing was done,” which is misleading after an earlier action in a batch.
- The walker has limits (including 1500 nodes). Some controls are virtualized; canvases may expose little semantic content. Missing from a captured tree does not always mean absent from the app.

## Runner patterns worth adopting

Reviewed `core/runner_core.py` and `mcp/src/index.ts`, not just README claims. Runner stores metadata, full stdout/stderr, events and per-consumer trackers. Test adapters normalize Go/pytest output; success collapses to counts, failures include bounded detail and exact log references. Responses expose cursors, truncation and follow-up calls. It separates a pattern match from authoritative process state.

Leap equivalents: session/action/observation IDs; retained captured trees; compact outcome/changes; exact evidence references; bounded queries; per-consumer or explicit `since` cursors; honest completeness. Domain summaries should be deterministic and traceable to nodes, with raw observations retained. Avoid guessing business success from button text alone.

Important difference: logs of a completed run are historical evidence; UI state changes independently through user input, timers and other clients. Persisted snapshots never authorize a click without fresh identity/geometry validation. Surviving a restart means evidence survives, not that old AX handles remain valid or a workflow automatically resumes.

## Proposed architecture

1. **Automatic session attachment.** First observation or safely resolved action attaches to an application instance and an explicit window/device. Optional explicit open/resume supports discoverability and retention settings. Separate durable session ID, process epoch, window identity, snapshot ID and action ID. PID/window-title alone is insufficient across relaunches. Existing app arguments remain usable.
2. **Immutable captured observations.** Keep serializable nodes with parent links, coordinate space, source, timestamps, coverage, unavailable fields and truncation. Keep live AX handles only in memory. Store an observation before/after each action, reusing an actually fresh baseline where valid. Snapshot capture is not atomic across an entire changing app: record capture interval and stability limitations.
3. **One durable store.** Use a project SQLite database at `.leap/leap.db` with sessions, snapshots, nodes, actions, checks and screenshot metadata. Use bounded retention; export JSON/JSONL on demand for jq, debugging and regression fixtures. Screenshot bytes remain ordinary files under `.leap/sessions/<session-id>/`. Do not maintain independent SQLite and JSON sources of truth. For this campaign the project root is this repository, regardless of which app Leap controls. Explicitly curated regression exports remain under `artifacts/test-runs/`; bulk capture stays locally excluded through Git's exclude file, not tracked `.gitignore`.
4. **Compact projections.** Return action outcome, failed/unknown checks, relevant changed nodes, unexpected dialogs, focus/window changes and retrieval hints. Store the captured tree even when most nodes are omitted from the response. Default to the target region plus relevant application changes; unrelated disabled tabs are queryable, not repeated. Keep separate internal observation generation and externally selected diff baseline. Changing rendering options must not make unchanged UI look changed.
5. **Bounded read-only query.** Start with declarative selectors: role, exact/contains label, identifier, value, subtree/window, enabled, visibility and changed-since; support selected fields, count, limit and cursor. Return matched count and completeness. `snapshot` means historical data; `fresh` means obtain a current observation. Compile this small selector model to parameterized queries or evaluate in memory; do not promise full jq-to-SQL equivalence. JSON export already enables real jq offline.
6. **Action plus expectations.** Resolve a unique live target, verify preconditions, dispatch once, observe, evaluate bounded postconditions, persist evidence and return a compact result. Supported checks should include exact value, count, selected/enabled state, appearance, disappearance and change-from-before, plus `all`/`any`. Match ambiguity is explicit; incomplete observations can yield unknown. Expectations are caller-declared or conservatively generic, not app-specific inference disguised as verification.
7. **Continuous event evidence within an attached session.** Register supported AX notifications and retain each received notification's envelope before coalescing expensive refresh work. Capture source element information when feasible and separately record when it was actually read; notification receipt does not freeze an element's old value. Notifications also mark scopes dirty. Use bounded polling during expectations and fresh validation before actions as backstops. Do not continuously screenshot or rescan every app. Internal work still costs time even when it consumes no model context.
8. **Visual evidence as a separate channel.** Opt-in screenshot capture can save a file without embedding it. Bind capture to the observed window and record timestamp, geometry and scale; do not claim exact simultaneity with AX capture. Return a resource reference/crop on demand. AX verifies ordinary control state; Blender geometry and visual correctness still need image review or a trusted app-specific adapter. Pixel differences detect change, not success.

## Action result contract

Represent these independently rather than collapsing them into one success boolean:

- Dispatch: not-sent / sent / unknown (for interrupted or lost acknowledgement cases).
- API acknowledgement: accepted / rejected / uncertain, with original error code.
- Observation: available / unavailable, snapshot reference and freshness/coverage.
- Expectations: passed / failed / unknown / not-requested, with matched node evidence.

Write action intent before dispatch and terminal observations afterward. An interrupted action journal entry remains unknown and is reconciled by observing, not replaying. Caller-provided request IDs can deduplicate transport retries, but cannot create exactly-once guarantees across the OS dispatch/crash boundary.

After ambiguous AXPress, do not send a fallback click. Capture fresh state and evaluate requested checks. A timeout is not proof that nothing happened. If an expectation already held before the action, report that distinction; it may not verify a new effect. A vanished Save button establishes a UI transition, not durable saving. Reopening and comparing the stored value is a stronger, separate workflow assertion.

An explicitly unsupported AX action may use a preselected pointer fallback under existing live-target guards. Pure observation retries are safe; action retries require explicit policy and evidence. Conditional batch branches are bounded and stop on unknown outcomes. No loops that implicitly resubmit or silently replay prior steps.

## Illustrative interface (proposal only)

An action could accept `target:{role:"button",name:"Save"}`, `expect:[{target:{role:"textField",name:"Play title"},condition:"absent"}]`, a timeout, and `capture:{screenshot:"save"}`. The response could state: action sent, AX acknowledgement uncertain, editor-closure check passed, snapshot reference, no replay. The caller would still reopen and check notes to verify persistence.

Exact schemas should be designed around the generic result contract and current tool compatibility. Keep convenient existing click/set_value tools as wrappers; a new action tool is not inherently necessary.

## Implementation order and acceptance

[../PLAN.md](../PLAN.md) is the authoritative current execution order and restart checkpoint; the stages below describe architecture delivery. [../FEATURES.md](../FEATURES.md) tracks acceptance status.

1. Durable SQLite session/interaction/action/event/snapshot journal, AX observer subscriptions with recorded coverage, and typed action outcomes together. Include bounded event retrieval and initial/before/after snapshots. Capture starts before the action under test; follow-up observation also runs on ambiguous errors. Keep callback delivery independent of blocking AX requests.
2. Scoped event queries and snapshot selectors, immutable baselines and compact projections. Confirm queries match retained evidence, loss/truncation is explicit, concurrent consumers do not consume each other's diffs, and restart invalidates actionable handles. Reproduce Gameday Save and inspect the captured interval without replaying Save.
3. Attach expectations to existing actions/batches; arm event predicates before dispatch, evaluate state and temporal checks with separate semantics. Verify false/unknown cases: incomplete tree, duplicate labels, preexisting condition, delayed updates, app relaunch and user interaction.
4. Save-only screenshots and referenced crops where AX evidence is insufficient. Preserve visual tests for Blender and cross-device targeting for Simulator. Keep the TUI deferred until end-to-end parity is demonstrated.

Measure returned text size and model image attachments, round trips, latency, false success, duplicate dispatch, and recovery after interruption on the same Gameday/Simulator/Blender cases. No token-saving percentage or general parity is claimed without measurements. Retain protected-value redaction and explicit retention controls for persisted UI data; do not bypass secure accessibility fields.

This design improves the existing campaign rather than replacing its acceptance tests. Runner is an architectural reference, not a runtime dependency for Leap.

## Event-capture clarification and first-increment requirements

Runner's important advantage is not merely compact output: retained evidence lets the agent ask a new question without repeating the original operation under different conditions. Leap needs that property immediately. Snapshot history alone cannot capture a short-lived notification or transient intermediate UI state between calls. The current Leap source has no AXObserver event capture implementation.

macOS provides AXObserverCreate/AXObserverCreateWithInfoCallback, per-element notification registration, and a run-loop source. Notifications can be unsupported by the target. Reference: https://developer.apple.com/documentation/applicationservices/1462089-axobserveraddnotification and local Xcode AXUIElement.h. AX is not a lossless application event log: callback payloads do not universally include previous/new values or original event times. A follow-up read may find the element changed or destroyed. Never describe this as capturing every application event or reconstructing every intermediate tree.

Store: durable session ID, process epoch and explicit window/device identity; interaction ID for a logical multi-action operation; action ID for each dispatch; ordered observer-receipt events with monotonic and wall-clock timestamps; source/provenance, payload where available, and separately timestamped attribute observations; snapshot references; subscription successes/failures; capture interruptions, queue overflow and retention boundaries. Temporal association with an action is not proof the action caused an event: user input and asynchronous work can overlap.

Subscribe before the initial scan, bracket the scan with event cursors and reconcile events received while scanning; no atomic whole-app snapshot is promised. Re-register on lifecycle changes. Callbacks enqueue lightweight immutable envelopes promptly; a single writer commits bounded batches to SQLite. Avoid synchronous full-tree traversal inside callbacks. Preserve notification envelopes while coalescing refreshes; record explicit gaps if any queue/storage budget is exceeded. Observe only attached targets and preserve secure-field redaction.

A dedicated observer run-loop thread is necessary if AX actions block the main executor, as Save can do. A long-running observation process is required for capture across MCP disconnection; a first version can run inside the persistent MCP process between calls and record gaps on restart. Historical evidence survives shutdown, but no events can be captured while its observer is absent. Do not imply a database by itself supplies an always-running recorder.

Provide bounded queries such as events since cursor, events during an interaction, notification/source/text filters, and nearby snapshots. Distinguish `currently true`, `observed at least once since action`, `remained true for an observed interval`, and `no matching event observed`. Event absence is not proof of non-occurrence when coverage is incomplete. Saved screenshot policy remains independent; no screenshot can reconstruct an uncaptured past frame.

## Tracer storage reference

Inspected `/Users/ryan/src/tracer-mcp/internal/trace/store.go` and the existing `/Users/ryan/src/raindb-prime/.tracer/traces.db` using a read-only SQLite connection. The latter contains 20 traces, 2,569 steps, 77 mutations, 39 findings and 2,549 flow edges; six trace directories contain rendered report artifacts. The SQLite database is the structured record and per-trace directories hold derived assets. No RainDB records were edited.

Tracer resolves the Git top-level from the supplied project path, falling back to the absolute supplied directory outside Git. The write path creates `.tracer/`, opens `traces.db`, and idempotently appends a local exclude rule. SQLite enables WAL, foreign keys and a 5-second busy timeout; the store limits itself to one connection. The schema contains source provenance, ordered steps, before/after mutations, evidence links, and explicit observed/derived/assumed/unknown confidence. Those are useful patterns for Leap; do not copy Tracer's clean/pushed-source creation prerequisites into interactive app control.

Leap adaptations:

- Determine the capture root from an explicit project/session binding or the calling workspace. Do not infer it from Gameday, Blender, or Simulator's bundle path, or silently accept an unrelated MCP process working directory. Pin the resolved root in the session and return it on attachment.
- Create `.leap/leap.db` and `.leap/sessions/<id>/` only when starting recording. Historical list/query operations on a missing store return empty/not-found without creating state. Use actual read-only DB connections for historical reads; Tracer's OpenExisting avoids missing-store creation but still calls its common initialization path.
- Add `/.leap/` idempotently through Git's resolved exclude path. Prefer `git rev-parse --git-path info/exclude` to manually interpreting `.git`, so linked worktrees/common-directory layouts are handled by Git. Preserve existing contents and coordinate concurrent initialization; verify effective exclusion. If exclusion fails, surface a warning instead of claiming artifacts are ignored. Do not edit tracked `.gitignore`.
- Keep relational columns for indexed identity/order/type/time and JSON payloads for varying notification/AX attributes. Schema versions and explicit migrations are required. Separate received events, later observations, derived changes and expectations, so inferred history is never presented as a native event payload.
- WAL and a dedicated writer support the recorder, reads and a future TUI, but do not alone guarantee durability or zero event loss. Record capture gaps and define commit/retention policy. One writer per project needs coordination across multiple MCP instances.
- Keep generated images and exports in session directories and store relative artifact references. Curated reproducible tests/evidence can be exported intentionally into tracked repo paths. Existing campaign evidence remains in place.

Tracer is the stronger reference for project-local structured persistence and provenance; Runner remains the useful reference for compact summaries, retained raw evidence, cursors and drill-down. Neither substitutes for implementing the macOS event recorder.

## Companion `leap-cli` TUI

Deferred by user until core end-to-end parity. User-requested addition: an operator console, inspired by runner-cli, for watching and helping the agent. It reads the same journal and observation model; it must not run an independent automation engine with conflicting targets or issue its own AX scans just to redraw the display.

Suggested panes:

- Sessions: app/process epoch, explicitly selected window/device, foreground/background, latest observation age, active action and pause owner.
- Timeline: requested actions, dispatch/API outcomes, expectations, delays and observations; highlight uncertain outcomes and unmet checks rather than only tool errors.
- Inspector: searchable captured tree, node properties/ancestry, relevant before/after changes, matched selectors, and coordinate/visibility provenance. Distinguish captured, fresh, partial and unavailable state.
- Evidence: screenshot references with timestamps; open a local image preview. Inline terminal images are an optional terminal-specific enhancement, not a dependency.
- Operator notes: select an observed node, flag a mismatch, attach a short correction and link it to session/snapshot/action IDs. Return pending corrections on the next agent tool response; do not claim to interrupt an idle model without a supported notification mechanism.

Start read-only, then add cooperative intervention:

1. Pause prevents subsequent action dispatch and acknowledges when the current gesture has finished and held inputs are released. It cannot revoke an AXPress already delivered to the app; show that clearly.
2. The user takes control and corrects the app. Resume triggers fresh observation and target revalidation. Pending workflow steps remain suspended until their preconditions are checked; do not blindly resume a cached batch.
3. Invalidate coordinate targets and old actionable handles when context changes. Revalidate the app/window on hand-back. Never auto-switch the agent to whichever window the operator clicked.
4. Optional later operator actions (such as highlight node, request fresh observation, or choose an explicit target window) go through the same serialized action/control channel and are separately attributed. Tree selection alone does not click the app.

Storage is evidence, not a command queue. If MCP owns the live engine, provide a local IPC control endpoint per server instance; the TUI uses it for pause/resume and attribution. SQLite readers can inspect committed history, but must not write control flags directly into tables or access live AX handles. Multiple MCP clients need an explicit shared input lease/coordinator before cross-client exclusion can be promised; serializing each process separately is insufficient. An offline TUI can show history but cannot pause a disconnected server. A separate long-lived daemon is an option if cross-client operation warrants it, not required for a read-only first version.

Additional acceptance cases: TUI never steals focus merely by observing; pause during an active gesture completes/releases safely; user correction invalidates cached targeting; notes reach the agent with correct provenance; UI/log viewers cannot cause duplicate dispatch; an MCP crash is shown as disconnected/unknown, not successful or paused. Keep the existing visible Leap pointer overlay.

## Recording failure policy (peer-review decision)

In recording mode, commit action intent before dispatch. If that commit fails, refuse input and report not-sent plus the storage error. After dispatch, recording/observation failure must preserve sent/uncertain status, stop dependent batch actions and report the unavailable evidence. Never retry input to repair an observability failure. If storage itself cannot retain the failure record, report it directly to the caller; on restart reconcile unfinished intent as unknown. A later opt-in degraded mode would require a separate explicit contract; none is assumed.

A controlled repo-local transient-event fixture is required: produce a notification while an AX call blocks, then retrieve the recorded envelope after the transient UI has disappeared. This proves between-call/during-call capture without claiming a complete historic tree. Independently exercise overflow, unsupported subscriptions, disk/write failure, migration rejection, independent query cursors and capture versus response limits. See REC-01–03 in PLAN.md.
