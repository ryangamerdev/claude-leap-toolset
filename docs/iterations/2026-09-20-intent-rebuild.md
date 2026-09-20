# 2026-09-20 — Specification and intent-layer rebuild

## Outcome and evidence

User explicitly rejected treating existing implementation as precious and requested a full specification followed by aggressive rebuilding. [Release specification](../SPECIFICATION.md) fixes the outcome and scope. New orchestration is implemented around sessions, backend-neutral observations, selectors/assertions, workflows and retained evidence. WebDriverAgent was built and started on the existing iPad Simulator. No new native-host UI acceptance is claimed before restart.

## Rationale and alternatives

Continuing independent tool patches would retain the same agent-side orchestration burden. A wholesale rewrite of tested input primitives would add risk without changing that contract. Replaced the orchestration and startup guidance, reused AX/event/screenshot primitives behind the Mac adapter, and reused the append-only storage primitive to preserve history. Neither is exempt from later replacement. Added an independent device-native XCTest adapter to remove dependency on Simulator host AX geometry for guest actions. Used pinned maintained WebDriverAgent rather than write and maintain a new XCTest runner.

WDA is selected explicitly and does not fall back to Mac AX after failure. Its device identity and selected guest app are checked. Endpoint→UDID provenance comes from local runner setup, not a fabricated UDID derived from vendor identity. Existing recorded histories are retained; no schema reset or deletion was necessary.

## Changes

- AutomationEngine/AutomationModel replace manual orchestration with new preferred session/observe/perform/history/evidence APIs. Prevalidate step types and supported actions; fresh unique selector resolution; preconditions and bounded checks; per-step execution/dispatch/acknowledgement/verdict; stop dependent actions after failure or unknown.
- Mac adapter pins process and window identity. Device adapter uses WDA JSON observations and device-native actions. Coordinates require retained source snapshot, explicit space and unchanged bounds/tree/orientation. This is conservative stale-input rejection, not atomic exclusion of human input.
- Immutable snapshots, durable intents, per-step/results, raw field/chunk retrieval, full-envelope output budget, deduplicated bounded deltas and failure screenshots. Separate diagnostic errors retained; overbroad read-only warning wording corrected.
- Added pinned runner build/start/status and declarative scenario runner. Kept all runtime products in ignored repository artifacts. Replaced long server instructions and moved legacy skill instructions behind a conditional reference.
- Archived accumulated plan/checklist/handoff, replaced with concise release requirement/status tracking. Existing detailed trials remain the historical baseline. Legacy low-level tools remain available during native migration.

## Validation and delivery

Seven focused AutomationModel tests passed (partial acquisition, duplicate state checks, truncated values, scoped/exact selectors, incomplete deltas, full response budget, endpoint rejection). Initial budget test incorrectly compared escaped JSON text; corrected to decode its file field. Swift compilation initially required explicit optional CGFloat conversion; corrected. Release build/signature passed.

Installed signed candidate SHA256 `b727dc103a5c7c4011ce92091c6e31443f0450933838c1208afa48d238db5a6d`; [metadata](../../artifacts/test-runs/20260920-rebuild/install.json). Prior app preserved in ignored/local-only artifacts/backups/20260920-intent-rebuild/previous.app. skills-only install run; source and Claude/Codex copies compared byte-for-byte. Skill validation passed.

After installation, scripts/test-automation-contract.py exercised the real installed stdio MCP against a local fake WDA backend: failed assertion sent zero clicks; simulated effect plus lost acknowledgement sent exactly one click; fresh evidence met the postcondition while dispatch stayed uncertain; subsequent action skipped; two workflows and immutable earlier snapshot retrieved. [Curated results](../../artifacts/test-runs/20260920-rebuild/contract-results.json). Fixture paths within those results are ignored/local-only, not required from a fresh clone; the reusable script recreates them. This is protocol/adapter evidence, not a native app pass.

Pinned WDA1892efc71cc6e5bc8a20b083acc2753ea2288b62 built successfully against local Xcode and responded ready on iPad18.0 at127.0.0.1:8100. [Validation summary](../../artifacts/test-runs/20260920-rebuild/validation.json). Downloads/derived data/runner logs/endpoint manifest remain ignored/local-only. Runner startup may have foregrounded its test app; no Gameday content mutation was requested. iPhone runner is not yet provisioned.

## Remaining work

Restart host to load new tools and test the actual iPad guest bundle local.gameday.ios: discover/read, reversible information toggle with expected state, restore, inspect history/geometry, then rotate/scroll/drag. Compare with retained Sky baseline. Mac coach workflow and paired Blender artifacts remain release gates. Candidate implementation is not completion of R01–R16 acceptance.

Known limitations: WDA fresh semantic resolution requires globally unique name/role even when a normalized subtree selector was unique; guest replace-text and broader keys/gestures are unsupported; transient pre-armed event assertions not implemented; whole workflow timeout cannot hard-cancel synchronous OS calls; captured files consume storage beyond the SQLite budget; custom canvases require visual verification. Source skill and FEATURES make these boundaries explicit. Correct required gaps together based on native evidence, without expanding the fixed platform scope.

## Final review addendum

Before handoff, tightened workflow validation to reject unknown step fields, unsupported backend arguments and mistyped input arguments before any step is dispatched. This prevents silently ignoring device modifiers or falling back to a default mouse button. WDA also permits role-only targets when fresh backend resolution proves uniqueness. Rebuilt/reinstalled the consolidated candidate and reran the protocol fixture with a new case: an unsupported second step prevents the first step's input. Initial candidate identity retained in install-initial.json; final identity is install.json. No native acceptance occurred between these internal installs.
