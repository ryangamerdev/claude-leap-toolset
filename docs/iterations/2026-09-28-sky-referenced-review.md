# 2026-09-28 — Checkpoint 3 native pass; Sky reference for every issue so far

## Outcome and evidence

Native on 49a3213 (restarted, user hands-off): Edit play → `Save` `disabled` verified `passed`
(the lone disabled control is now visible); Cancel → text area `absent` `passed` in 4 s total; ids
stable across editor open/close (`…AXButton[Flashcards]#0` unchanged, no removed+added churn);
disabled inactive view collapsed to one line while Reset filters / Include Team Library / Notes stay
listed. New defect: the labelled-by switch and its title toggle rendered as the same `[11]` twice —
the key used the resolved label while the parent's ordinal used the element's own attributes, so two
siblings produced one key.

## Sky reference for each issue (user request: reference Sky first)

| Issue | How Sky handles it (evidence) | Leap choice |
|---|---|---|
| Missing/extra `a` in Simulator | Same symptom in Sky (user observation); Sky's factory brackets keys with flagsChanged (research/sky-keyboard-controller-trace.md) | Hardware-accurate per-modifier flagsChanged with modifier keycodes; minor glitches accepted |
| Rotated Simulator frames | Coordinate actions miss Simulator (`windowNotFoundAtPosition`); ~95 % of Sky clicks are by index (SKY-BEHAVIOR §5–6) | Same principle: AXPress by index/label; coordinates from rotated frames refused |
| Post-action settle | ~1 s + up to 5 s while the app changes; ≈5 s AX timeout (§5, parity table) | Same budget; never start a re-scan that cannot finish |
| Delta/result size | Text diff `~`/`+` lines, removed summarized by ID range (§3) | Summarized added/changed nodes; quality summary; counts for unobserved |
| One unreadable attribute blinds window | No completeness notion; renders what it reads (§3 grammar) | Node-scoped failures; blocking only for structure/transport |
| Unlabeled SwiftUI controls | Service references AXTitleUIElement, AXLabelUIElements, AXServesAsTitleForUIElements (Sky strings 1971/2021/2036) | Resolve title/label UI elements; keys use own attributes only |
| Duplicate label from labelled-by | Sky reads AXServesAsTitleForUIElements (usage not traced) | Open: consider suppressing title-serving elements |
| Long lists | Containers capped `(showing 0-100 of N)`; iOS shows only laid-out rows (§3, §6); service references AXVisibleChildren/AXVisibleColumns | Visible rows for tables/lists >60 with unread count; absence over unread rows = unknown |
| Disabled controls | Always rendered with `(disabled)` flag (§3) | Lone disabled shown; runs ≥5 collapsed with count+examples (token tradeoff; differs from Sky) |
| Element ids | Positional, reused; `~` may be another element (§4, Sky's weak spot) | Content-keyed stable ids (exceeds) |
| Custom actions | `Secondary Actions: Raise, Cancel, Edit filters` by name (§3) | Show/accept action names |
| No window | `noWindowsAvailable` error (§5 table) | Error names app and lists windows |
| Scoping without ids | No selector layer; agent regex-matched `Description: <label>` (§1) | `within` ancestor-label selector (Leap-only) |

## Changes

Keys use the element's own identifier/title/description/placeholder (labelled-by text is display and
matching only). AXLabelUIElements fallback. `within` selector (ancestor's own label) in ui_observe and
ui_perform, documented in tool schema and skill. AGENTS.md: reference Sky first for every issue.

## Validation and delivery

`swift test`: 61 tests, 0 failures (new: within scoping incl. labels containing `#`). Native checks of
this build pending restart.

## Remaining work

Native: single `[11]`/`[12]` Sideline elements; `within` selector on Coaching notes. Then (Sky first):
coordinate provenance strictness, observe step output, duplicate labels via AXServesAsTitleForUIElements.
