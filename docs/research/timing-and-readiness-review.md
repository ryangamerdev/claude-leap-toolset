# Timing and readiness review — 2026-09-20

User hypothesis: an immediate post-click observation can report failure before the application finishes. This is valid, and automatic readiness handling belongs inside Leap.

## Reference and current implementation

Sky's local reference node/sky/docs/skills/oai_sky_lib/macos/SKILL.md:112 states approximately one second after an action, with up to five additional seconds for loading/changing state. The CUA reference docs also say state/screenshot methods internally wait. This establishes the documented policy, not the exact algorithm in every extracted native implementation.

Leap Engine.swift normal state path waits until 0.6 seconds after lastActionAt, then checks fingerprints every 300 ms, requiring two matching observations without a progress/busy indicator, within an intended extra five-second settling budget. wait_for also polls every 300 ms, but directly walks the tree and does not use that normal settling path. verified_action uses wait_for for its before/after predicates and normal state afterwards. Different readiness rules can therefore produce different results within one tool response.

The wait deadline is checked after synchronous window resolution/tree acquisition. Individual AX work can overrun it; poll count would not solve that. AXTree.attrs falls back from a failed batch read to individual reads and skips unsuccessful attributes. The snapshot truncation bit tracks node budget, not all failed attribute/child reads. A sparse tree can therefore be incomplete without being marked truncated. Repeated empty/partial trees are not proof of readiness or absence.

## What the Save evidence establishes

In artifacts/test-runs/20260920-recording-checks/save-timeline.json, action result 179 occurred at monotonic 2303426.803; next recorded snapshot 195 arrived at 2303441.220 (about 14.4 seconds later) with nine nodes and no Edit play. Snapshot 201 arrived at 2303441.996 with 258 nodes including Edit play. Reopening confirmed mirrored-route persistence.

This proves the observations changed and the requested three-second wait was not a hard wall-clock bound. It does not isolate the time spent in each AX call, identify why the nine-node tree was sparse, or prove the app completed Save before that first read. Possible contributors include application transition, accessibility server delay, failed reads, and subscription/read contention. Add capture start/end and read-error metrics to distinguish them. A fixed sleep alone does not address all of these cases.

## Preferred next implementation

1. One readiness/observation coordinator for ordinary state and action expectations. Dispatch input once, then retry only observations.
2. A short default settling grace and a stable interval, with explicit outcome predicates taking precedence over generic stillness. Notification signals can wake checks early; bounded polling remains a fallback. Provide timeout and poll/settle overrides without requiring agents to tune them routinely.
3. One monotonic deadline covering window selection, reads and polling. Carry remaining budget into AX messaging and traversal; stop launching new work when exhausted. A Swift task timeout does not cancel a blocked synchronous AX call. Do not spawn unbounded replacement reads; isolate workers if needed and discard late results by generation.
4. Capture completeness explicitly: read failures, missing child reads, node cap, window identity, start/end times and stability. Missing from a partial observation means unknown, especially for disappearance assertions.
5. Distinguish expected state observed, unmet by deadline with adequate observations, and unable to determine because observation was incomplete/blocked. Preserve any later observation as later evidence, not a retroactive within-deadline pass.
6. Persist the check timeline and return one compact result. Retain the ambiguous-input no-replay guard; readiness retries never authorize a second click.

Acceptance: delayed successful transition, transient empty tree, stable-but-incomplete tree, long blocking AX read, normal fast action, genuinely unmet condition, user/window changes during polling. Keep fixture/tests in this repo and validate through native MCP after installation. This review changes documentation only; the installed insights build is unchanged and still awaits restart.
