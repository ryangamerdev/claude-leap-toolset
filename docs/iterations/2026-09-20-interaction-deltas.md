# 2026-09-20 — Native quality pass and timestamped interaction deltas

## Outcome and evidence

After confirmed restart of a0ec8c9ead9dbd0315f9e212c3504a335127604745be9143a119586e101b2678,
iPad snapshot 560 identified both AXSubrole errors as AXCheckBox metadata: two advisory,
zero blocking failures, 105 nodes, no deadline/truncation. Both native verified_action view
toggles returned met postconditions and settled responses. The iPad was restored to field
view with no play edits. iPhone snapshot 584 identified Phone parity, 31 nodes and zero failures.
Prechecks remained unknown under their short budget; no claim of prior absence is made.
[Native evidence](../../artifacts/test-runs/20260920-field-quality/native-results.json).
Recording stopped cleanly. Raw database remains local-only. Retained-earlier timeout behavior
still needs its own controlled native case; these passes do not cover that branch.

## Rationale and alternatives

The user asked for deltas instead of repeated whole trees and a timestamped interaction list.
Existing ui_diff compared chosen snapshots but required manual discovery; ordinary rendered
diffs used the last displayed baseline rather than input boundaries. Reuse immutable records
and record order to choose the last observation before the first intent and the last observation
after the final intent within the same interaction. Never borrow another interaction's baseline.
Missing observations remain unavailable; incompatible window/session comparisons preserve IDs
and report the reason instead of fabricating changes. Changes remain observational, not causal.

## Changes

- interaction_timeline discovers recorded interactions with timestamps, input counts, snapshot
  references, bounded pages and a fixed through boundary. Last timestamp is not completion.
- interaction_delta selects the bracketed observations and returns a ten-change/4 KB item
  budget, quality metadata, baseline IDs and ui_diff continuation. Timeline first/last snapshot
  references include prechecks and must not be mistaken for input brackets.
- Successful recorded single-action responses with default then_state return joined outcomes
  and a structured observation/delta object instead of repeating the entire rendered tree.
  Unrecorded operations, explicit then_state:false, full errors and batches retain their paths.
  Failed summary construction falls back to the original response; input is never retried.
- ui_diff adds beforeValues/afterValues for changed fields, shortening long text previews.
  Full captured fields remain retrievable through ui_to_text/leap_asset. Unchanged controls
  are omitted. Partial captures continue to be labeled incomplete, including advisory metadata.
- Source skill documents current tools and limits; installed copies refreshed during install.

## Validation and delivery

Focused EvidenceTests add an interaction with an earlier precheck, a later true pre-input
snapshot, action and post snapshot: the delta must choose 3/5, not 1/5. Missing-post evidence
is unavailable. Timeline pagination and frozen through boundary exclude later records.
Existing asset/diff/uncertainty cases run with this test class. These are supporting code tests;
new tool definitions and automatic responses require native acceptance after restart.

Build/install metadata and tests are retained under artifacts/test-runs/20260920-interaction-deltas.
The first release compile caught a throwing nil-coalescing expression; corrected before install.
No new native pass is claimed for the new tools. Preserve the original failed build log locally.

## Remaining work

After restart: inspect new schemas; interaction_timeline(session_id for the prior iPad session)
then interaction_delta on 2ED5EA8E-0C89-4A74-92F8-932D6B328A7C and
E0224AF5-A319-4CB9-B591-3B1B48DC4B03. Check chosen snapshot IDs and pagination.
Perform a reversible view toggle and confirm one input, expected outcome and bounded delta
without full-tree duplication; restore. Check an error/unrecorded path retains essential evidence.
Continue Simulator/Blender campaign. A timeline shows only recorded intervals, not all app history.

## Delivery result

Five EvidenceTests passed with the configured Swift toolchain. Final release build/signature passed; installed SHA-256 `beb4b0b373f57b352c08f9cca50df423d35178c26853bbba28749239eb317e73`. Both skill copies match source. [Install identity](../../artifacts/test-runs/20260920-interaction-deltas/install.json). Native tool acceptance awaits restart.
