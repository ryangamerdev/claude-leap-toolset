# Gameday coach workflow — Sky baseline

Date: 2026-09-19 (America/Phoenix). Target: running native macOS Gameday, team Higley High School Knights · Freshman, playbook Freshman 2026. UI-only trial through `mcp__cua_repl` / Sky. No database or app-source shortcuts. Changes authorized by the user. Companion comparison: `trial-leap.details.md`.

## Scenario and reproducibility

Coach on the sideline: narrow the call sheet, inspect a play and its assignments, zoom, advance, switch to third down, recover from an empty result. At halftime: create a new 2X2 SLOTS passing play from library routes, add coaching notes, save, and find it in Sideline.

The baseline had 86 plays. Sky adds one named `TRIAL SKY - Halftime Slant Flat`; Leap must use `TRIAL LEAP - Halftime Slant Flat` to avoid overwriting it. Counts may consequently differ by one. Use current AX element IDs rather than copying numeric IDs between tools or after replaced views. Compare semantic actions in this order.

## Ordered trial

| Step | Action | Sky result / evidence |
|---|---|---|
| 01 | In Sideline, Reset filters | 86 matching plays; picker opened. |
| 02 | Click PASS, then defense front 3–4 | 13 matching plays; 3–4 explicitly selected. PASS did not remain marked selected in returned AX; do not treat passing-only filtering as proven. Both clicks used indices from the preceding tree; repeat with an observation after each in Leap. |
| 03 | Set Search plays to `OSCAR` | Field read-back OSCAR; 2 matching plays. |
| 04 | Select `ANY OSCAR BRADY · 3-4` | Header matches; active sequence 1 of 2; 7 offense / 7 defense. |
| 05 | Show play information | No coaching notes; assignments include LT Block BS B gap, LG/C ACE to PSILB, RG/RT DEUCE to PSOLB, T T path 12. |
| 06 | Show field; inspect screenshot | Diagram renders routes/blocking and defensive front. A stale old zoom index was rejected before any action; refreshed AX supplied the new zoom control. |
| 07 | Zoom to 150 percent, then Reset field view | AX changes to Reset field view / Zoom active, then back to Default view. |
| 08 | Next play | ANY OSCAR VICK · 3-4; sequence 2 of 2. |
| 09 | 3rd down shortcut | Search cleared and list showed No matching plays / 0 matching plays. This is an observed data/filter outcome, not established as a bug. |
| 10 | Clear filters, then Playbook mode | Full 86-play list recovered; mode header PLAYBOOK. Top navigation Playbook was an additional no-op, unnecessary for replay. |
| 11 | Select ANY OSCAR BRADY · 3-4; New play | Editor opens New Play 1, default Formation 2X2 SLOTS, Any defense, PASS selected, 11 O / 0 D. |
| 12 | Set title, coaching notes, add tag | Title `TRIAL SKY - Halftime Slant Flat`; notes below; tag HALFTIME-TRIAL added. All text fields read back correctly. |
| 13 | Select receiver `1`; Find a route = `2 Step Slant` | Search narrows library to 2 Step Slant and 2 Step Slant (Quick). |
| 14 | Assign exact `2 Step Slant`; set player note | Edit selected route and Mirror route become enabled. Player note reads back. |
| 15 | Select receiver `2`; Find a route = `Flat` | Candidates include 3 Step Slant (Flat), Block-Flat, exact Flat, Flat to BDRY, Motion, Flat. |
| 16 | Assign exact `Flat`; set player note | Route controls enabled; note reads back. |
| 17 | Mirror route, inspect screenshot, mirror again | AX Original → Mirrored → Original. Screenshot displays both receiver paths; selected Flat library card visible. Restored Original before saving. |
| 18 | Save | Editor closed after ~11 seconds for combined mirror/save/observation call. Returned to the previous play rather than automatically selecting the new one. |
| 19 | Reset filters; Search plays = `TRIAL SKY` | Exactly 1 matching play, with the saved title. |
| 20 | Select trial play; enter Sideline | Header SIDELINE TRIAL SKY - Halftime Slant Flat; active sequence 1 of 1. |
| 21 | Show play information | Saved coaching notes and both player notes displayed. Verified persistence through leaving editor and reopening, not through app relaunch. |

Coaching notes: `Halftime adjustment: attack the soft flat. Read the flat defender; throw the slant if he widens. Trial play for UI testing.`

Receiver 1 note: `Two hard steps, win inside; eyes to QB.`

Receiver 2 note: `Widen quickly to the flat; be ready on rhythm.`

## What worked

- Native AX names covered filtering, navigation, player selection, route assignment, mirroring, text entry, and saving. No coordinate clicks were necessary.
- `setValue` correctly updated SwiftUI fields and the multiline coaching-notes editor.
- AX diffs made ordinary changes concise; screenshots were needed only to inspect the actual field geometry.
- Saved play and notes were verified from the coach-facing Sideline UI, rather than inferred from a successful Save click.

## Friction and interpretation

1. **AX noise from hidden tabs.** The initial tree included hundreds of disabled Route library/Formations controls. Zoom caused large diffs recreating those hidden controls even though only the field zoom changed. App AX exposure affects both backends; the trial often filtered disabled lines from displayed Sky text to reduce noise. Full state remained available in the tool result/REPL.
2. **Element IDs need a new observation after view changes.** After switching information back to field, attempted zoom ID 438 was invalid. Sky rejected it; refreshed state provided ID 464. This was an agent sequencing error and a successful safety rejection, not a failed zoom implementation.
3. **PASS filter not proven.** It lacked selected state after the grouped PASS/3–4 operation. The resulting OSCAR example carries blocking/running assignments, so do not call it a validated passing-only result.
4. **Third-down empty result.** A real coach needs a clear recovery action; Clear filters worked. We did not establish whether the empty list reflected missing tags or incorrect app filtering.
5. **Save does not select the new play.** The old play remained active. Explicit search found the new play and verified saving succeeded.
6. **Route selection confirmation is partly visual.** AX enables Edit selected route but does not mark the assigned library card selected. The screenshot shows the selected card. A textual assignment name in the player inspector would improve both agents' verification.
7. **Defense display inconsistency.** Editor showed Any defense / 0 D; reopened viewer showed Any defense / 7 D (likely retained scout overlay). Treat as an app-state observation requiring product clarification, not a Sky failure.

## Scope limits

This trial did not grade football strategy, route-library geometry correctness, touch-device behavior, destructive actions, or persistence across Gameday restart. No existing play was edited or deleted. The labeled trial play remains in the playbook.

## Follow-up from Leap replay

Leap observed PASS selected immediately after clicking it, then unselected immediately after choosing defense front 3–4, with 13 results. This confirms the same filter outcome with separate observations; the earlier grouped Sky call is not needed to explain it. Leap subsequently lost the entire Sideline AX subtree after zoom because of Leap's hit-test pruning; see the companion report and restart checkpoint.

The Leap replay subsequently completed all remaining steps after removing the faulty pruning. It saved and reopened `TRIAL LEAP - Halftime Slant Flat`, verifying the same notes and route workflow. The user manually cleared filters during the Leap recovery step; this is documented rather than attributed to the tool.

## Dedicated scroll comparison

See [feature scroll trial](trial-scroll-details.md). Sky's filter-panel down/down/up/up one-page sequence moved normalized scrollbar 0 → 0.7297 → 1 → 0.2703 → 0. This directly outperformed Leap's pre-fix wheel-only scroll, which left it at 0.
