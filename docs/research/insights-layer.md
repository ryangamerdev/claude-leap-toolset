# Insights layer — 2026-09-20

## Product contract

Leap is an action and evidence service. Agents should request an outcome, declare what would establish it, and receive the result with relevant evidence and useful next queries. Storage, notification subscriptions and raw payload parsing are implementation details. Primitive tools remain useful escape hatches; they are not the only abstraction.

References inspected: Runner mcp/src/index.ts runner_status and runner_section (failure-proportional summaries, independent cursors, concrete next calls); Tracer mcp/src/index.ts tracer_summary and tracer_review (overview, counts, paginated facts, drill-down). We adopt those patterns without pretending a UI notification stream is complete or causal.

## Implemented this increment

- recording_review: overview, actions, issues, events. Filter by session or interaction; omit project while exactly one project is actively recording. Historical use without an active binding still accepts an explicit project.
- Whole-scope counts and attention count remain visible even when the detail page is short. Attention includes action API errors, unmet AFTER checks, capture gaps, coverage notices and failed subscriptions. An unmet BEFORE check is expected for many successful transitions and is not counted as a failed postcondition.
- Overview and issues return attention records; actions returns intents, results and checks with stable evidence references. Events groups by session, notification and ephemeral element hash, preserving count and first/last receipt. Distinct input attempts are never deduplicated.
- A transaction fixes each initial read. The returned through boundary can be supplied on subsequent pages; after is exclusive. Groups paginate by their first sequence within that fixed scope. Later records are intentionally outside that review, not silently lost.
- Page size at most 50, projected detail excerpts at most 400 characters, with roughly 10 KB item budget plus counts/metadata. Raw snapshots never appear in review output. Counts cover selected history rather than only the page. Summary absence does not prove no uncaptured event occurred.
- recording_nodes(outline:true) exposes role, label, depth, key and basic state without values, geometry or actions. Existing full-node retrieval remains available.
- A newly observed expectation target no longer prints a fictional actionable index [0]; use the index in returned state.

## Validation

Native installed prior build 08a19416cac19a3dd390c2ca95395657218808d0b1c17156d90ef9773ef7ee29 passed two Gameday transitions: Show field → Show play information, then reverse. Native queries retrieved two before/not_established and two after/met verdicts. Session A16C3242-997E-4E00-946D-F07E234DF73F is stopped cleanly. Gameday remains in information view; no play data changed in these transitions.

Evidence/scripts: artifacts/test-runs/20260920-insights. SQL support check paginated six event groups representing seven recorded notifications without skips or duplicates. This does not replace native acceptance of the new review tool after restart.

After restart: recording_review with explicit project and that historical session; inspect overview and actions, events with limit 1/through continuation, and snapshot 295 outline. Review the prior uncertain Save interaction CF86E21F-70C0-4005-945B-78D6AC436E92 to ensure error evidence stays visible. Then continue timeout/observer foundation work and the app campaign.

## Remaining scope

This is not the complete insights contract. Still needed: snapshot comparisons, semantic role/subtree/field selectors, chunked large-value retrieval, directly executable structured next-call arguments, automatic relevance-based live-state response budgets, compound outcome workflows, temporal assertions, and stricter AX acquisition deadlines. Current actions view preserves separate intent/result/check records rather than joining them into a complete action narrative. There is no automatic attachment outside explicit recording_start. Tree depth is retained but explicit parent links are not yet present. Keep these gaps visible in FEATURES and PLAN rather than claiming full parity.
