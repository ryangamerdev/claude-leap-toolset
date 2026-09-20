# 2026-09-20 — Native grouped evidence acceptance

## Outcome and evidence

After user-confirmed restart, installed build 444130a908e54dff63cb2a618a60bde37c75121fc33713da4334e98ecf8521db exposed all new tools. Native recording_sessions returned the original 11 sessions, 589 records, 40 interactions and 82 snapshots before binding. Binding migrated schema 1→2; subsequent read-only comparison against the local-only pre-migration backup found all 589 record tuples identical. quick_check returned ok.

Historical interaction deltas selected snapshots 563/572 and 575/582 (not precheck snapshots 561/573). Timeline paging with through=589 returned the remaining two interactions without empty IDs or newer records.

Native group E02D3027-C127-4760-A280-7E2FC74244C4, named Simulator grouped timeline and delta acceptance, contains Simulator capture E06BFE93-9927-4CD7-A3D5-0F0FA666ECEC and Gameday capture 5A361A0B-D335-468F-B813-0CAB3455B19F. iPad and iPhone are windows of the same Simulator app and share its capture. iPhone snapshot629 read Phone parity cleanly; Gameday snapshot664 was clean.

Two background verified_action calls toggled iPad field→information→field. Each returned exactly one acknowledged input, met postcheck and automatic structured delta. Interactions 0263CEAC-AC11-4F41-915F-43C9827DC1D3 and F269452B-31A7-463C-B903-F1035C5B02EF use brackets608/617 and620/627. Two advisory checkbox subrole failures remain; zero blocking failures. Prechecks were unknown, not proof of absence. No play content edited.

Ending the group closed two captures. Resuming within the same MCP process and rereading iPad created capture CCCEB510-006B-4398-997F-E0438116D368 (snapshot680) under the same group. Grouped timeline returned six nonempty interactions across three capture periods; session inventory pagination advanced from Simulator ordinal12 to Gameday ordinal13. Simulator recording stopped cleanly before handoff; logical group remains available for explicit resume.

## Rationale and alternatives

This validates retention, historical query boundaries, actual action-summary delivery and in-process group lifecycle. It does not establish resume across an MCP process restart; that is the next distinct case. Keep the same group ID and require a new capture epoch after restart rather than simulate uninterrupted observation.

Delta output is bounded but still noisy: role/ordinal-dependent AX keys produce added/removed entries for unchanged labels, and full before/after quality metadata repeats detail. No token-saving claim is justified from this pass. A future concise summary should retain full diagnostic retrieval and avoid merging ambiguous repeated controls based only on label.

## Changes

Acceptance documentation and skill status updated; no executable changes. DATA-20/21 have scoped native passes. DATA-22 is partial pending cross-process resume. Recorded noisy-delta follow-up without claiming stable identity is solved.

## Validation and delivery

[Native MCP responses](../../artifacts/test-runs/20260920-group-native/results.json) retain inventory, historical deltas, both action responses, grouped timeline and paged inventory. SQLite comparison is supplementary retention evidence, not substituted native acceptance. Source skills refreshed with scripts/install.py --skills-only and compared to Claude/Codex copies. No binary rebuild needed for documentation changes. Commit/push this checkpoint.

## Remaining work

Restart then bind_project, recording_group(action:resume,group_id:E02D3027-C127-4760-A280-7E2FC74244C4), observe iPad, verify a new capture and retained prior six grouped interactions. Then continue Simulator/Blender campaign. Full cross-epoch ui_diff remains restricted by design; task grouping alone does not establish node correspondence. Retained-earlier timeout and temporal checks remain separate gaps.
