# Lessons from gameday's ui-ax.swift (2026-09-28)

Source: docs/followup/2026-09-28-gameday-ui-ax-comparison.md (other agent). ui-ax.swift is a ~100-line
AX script: fresh walk per command, first label match with AXPress pressed in the same pass, raw AXError
mapped to exit codes (cannotComplete → 3 "uncertain: verify, never re-press"), 250 ms label-predicate waits,
and a raw `dump`. It is less safe than Leap (first match wins, no ambiguity/occlusion handling, no evidence,
no pointer path) but a few properties explain cases where it succeeded or settled app-vs-tool questions.

## How the methods combine in Leap

| Need | Method | Leap feature |
|---|---|---|
| Act on the control the agent means | Intent step: fresh observation, exact/unique selector, preconditions, expectations, evidence | `ui_perform` (unchanged contract) |
| Act on the *current* element object | Resolve again from a plain walk immediately before input (ui-ax's find-and-press; Sky validates element ids) | Quick read before every selector action; `native.refresh`; refuse if the target vanished |
| Know what the OS said | Pass through the raw AXError; `cannotComplete` = uncertain, may have applied (SwiftUI replaces controls mid-action; Sky's timeouts "had already applied") | `ax_result`, `dispatch: uncertain`, `side_effect_note`; expectation still evaluated; never re-press |
| Wait cheaply | Label/state predicate over a plain walk every 250 ms; one full observation for evidence at the end | `automationCheck` quick polling |
| Tell app bugs from tool bugs | Raw, unnormalized attributes, action names, parents | `ui_inspect` (read-only) |
| Label placeholder-only fields | title → description → placeholder | Already present (confirmed on the New playbook "Name" field) |

Not adopted: first-match-wins pressing, no evidence. Occlusion inference by AX hit-test was tried and
removed the same day: SwiftUI's hit-test reports hidden layers at visible controls (agent-retest entry).
