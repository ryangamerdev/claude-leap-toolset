# 2026-09-28 — Checkpoint 4 native pass; coordinate provenance, observe items, compact deltas

## Outcome and evidence

Native on 26cab3f (restarted; host still showed the cached ui_observe description, but the installed
binary contains the new text and the server started after install):
- Gameday Sideline toggle/switch now distinct: index 11 `AXCheckBox[Sideline]#0`, index 12
  `AXCheckBox[]#0` (labelled-by label "Sideline" for display/matching).
- `within`: Edit play → `{role:AXTextArea, within:"Coaching notes"}` exists `passed`; assert
  `within:"Player notes"` absent `passed`; Cancel → text area absent `passed`.
- TextEdit (general app): set_value replacement verified; foreground type_text append exact; menu bar
  Format opened with items in the delta; Escape closed it.
- Operator error: the TextEdit test used the user's existing unsaved "Untitled 7" document and
  replaced its text. The delta retained the full prior value; it was restored with set_value and
  `value_equals` verified the original text. Undo history now contains the test edits. Rule going
  forward: test non-test apps only in new documents/windows created for the test.

## Sky reference

- Coordinates: Sky `click([x,y])` converts screenshot points to global points with no content-equality
  provenance; its failure mode is `windowNotFoundAtPosition` (SKY-BEHAVIOR §5). Leap required the whole
  prior node list to be byte-identical, so any changing screen made coordinates unusable. Leap now keeps
  the geometric checks (same window, bounds, orientation, coordinate space; point inside bounds) and
  drops content equality; expectations judge the outcome.
- Observe: Sky returns the tree/diff text on every `getAXState`. Leap's `observe` step returned only a
  delta; it now returns `matched` and up to 20 matched `items`.
- Delta size: Sky diff lines are `+ 153 button Cancel`. Leap delta summaries now carry index/role/label/
  value plus only non-default state (disabled/selected/focused/offscreen); frames stay in snapshots.

## Validation and delivery

`swift test`: 61 tests, 0 failures. Native verification of these three changes pending restart.

## Remaining work

Native: observe items; delta size on Gameday navigation; coordinate click from a snapshot on a changing
screen. Open (Sky first): duplicate labels via AXServesAsTitleForUIElements; Simulator iPad/iPhone
play creation/save/reopen; Blender gate.
