# 2026-09-20 — Separate optional metadata from blocking capture failures

## Outcome and evidence

The paired iPad comparison showed both controllers could toggle information/field views,
but Leap's two persistent AXSubrole generic failures prevented settling. Its final short
scan could replace useful earlier evidence with a sparse tree. This increment addresses
those policy failures; it does not claim the provider now returns the missing subroles.

## Rationale and alternatives

Do not erase AX failures or assume all subroles are optional: text/secure-field interpretation
and unknown roles need conservative handling. Restrict advisory classification to generic
.failure on AXSubrole for known button, checkbox, scroll area, toolbar, menu bar/item and
image roles. Transport/timeouts, unknown/text roles and other attributes remain blocking.
This narrow whitelist is intentionally conservative; native role diagnostics will show if
it addresses the observed iPad controls. No universal predicate dependency engine is claimed.

Global retries did not recover these reads. Preserve their diagnostic counts, roles and
impact classification, allowing ordinary label/state checks to proceed only when blocking
coverage is complete. Retain an earlier usable scan if a later scan is incomplete, explicitly
marking it rather than claiming it is the latest state. Stability still requires two consecutive
usable matching scans. Historical comparisons retain their conservative incomplete flag.

## Changes

AXWindowSnapshot now exposes advisoryReadFailures, blockingReadFailures and
retainedEarlierObservation alongside the total and bounded details. Failed batched attributes
carry the already-read role without extra diagnostic AX calls. Engine settling and label/state
expectations use blocking coverage. Text warnings distinguish advisory metadata from missing
coverage. Timeout wording no longer asserts the UI was changing; truncation no longer falsely
claims 1500 nodes when a deadline/depth limit stopped a small tree.

The skill documents new metadata and stale-return handling; both installed skill copies are
synchronized during installation. No new tools or registration changes. Action-scoped deltas
and the timestamped timeline remain separate pending work.

## Validation and delivery

Focused ObservationQualityTests cover role/attribute exclusions, complete failure counts with
capped samples, and transport errors remaining blocking. Run via `swift test --filter
ObservationQualityTests`; code tests are not native Simulator acceptance. Release build/signature
and installed identity are recorded under artifacts/test-runs/20260920-field-quality.
Build logs and rollback bundles remain local-only. Native verification requires restart.

## Remaining work

After restart bind the repository and read the iPad. Inspect role/impact, total/advisory/blocking
counts. If roles are not in the safe whitelist, keep the errors blocking and investigate rather
than expanding it blindly. Repeat Show play information / Show field with verified_action,
confirm stable useful responses and restoration. Observe iPhone for regression. Delayed/partial
capture still needs controlled native coverage. Then implement DATA-20/21 and proceed with
Simulator and Blender trials. Commit/push this build/install checkpoint before handoff.

## Delivery result

Release build and signature passed; installed SHA-256 `a0ec8c9ead9dbd0315f9e212c3504a335127604745be9143a119586e101b2678`. Two focused tests passed with `TOOLCHAINS=org.swift.640202609131a swift test --filter ObservationQualityTests`. Initial default-Xcode runs failed in the MCP dependency’s newer task-group API, not in the test assertions; logs retained locally. Reverted only the generated Package.resolved originHash change after verifying pins were identical. Both installed skill copies match source. Native acceptance remains pending user restart.
