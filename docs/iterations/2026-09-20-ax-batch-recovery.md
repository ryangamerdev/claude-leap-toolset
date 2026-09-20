# 2026-09-20 — Diagnose and recover per-attribute batch read failures

## Outcome and evidence

After the user restarted diagnostic build `7f13fab06b2a1c51b66dcf68265776469fa9e47531b44382998a40ce8f193c07`, native bind_project and ui_to_text targeted the open iPad Air 11-inch (M2) window. Snapshot 484 retained 105 nodes, two failures, no deadline exhaustion and no node truncation. Both failure samples named AXSubrole with generic AX error -25200 on different ephemeral element hashes. All samples fit the eight-sample budget. The intended Freshman 2026 playbook was identified.

This verifies that the new diagnostic metadata is useful through the MCP. It does not prove that the single-attribute getter succeeds, nor that AXSubrole failures may safely be ignored. [Native response](../../artifacts/test-runs/20260920-ax-batch-recovery/native-before.json) is tracked; the raw database is local-only under ignored `.leap`.

## Rationale and alternatives

The walker already falls back to individual getters when an entire multi-attribute call fails. However, a successful batch can contain an error for an individual field, and this path previously counted that error without trying the corresponding getter. A narrowly bounded fallback makes those two paths consistent.

Increasing global timeouts is unsupported by the evidence: this error is generic failure, not cannotComplete or deadline exhaustion. Ignoring optional subrole failures would erase uncertainty without establishing what the provider means. Replaying the user's action cannot help and risks duplicate effects. One read-only retry for generic per-field failure is a useful next candidate: accept a returned value or explicit unsupported/no-value result; otherwise preserve the final failure. This is a recovery hypothesis to test after installation, not a proven Simulator fix.

## Changes

- For a generic AX error inside an otherwise successful attribute batch, retry that attribute individually once, only if the acquisition budget allows starting the read.
- Successful values populate the same attribute dictionary. Explicit unsupported/no-value replies retain the existing legitimate-missing treatment. Other errors remain counted and sampled.
- Snapshot metadata adds batchReadRetries and batchReadRecoveries. These distinguish recovered batch-provider failures from silently discarded errors. A recovery can mean an explicit no-value/unsupported result, not necessarily a returned value.
- No input dispatch retry, foreground change, tree completeness relaxation or timeout increase is introduced. Individual reads stay under the existing messaging/read budget.

## Validation and delivery

Native evidence above tests the diagnostic build, before this recovery change. Run `python3 scripts/bundle.py`, retaining the release/signature log under this iteration's artifact directory, then `python3 artifacts/test-runs/20260920-ax-batch-recovery/install.py`. Install metadata records the exact build and local-only rollback bundle. Native recovery acceptance requires the user's next restart. A successful build alone cannot close the iPad failure.

No broad suite or alternative stdio harness replaces the requested native test. This iteration remains uncommitted; earlier permission to push applied to the completed checkpoint.

## Remaining work

After restart: bind the repository, read the iPad with ui_to_text, inspect failure samples and retry/recovery counts. Success requires either explicitly recovered reads with no remaining failure or an accurately retained failure leading to further diagnosis. Verify the iPhone still yields the correct playbook. Stop repeating input if acquisition remains incomplete.

The user's interaction timeline request is now explicitly DATA-21: a bounded timestamped list of interactions, actions/outcomes and before/after snapshot references. DATA-20 covers automatic action-scoped deltas; existing ui_diff compares any compatible retained snapshots. Timeline and automatic wiring are still pending, not part of this recovery build. Neither a timeline nor a delta establishes causal attribution when the user/app also changes state.

## Installed checkpoint

Release build and signature passed; install completed with SHA-256 `2ff924fb96fddfe1451953c59b81af6ec808e195833a0ed2da8ce0df7832cdd3`. [Install metadata](../../artifacts/test-runs/20260920-ax-batch-recovery/install.json). User restart is pending. Simulator recording stopped cleanly; no UI input or play data changes in this iteration. `git diff --check` passed.

## Native acceptance addendum

After confirmed restart, iPad snapshot 506 reported two retries, zero recoveries and two AXSubrole -25200 errors. The fallback hypothesis did not resolve the provider failure. iPhone snapshot 508 had zero failures/retries and the expected Phone parity playbook. [Native evidence](../../artifacts/test-runs/20260920-ax-batch-recovery/native-after.json). No input was sent. Further diagnosis is required; retained uncertainty is correct but is not a recovery pass.
