# Recording v1 native MCP trial — 2026-09-20

Tested installed SHA `d6b28927cb83f7c76c1f314afaa5a6dd5ac4fb832e1da2155f8de4ef1ffcb45d` after the user confirmed restart. All UI actions and history queries used native `leap` tools. No screenshots were needed.

## Observed results

- recording_start attached Gameday, captured 258 nodes, returned session F32376AA-772C-4A01-97C8-B2679EFD3240 and snapshot 9. Git check-ignore confirmed .leap/leap.db is excluded.
- Show field dispatched once. My expected label was mistakenly “Show information”; the actual label was “Show play information”. verified_action correctly returned failed expectation alongside successful dispatch and a fresh diff. This is a useful negative case, not an input failure. No retry occurred.
- Show play information reversed the transition. verified_action reported Show field absent before, present after (161 ms), and returned the complete diff versus state 2. Internal polling did not consume this observed baseline.
- recording_query returned AX layout/activation notification envelopes and the specific action_result by interaction. These are received events, not proof of causal origin or a transient-value capture test.
- recording_nodes(snapshot:9,contains:"Coaching notes") incorrectly returned zero nodes. A second value query also failed. Direct inspection confirmed both records existed in the saved snapshot.
- recording_stop then recording_start succeeded immediately with a new session E526DB07-E601-4B14-B917-CC975E2978D1, snapshot 64. Historical action data was retained.
- Gameday changed from background to frontmost during the first action interval and later returned to background. An activation notification records timing but does not establish whether user activity or Leap caused it. Do not claim focus preservation from this trial.

## Fix and validation boundary

SQLite JSON node ordinal is an expression without column affinity. Comparing that INTEGER expression to the TEXT-bound cursor made every row fail the comparison. Cast the cursor to INTEGER explicitly. A focused SQL regression against a backup of the actual native recording reproduces the old empty result and returns ordinals 79/80 after the fix; an exclusive cursor of 79 returns only 80. This is supporting SQL evidence, not a native MCP pass of the corrected build.

Evidence: artifacts/test-runs/20260920-recording-query-fix/native-results.json, native-evidence.db, check-query.py and query-regression.json. Build/install identity is in that directory. Next restart: query historical snapshot 9 through recording_nodes, test pagination, then continue Save and transient-event verification. No broad row is certified by these narrow cases.

## Agent-facing direction

The agent should ask for state, act, declare expected outcomes, and retrieve relevant history. SQLite, subscriptions, storage layout and queue mechanics belong behind the MCP interface. Bind a project once when necessary; use session/evidence handles thereafter rather than repeating paths and storage explanations. Keep technical capture limitations available as concise coverage metadata. Automatic attachment after binding and simpler continuation queries remain planned, not implemented by this pagination fix.
