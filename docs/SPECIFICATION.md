# Leap release specification

Version 2, 2026-09-20. This document supersedes architectural preferences in older plans. Existing code has no preservation requirement. Existing user data, recorded evidence, registration `leap`, and truthful acceptance history do. The user authorized replacement/rebuilding to finish the product rather than indefinitely extending a prototype.

## Product and release boundary

An agent must discover an unfamiliar native application, understand relevant state, perform intent-level operations, verify outcomes and investigate failures without replaying input or loading enormous trees. The MCP owns target resolution, readiness, bounded polling, journaling, deltas and failure evidence. The agent owns task intent and visual judgments not represented by accessibility.

Release targets: macOS desktop applications including Gameday and Blender, and Gameday on iPhone/iPad Simulator. Physical devices, browser DOM, Windows/Android, virtual HID, TUI, remote access and arbitrary scripting engines are not release blockers. Neither historical architecture nor matching Sky internals constrains the solution.

## Required contract

| ID | Requirement | Release evidence |
|---|---|---|
| R01 | Discover Mac and Simulator targets with identity, availability and backend capabilities. | Correctly distinguish both devices and guest application from Simulator host. |
| R02 | Explicit project/session open, close, immutable evidence history and process-restart semantics. | Two sessions retained; restart preserves history; old live handles refused. |
| R03 | Observe normalized elements with backend role, identifier, label/value, hierarchy, states, geometry and completeness. | Gameday and both devices; canvas limits declared. |
| R04 | Select by exact identifier/label/role and subtree; exactly one match for single-target input. | Zero/duplicate/replaced-element cases cause no unintended action. |
| R05 | Query snapshots with filters, fields, depth, cursor and total response budget. | Large observation remains retrievable; no silent truncation. |
| R06 | Dispatch semantic or coordinate actions through an explicitly selected backend. | Click, double click, text, keys, scroll, drag; capability-specific refusal. |
| R07 | Coordinates identify snapshot, space and target; stale geometry rejected. | Move/resize/rotation and host/device-space confusion refused. |
| R08 | Distinguish execution, dispatch, acknowledgement and verification; no automatic input replay. | Timeout/API ambiguity after completed effect never duplicates input. |
| R09 | Actionability checks and bounded current-state assertions share selectors. | Exact/contains/count/enabled/selected/existence; partial absence unknown. |
| R10 | Bounded workflows execute action/wait/assert/observe/capture with pre/post expectations and per-step evidence. | Stops dependent steps after failure/unknown; retains completed steps. |
| R11 | Ordinary responses return compact deduplicated changes plus retrieval handles. | Before/after IDs and useful field changes; unchanged tree omitted. |
| R12 | Durable intent before dispatch, outcome after, automatic failure artifacts and independent diagnostics. | Storage-failure and observation-failure paths preserve uncertainty. |
| R13 | Temporal observations distinguish ever-observed from final state. | A bounded wait can report observed occurrence; no claim of complete event history. Pre-armed transient AX event assertions require separate native proof. |
| R14 | Reusable declarative scenarios and machine-readable results. | Run a saved workflow without agent intervention; retain run/result/artifact identities. |
| R15 | User coexistence and explicit foreground policies. | Targeted background Mac pointer and foreground tests; report keyboard restrictions. |
| R16 | Finish paired Sky/Leap campaigns, not just implementation tests. | Coach filter/inspect/new play/route/save/reopen; iPhone/iPad orientation/tap/drag; separate editable Blender basic-shape Mickey heads saved and reopened. |

## API

New preferred surface (existing tools may remain as compatibility/debug adapters):

- `target_list`: running Mac apps plus available Simulator devices; no guessed readiness.
- `session_open(project, app, backend, window?, endpoint?)`: Mac AX or local WDA endpoint. Returns session and actual target, creates durable session record. WDA endpoint must belong to intended booted device; setup records UDID/port. Attaching may activate guest app but must not reset/reinstall data.
- `session_close(session_id)`: closes Leap ownership and evidence session; no app termination/reset. Historical evidence remains readable.
- `ui_observe(session_id, snapshot?, selector?, fields?, after?, limit?, max_bytes?)`: fresh or retained normalized snapshot; historical reads never acquire a live app.
- `ui_perform(session_id, steps, timeout?, expected_snapshot?)`: intent workflow; bounded 50 steps, 120-second scheduling budget, per-condition bounded polling. No loops/eval, automatic input replay, silent backend switch or implicit target change.
- `session_history(project?, session_id?, after?, limit?)`: timestamped operation inventory; detail remains queryable by record reference.

Step shape: `{id?, type: action|assert|wait|observe|capture, action?, selector?, arguments?, expect?, timeout?}`. Actions are click/double_click/type_text/set_value/press_key/scroll/drag/activate. Assertions are `{selector, condition: exists|absent|enabled|disabled|selected|value_equals|value_contains|count, value?}`. Before-condition can gate action. Coordinates require a current snapshot reference and explicit space; do not reinterpret old numbers after movement.

All preferred responses are JSON with schema version, session/interaction identity and operation-specific data. Workflow results include each step's execution (`completed/failed/skipped`), dispatch (`not_sent/attempted/uncertain`), verification (`passed/failed/unknown/not_evaluated`), error, snapshot references and observed delta. `attempted` means an API request was made, not proof of effect. Unexpected exceptions after input preserve uncertain dispatch. Assertions are observations, not causal proof. No boolean success may erase uncertainty.

## Architecture

1. New orchestration layer owns live sessions, normalization, selectors, checks, workflow execution, retained artifacts and bounded responses.
2. Mac backend uses AX for semantics, targeted native events for canvases, ScreenCaptureKit for images. Reuse primitives only when they satisfy the contract; old rendered-text tool orchestration is not the new API.
3. Simulator backend uses maintained WebDriverAgent/XCTest, with explicit endpoint/session attachment, device-space queries and input. No conversion through a host AX rectangle for guest-device semantic input. Startup tooling pins reference identity and records local logs. Failed backend setup is explicit, never an automatic fallback to host AX.
4. Durable project store retains session, operation, snapshot, outcome and artifact metadata. Existing histories are not deleted. Independent diagnostic logging remains configured in ~/.config/leap/leap.json and stored in ~/.leap/logs/.
5. Source skills describe current installed contract and concrete examples; acceptance status is separate. Each meaningful install is signed, backed up, committed and pushed, then tested through the restarted MCP.

## Observation and selectors

Node IDs are snapshot-local handles. Durable selectors use identifier first, role/label and scope where needed. Backend-only IDs never cross sessions. Exact-match selectors default; substring is explicit. A partial scan cannot establish absence, uniqueness or exhaustive count. Value truncation cannot establish exact equality. Unsupported attributes stay unknown. Parent links and raw backend roles are retained.

Snapshot metadata includes acquisition time interval, target identity, coordinate space/window bounds, completeness and limitations. Mac AX reads are not atomic. WDA snapshot completeness describes successful backend traversal, not proof the framework exposes every visual object. Canvas verification still requires images.

Output budgets bound the entire returned JSON, not only element arrays. Oversized fields get retained references/previews. Pagination binds to immutable snapshot; live refresh uses a new snapshot. Whole snapshots remain on disk. No unbounded recursive object expansion in ordinary results.

## Workflow, timing and errors

Validate syntax before first input. Re-resolve selectors against fresh observations; check target identity and coordinate provenance immediately before dispatch. Journal intent before calling the backend. Capture result and post-observation, then evaluate expectation. Retry observation, never input. Stop subsequent mutations after uncertainty or failed preconditions.

Waits use monotonic deadlines and bounded intervals; slow synchronous OS calls can overrun scheduling budgets and must be reported rather than represented as hard-cancelled. `assert` evaluates one observation; `wait` polls for a condition. A transient condition only counts if actually observed, with its snapshot/time retained. No promises of catching every toast without covered event instrumentation.

Failure artifacts contain best available post-state, image when possible, and diagnostic references. Evidence capture failure is separate from action failure. Secure input arguments are not journaled as cleartext; UI observations may themselves contain sensitive app content, so stores remain project-local and locally excluded.

## Capability policy and lifecycle

Capabilities describe operations implemented by a backend, not certified acceptance. Missing/unavailable backend dependencies are explicit. Opening a WDA session is a lifecycle operation with possible foreground effects; record them. No erase/uninstall/reset action is implicit. Mac sessions pin process and selected window; relaunch invalidates live session. Device endpoint and guest app must be verified by setup and backend state; broad physical-device support is deferred.

## Regression and delivery gate

Focused tests cover selector ambiguity, partial absence/count, budgets, failure after dispatched input, workflow stop/skips, persisted history and adapter errors. Native MCP acceptance covers observable app effects and persistence. Scripts/harnesses do not substitute for that gate.

Finish in consolidated installations, not one restart per small fix. A release is complete only when R16 artifacts exist and no unresolved P0 issue invalidates those workflows. Track implementation and native acceptance separately in FEATURES. Record each delivery's remaining concrete gaps rather than repeatedly expanding the release boundary.

## First installed implementation and deviations

[FEATURES.md](FEATURES.md) is the current traceability matrix. The first v2 installation implements the new intent layer and WDA adapter; it does not assert that the release gate has passed. Semantic WDA subtree selection currently requires globally unique backend re-resolution; nested compound predicates, pre-armed transient-event checks and whole-store artifact budgets remain incomplete. APIs also include evidence_read for raw nested retained values. Legacy tools remain available until the new native campaign demonstrates equivalent coverage. The acceptance gate, not preservation of these adapters, decides what ships.
