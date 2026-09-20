# 2026-09-20 — Native query acceptance and actionable capture diagnostics

## Outcome and evidence

Native MCP testing followed the user's confirmed restart of build
`42b0158bde583a211f1c6e7cf9334a1e5bb58bf8dcc58f51592fa5713f87658d`.
The objective was to close the two installed fixes without using a stdio harness as acceptance,
then exercise query depth/pagination and begin the Simulator comparison.

[Retained native results](../../artifacts/test-runs/20260920-postrestart/native-results.json):

- First Gameday ui_to_text after bind_project succeeded without retry: snapshot 425,
  258 nodes, zero read failures, no deadline/cap exhaustion, approximately 847 ms.
- Native ui_diff(370,380) returned 34 unique changes over four pages: 23 added, 11 removed,
  zero changed nodes. The identical-frame false positives are resolved in this scoped case.
- Grouped events paginated over eight pages at through=425: 39 groups covering all 101
  notification records, matching the overview count. No cursor stalled.
- The first scroll subtree returned one node at relative depth 0, 53 at depth 1, and 56
  at depth 2. Returned depth values remain absolute rendered-tree depth; the filter is relative.
- Button pagination returned all 139 matches with 139 unique keys across seven pages.
- Both background Show field / Show play information verified actions dispatched once and
  met their postconditions. Prechecks were unknown, not falsely reported absent. Gameday
  was restored to information view; no play data was edited. Recording stopped cleanly.

The Sky-backed native controller (cua_repl) discovered iPad Air 11-inch (M2) – iOS 18.0,
opened Window > iPhone 16 – iOS 18.0, and returned to the iPad. It observed Freshman 2026
on the iPad and Phone parity on the iPhone. Leap then observed those same explicit window
identities and playbooks, and a read without window retained the selected iPhone even
though the reference controller had restored the iPad. Leap's richer pinning does not need
to reproduce the reference's menu navigation mechanics to achieve this read-only outcome.
No Simulator app edits, keyboard routing or gesture passes are claimed.

[Simulator results](../../artifacts/test-runs/20260920-postrestart/simulator-discovery.json)
retain two iPad reads with 105 nodes and two read failures each (about 1.03 and 0.90 seconds).
The iPhone reads had 31 nodes and zero failures. The iPad identity query succeeded, but its
observations are incomplete. Raw database records are local-only in the ignored `.leap` store.

## Rationale and alternatives

The iPad exposed a concrete observability gap: a failure count says not to trust absence,
but cannot explain which read failed. Repeating clicks, hiding the errors, globally increasing
timeouts, or requiring screenshots would not diagnose this safely. The acquisition policy
must remain conservative until the failure is understood.

Retain up to eight failed-read samples in the same snapshot: attribute, AX error code/name,
and ephemeral element hash. The hash correlates reads within an observation; it is not a
stable element identity or an action target. Count all failures and explicitly report how
many samples were omitted. This provides useful debugging evidence without unbounded output
or extra AX queries that could themselves block or recursively generate failures.

## Changes

AXReadBudget accumulates bounded failure details alongside the existing count. AX.attr,
batch per-attribute errors, and single-attribute fallback attach attribute/element context.
AXWindowSnapshot carries the details and omission count; recorded snapshot metadata exposes
them through ui_to_text. Optional unsupported/no-value attributes retain their existing
non-failure treatment. No values are copied into diagnostic samples. No action routing,
retry policy, expectation completeness rule or MCP registration changes.

This diagnoses the iPad failure; it does not yet resolve or claim a root cause for it.
Tracking documents now distinguish scoped native passes from remaining cases instead of
leaving obsolete 'pending restart' claims in the current handoff.

## Validation and delivery

Native results above apply to the pre-change installed build. The diagnostics increment
requires a release build/signature verification and installation; install.json in this
iteration's artifact directory records its identity. Native diagnostic verification awaits
a new user restart. Build logs and rollback bundles remain local and ignored. No commit
or push is performed in this iteration.

## Remaining work

After restart bind the project, read the iPad via ui_to_text and inspect readFailureDetails.
Use the attribute/error evidence to decide whether the cause is transient, optional-attribute
classification, timeout, or invalid element; do not discard errors simply to pass a check.
Then continue Simulator control/keyboard/gesture comparisons and paired Blender. Controlled
delayed/partial observation, remaining Gameday route replacement and strict OS-call cancellation
are still open; this scoped validation does not certify full parity.

## Delivery and user-direction addendum

Release build and code-signature verification passed. Installed candidate SHA-256:
`7f13fab06b2a1c51b66dcf68265776469fa9e47531b44382998a40ce8f193c07`.
[Install metadata](../../artifacts/test-runs/20260920-postrestart/install.json) retains the local
rollback path. Native diagnostics have not yet been exercised. No broad test suite rerun:
this change adds bounded diagnostic metadata; the installed MCP is the requested acceptance path.

The user proposed automatic deduplicated before/after action deltas during this iteration.
The existing rendered-state diff and historical ui_diff implement parts of this, but the
last displayed baseline is not guaranteed to be the immediate pre-action state. DATA-20
now tracks explicit interaction-scoped structured deltas, bounded output/continuation,
full retained snapshots and truthful partial-capture semantics. This contract is recorded,
not claimed implemented in the diagnostic build. Avoid presenting unrelated concurrent
UI changes as effects caused by the action.
