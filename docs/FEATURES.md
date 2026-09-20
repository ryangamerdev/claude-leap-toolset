# Leap release checklist

Updated 2026-09-20. Scope and requirements: [SPECIFICATION.md](SPECIFICATION.md). This table replaces the accumulating checklist for current delivery decisions. The [historical inventory](research/archive/features-before-intent-rebuild.md) preserves feature IDs, earlier passes and evidence; those passes do not certify the rebuilt orchestration.

Status: PENDING = absent; RESEARCH = unresolved approach; PARTIAL = missing required scope; IMPLEMENTED = candidate exists without native acceptance; TESTED = named native case passed; CERTIFIED = repeated declared-scope native/regression acceptance; FAILED = observed unresolved failure; RECHECK = changed path needs replay; DEFERRED = outside release gate. No blanket certification.

| Requirement | Status | Candidate and exact remaining acceptance |
|---|---|---|
| R01 Target discovery/capabilities | IMPLEMENTED | target_list lists Mac apps and simctl devices. WDA uses explicit endpoint and stable backend device identity; actual UDID mapping belongs to runner manifest. Verify both devices and unavailable runner. |
| R02 Session ownership/history | IMPLEMENTED | New session IDs and append-only evidence; close leaves app running. Live handles expire at restart. Protocol fixture retained results/historical snapshots; native restart acceptance pending. |
| R03 Normalized observations | IMPLEMENTED | Mac AX + WDA JSON normalization, partial-read metadata and raw backend roles. Verify guest controls/geometry; selected can be unavailable on WDA. |
| R04 Shared selectors | PARTIAL | Exact id/identifier/role/label, contains/root; complete unique observation required. WDA re-resolution conservatively requires a globally unique named control; scoped repeated-label actions remain a gap. |
| R05 Bounded queries/content | IMPLEMENTED | Fields/depth/filter/frozen pagination; full envelope budget; retained raw field/chunk evidence_read. Verify large native tree and long value. |
| R06 Actions/backends | FAILED | Mac click/double-click/type/set/key/scroll/drag/activate; WDA click/double-tap/type/key subset/scroll/drag/activate/rotate. Guest replace-text and broader gestures unavailable; add only if gate needs them. Native role-qualified Route library and Playbook clicks passed; field information toggle remains failed. Gameday portrait rotation is excluded by app design. |
| R07 Coordinate provenance | IMPLEMENTED | Snapshot + space required, same session/tree/bounds/window/orientation; valid point bounds. No inferred host↔device conversion. Visual changes invisible to AX still require fresh screenshot judgment. Native move/rotate acceptance pending. |
| R08 Truthful outcomes/no replay | IMPLEMENTED | Step execution/dispatch/acknowledgement/check separated; ambiguous input halts workflow. Protocol fault fixture: one click after lost acknowledgement, completed effect retained, second action skipped. Not a native pass. |
| R09 Assertions/readiness | PARTIAL | Exact values, contains/count, enabled/disabled/selected/existence; preconditions and bounded polling. Partial observations produce unknown. Broader compound predicates and action-specific readiness need acceptance-driven completion. |
| R10 Intent workflows | IMPLEMENTED | Up to50 steps, prevalidated actions, pre/post checks, per-step evidence, skipped dependents, scheduling deadline metadata. Native multi-step case pending. |
| R11 Compact deltas | IMPLEMENTED | Bounded observed changes plus before/after references; identity churn remains possible. Validate relevance on real workflow. |
| R12 Durable failure evidence | IMPLEMENTED | Persist intent before dispatch, per-step/result records, failure screenshots when available, separate capture errors and diagnostics. Protocol fixture passed; native/storage-fault scope remains. File copies add storage beyond DB budget; no pruning. |
| R13 Temporal evidence | PARTIAL | Polling waits retain intermediate snapshots and observed occurrences. Pre-armed notification predicates/transient event coverage remain unproven; no complete-history claim. |
| R14 Regression scenarios | IMPLEMENTED | scripts/run-scenario.py runs reviewed declarative workflows through MCP, writes machine-readable results and exits nonzero unless checks pass. Native reusable scenarios must be authored from accepted workflows. |
| R15 User coexistence | RECHECK | Existing Mac targeted input reused; new WDA focus/cursor behavior requires native comparison. System keyboard fallback restrictions remain. |
| R16 End-to-end acceptance | PENDING | Historical Gameday/Sky evidence retained. New Mac/iPad/iPhone workflows and paired Blender artifacts must complete before release. |

## Installed candidate

[Intent rebuild iteration](iterations/2026-09-20-intent-rebuild.md), [install identity](../artifacts/test-runs/20260920-rebuild/install.json). WDA runner built and health-ready on iPad; this is infrastructure readiness, not UI acceptance. Seven focused contract tests and a protocol fault fixture passed. Restart required to expose new tools in the current host.

## Deferred scope

leap-cli, physical-device provisioning, Android/Windows/browser backends, arbitrary code execution inside workflows, complete event sourcing and virtual HID are not prerequisites. Existing history is preserved; no data reset performed.

## First native WDA checkpoint

[Native WDA trial](iterations/2026-09-20-wda-native.md): guest attachment,619-node observation, correct in-bounds information-control geometry, history and nested retrieval passed scoped native calls. Selector taps returned without expected effect both before and after verified host foreground activation. R06 remains failed for that case. A coordinate test exposed false stale rejection of equal numeric bounds; corrected and installed; after restart the coordinate tap dispatched but still had no observed toggle effect. Neither this correction nor observation success establishes device input parity.

## Landscape checkpoint

[Native checkpoint](iterations/2026-09-20-wda-landscape.md): numeric-bounds guard passed native dispatch; role-qualified Route library and Playbook clicks passed their postconditions. Label-only ambiguous targeting safely refused input. Gameday is intentionally landscape-only, so portrait refusal is not a Leap acceptance failure. Information-control effect remains unresolved. Navigation deltas showed substantial identity churn; compact output alone is not yet proof of useful change summaries.
