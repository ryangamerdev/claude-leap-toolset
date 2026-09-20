# Integrated native acceptance — 2026-09-20

Tested build c2775ef3377f90e7d7dc1459a3c9968fabd9795ed77c19078cd3747a7e4c8eb4 after confirmed restart, using native Leap tools.

## Passed scoped cases

- bind_project accepted this repository. Second structured read returned 258 Gameday nodes, zero read failures, no deadline exhaustion, approximately 137 ms acquisition. Button/enabled/frame-visible filters returned 44 matches and a bounded eight-item page with screen coordinates and action indices.
- Show field and reverse Show play information each dispatched once, met their postcondition and returned joined interaction results plus compact diffs. Both ran in the background; no explicit foreground activation or screenshot was needed. Before checks were unknown under the short precheck budget, reported honestly rather than claimed absent.
- Historical snapshot 370 still returned Show field after the live UI had transitioned away. Snapshot IDs remain tied to recorded content.
- A repo-local retained fixture was queried through native ui_to_text. Its 19,000-byte/16,000-character quoted, multiline Unicode value became a small leapAsset reference. Native leap_asset returned raw text and materialized a file under the fixture's recorded session. This establishes native retrieval behavior, not real-app acquisition of a huge field.
- recording_review overview for the action returned scoped counts, zero attention records, no raw trees, and a fixed through cursor.

## Failures fixed in the next candidate

1. First observation after binding failed with “Bind a project first” despite successful binding. New AppSession creation omitted autoRecord; only existing-session lookup attached it. Add autoRecord before returning a new session. The retry established the diagnosis but is not an acceptable final workflow.
2. ui_diff reported all unchanged screenFrame arrays as changed (281 total changes). Source compared debug string representations of parsed values. Replace with canonical JSON value comparison. Independent inspection of retained snapshots 370/380 found 247 shared nodes, zero changed frames, 23 added nodes and 11 removed nodes. A regression fixture now includes unchanged geometry, and all four EvidenceTests pass.

## Next restart

- bind_project then the very first ui_to_text(Gameday) must succeed without a retry.
- ui_diff(before:370,after_snapshot:380) should have 34 changes (23 added/11 removed), not spurious screenFrame changes. Check paginated output too.
- Continue structured subtree/depth/field checks and grouped review pagination; then Gameday Save timing and controlled partial/delayed observations before Simulator/Blender. No broad parity/certification claim yet.

Gameday was restored to information view. No play data changed during these tests. Recorder DD5F7E9C-3E0E-4B51-8AF5-3489195B96DE stopped cleanly. Evidence, build logs and rollback identity live in artifacts/test-runs/20260920-integrated-fixes.

## Postrestart verification

The two corrections and additional pagination/subtree cases passed native testing. See [iteration results](../iterations/2026-09-20-postrestart.md). This supersedes the pending status above, retaining the original failure history.
