# 2026-09-28 — Node-scoped read failures, labelled-by resolution, visible rows

## Outcome and evidence

Native (installed be4609c, restarted): on Gameday Playbook one unlabeled SwiftUI switch fails
`AXDescription` with -25200 on every read. Leap classified it as blocking, so every observation of
that screen was incomplete and `ui_perform` refused all targeting ("Selector missing/ambiguous or
observation incomplete; no input sent" when pressing "Route library"). The failure is general, not
Gameday-specific: Finder produced 83 such per-node failures (all blocking under the old allow-list).

Dev-build harness (background AXPress/reads only, separate git project to avoid the loaded server's
writer lock; the user was working on the machine, so no foreground or keyboard input was sent):
- Gameday: press Route library → expect "Edit routes" passed; press Playbook → deliberately missing
  label now `failed` (was `unknown`/refused).
- Observation cost (snapshot records): Notes 3.0 s truncated at 416 nodes → 0.05 s complete, 152
  nodes; Finder 1.89 s/1010 nodes → 0.29 s/367 nodes. A raw walk of all 3,579 Notes nodes takes 34 s.
- Edge exposed no AX windows; the old error waited 6 s and said "selected window unavailable".

## Rationale and alternatives

The advisory allow-list (role × attribute pairs added one field failure at a time) is part of the
09-20 churn and cannot generalize to arbitrary apps. Principle instead: a provider failure on an
element's own label/value/state/frame is node-scoped (the field is reported unavailable, selectors that
depend on it become uncertain, verdicts never judge a failed field); role/children and transport
failures stay blocking because they can hide structure. The failing switch exposes AXTitleUIElement,
the standard labelled-by relation that screen readers use; resolving it gives an exact label instead of
uncertainty. For long lists, Sky's service also references AXVisibleChildren/AXVisibleColumns; reading
visible rows with an explicit unread count keeps observation fast and honest. Absence/count verdicts
over unread rows are `unknown`; presence and targeting of visible rows remain exact.

## Changes

- AX.advisoryFailure: any element-own attribute (subrole/title/description/identifier/placeholder/
  value/enabled/focused/selected/position/size) with kAXErrorFailure is node-scoped for every role;
  recorded per element → unavailableFields label/value/enabled/selected/focused/frame/identifier.
- Verdicts return `unknown` when the judged field (enabled/selected/value) was unreadable.
- Walker: label from AXTitleUIElement when title and description are absent.
- Walker: tables/outlines/lists/browsers/grids with >60 children read visible rows (non-row children
  kept); `omittedChildren` on the node, rendered "[N more rows off screen, not read]"; exists-failed/
  absent/count over unread rows → `unknown` (scoped by selector root).
- Walker reads each child's attribute batch once (was: pre-read for ordinals, then re-read).
- ui_perform selector errors distinguish ambiguous (lists matches), incomplete, unreadable-field
  ambiguity, and not found.
- Missing window error names the app and lists windows / explains no accessible window.

## Validation and delivery

`swift test`: 58 tests, 0 failures (new: node-scoped vs blocking classification, per-element
recording, failed state field never judged, unread rows block absence not presence). Harness results
above. Native restart verification pending for this checkpoint.

## Remaining work

Native: Gameday Playbook targeting and failed-vs-unknown verdicts; Notes/Finder observe + a scoped
action; confirm row counts render sensibly. Next review items: coordinate provenance requires the entire
prior node list to be byte-identical (coordinates unusable on any changing screen); result size of
deltas (~3 KB per step); settle/fingerprint behavior on continuously changing screens.
