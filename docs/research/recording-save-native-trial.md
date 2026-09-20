# Saved history and Gameday Save — 2026-09-20

Native tools on build `5cc05b575fd6e50a6eab872af2dd321dc943f66333e2672690cb9446d0d882fb`, after confirmed restart.

- Historical snapshot 9 returned Coaching notes ordinals 79 and 80. Cursor after 79 returned only 80. Corrected node retrieval and exclusive pagination passed; old-session history survived MCP restart.
- Recording session E905AA1C-9346-462B-91A5-3B98E057A853 attached native Gameday in the background.
- Edit play returned AX cannotComplete (-25204), but fresh evidence showed the editor. No coordinate fallback was sent. Selecting player 1 reproduced the same ambiguous reply with completed effect.
- Mirror route changed Original → Mirrored. verified_action retained the API error and independently reported its current-state check met. Save returned -25204 as well. No action was replayed.
- Save's 3-second check did not establish Edit play before its deadline; the subsequent state read did show the playbook. Reopening and selecting player 1 confirmed Mirrored persisted, with Undo disabled. Cancel then exited the unchanged editor. The task-owned trial play deliberately retains the mirrored route.
- The Save journal contains one intent and one result for that action, not a duplicate click. Source guard plus native error output supports no fallback; this is not an independent OS event-tap measurement.

## Gaps revealed and next increment

Expectation results were returned to the caller but not retained as queryable journal records. The new build adds expectation_result records for before/after verified_action checks, tied to the existing interaction. Each distinguishes met from not_established and preserves diagnostic text. It does not infer that an unmet check proves an action failed. Record failure before input stops dispatch; record failure afterwards reports possible prior input and prohibits automatic replay. Native verification is pending installation/restart.

The journal also exposes a latency limitation: the Save observation spanned approximately 14 seconds before returning a nine-node transitional tree, despite a 3-second wait budget. Final observation then contained 258 nodes and Edit play. Synchronous AX acquisition can overrun the polling budget; notification delivery arrived in a burst during that interval. Do not call this a strict wall-clock timeout or a controlled proof of callback delivery while blocked. This remains an explicit follow-up for REC-03; do not hide it by silently enlarging every timeout.

Evidence is under artifacts/test-runs/20260920-recording-checks/: native-results.json, native-evidence.db, save-timeline.json and build/install metadata. Native query correction, ambiguous-press recovery and mirrored-route persistence have scoped passes. Full DATA/REC requirements and fresh route replacement/visual geometry remain open.
