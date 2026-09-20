# 2026-09-20 — Sky comparison distinguishes input from observation failure

## Outcome and evidence

User asked whether Sky handles the same iPad interaction. Through the Sky-backed cua_repl,
read iPad Air 11-inch (M2), clicked Show play information, observed coaching notes and
Show field, clicked Show field, and observed restored Football field/Show play information.
Sky returned normal diffs without acquisition warnings. No play data was edited.

Replayed the two semantic clicks through native Leap on installed build
2ff924fb96fddfe1451953c59b81af6ec808e195833a0ed2da8ce0df7832cdd3. Forward click returned
AX success; subsequent fresh snapshot 538 found Show field, proving the requested transition.
Reverse click returned AX success. Its immediate observation was partial (snapshot 544:
41 nodes, deadline exceeded, truncated); it could not verify restoration. A fresh Sky read
reported no change from Sky's original field baseline, independently verifying restoration.
[Leap responses](../../artifacts/test-runs/20260920-sky-subrole/leap-results.json).
Recorder 8277E86D-9D6B-4D11-BF26-4CDA6AE4726D stopped cleanly. Raw database remains local-only.

## Rationale and reference findings

The observed failure is not inability to click the iPad. Both controllers perform this
reversible transition. Leap exposes persistent failures reading two AXSubrole attributes,
then its global completeness gate prevents settling or establishing any expectation.
The final short-budget capture can be smaller than earlier usable captures. Its message
claims a 1500-element truncation even when deadline exhaustion produced a small tree;
these causes should be distinguished.

The local extracted Sky service disassembly shows AXUIElementCopyMultipleAttributeValues
at 0x1006e783c and single-attribute copying at 0x1006e3260. The inspected batch wrapper branches
on returned pointer and overall status around 0x1006e7910–0x1006e7928; it does not establish
how its higher-level renderer treats these exact per-field AXSubrole failures. There is no
original Swift source here. Live Sky observation succeeds, but claiming Sky recovers or
explicitly ignores these exact errors would exceed the evidence. The extracted version
also is not proven identical to the running controller.

Leap's relevant gates are in Engine.swift: state stability requires zero readFailures and
expectation checks reject any readFailures before evaluating the condition. Consequently
unrelated optional metadata failures can make an otherwise observable predicate unknown.

## Proposed correction and tradeoffs

Preserve field-specific uncertainty instead of treating every error as whole-tree loss.
Determine affected roles/keys and classify missing children/identity/selector/state separately
from missing optional descriptive metadata. Positive evidence and absence need different
coverage requirements. Subrole still matters for secure-field handling and particular
selectors, so a blanket 'ignore subrole errors' rule is not justified. Keep errors queryable,
avoid repetitive retries known not to work, and preserve the best usable capture on timeout
with its time/quality rather than silently replacing it with a sparse final scan.

## Validation and delivery

This is a paired live test/research iteration; no source changes, build or installation.
Document observed passes and gaps without promoting broad Simulator parity. No restart needed.

## Remaining work

Implement predicate/attribute-aware coverage and truthful settling/truncation messages, then
repeat this same two-click comparison. Continue the requested action-delta and timeline work.
