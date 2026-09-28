# 2026-09-28 — Native desktop workflow pass and observation-quality fixes

## Outcome and evidence

User restarted onto d1f995e and was hands-off (full control authorized). Native MCP results:
- Gameday (desktop) session: blocking read failures 0 (was 1 on every read before d1f995e).
- End-to-end workflow through ui_perform, all verification `passed`: open editor (Edit play), set
  coaching notes via set_value (AX selection replacement, verified), delta showed Save/Revert/Undo
  becoming enabled, Save → editor gone, Edit play → notes value_equals the saved text (persisted),
  Cancel to leave the app neutral. ~5 s for save+reopen+verify in one call.
- Notes: 152 nodes, visible rows plus "[440 more rows off screen, not read]", complete, fast.
- Simulator (landscape iPad): guest elements tagged `[rotated]` with one explanatory line; click by
  label used AXPress and opened Playbook; set_value cleared the search field.

Gaps found natively (all general, not app-specific):
1. `get_app_state` under recording dropped every `[disabled]` line: this hid Save/Reset/Notes controls
   (a disabled Save is key state) along with an inactive SwiftUI tab kept alive in the tree.
2. Persistent AXDescription/AXIdentifier -25200 (SwiftUI TextEditor, unlabeled switch) made label-only
   absence checks `unknown` on every such screen after d1f995e (Edit play `absent` → unknown, 8 s poll).
3. Sibling ordinals used identifier ?? title only; SwiftUI labels live in AXDescription, so ids like
   `AXButton[Flashcards]#6` became `#10` when unrelated buttons appeared (removed+added noise).
4. Custom actions rendered as raw descriptors "Name:pin\nTarget:0x0\nSelector:(null)".
5. Legacy single-action results (~6 KB) embedded full before/after capture metadata; their delta was
   flagged incomplete on any advisory read failure.
6. ui_perform argument errors did not say which arguments are accepted (set_value takes `text`).

## Rationale and alternatives

Keep noise reduction but make it lossless in meaning: collapse runs (≥5) of disabled lines into one
summary with examples; keep lone disabled controls. Persistent description/identifier failures are
how several providers report "none" (Sky and the gameday UI-VERIFICATION script also treat such
elements as unlabeled); diagnostics still record them; title/value/state failures stay unknown.
Ordinal signature now uses the same label as the key. Results report outcome and state change; full
capture metadata remains in the store.

## Changes

compactObservation collapses disabled runs; walker ordinal label includes description/placeholder;
description/identifier failures no longer mark label unknown; AX.actionName for display and matching
(perform_action accepts the short name); interactionDelta quality summary {complete,nodes,…};
diff omits empty beforeValues/ordinals/geometry for added elements and uses blocking failures for
`incomplete`; ui_perform argument errors list unsupported and accepted keys.

## Validation and delivery

`swift test`: 60 tests, 0 failures (new ObservationTextTests: custom action names; disabled runs
collapse while lone disabled controls remain). Native results above are for d1f995e; these fixes need
restart verification. Personal Notes content was observed but is not recorded here (local store only).

## Remaining work

Native: disabled Save visible in editor before edit; Edit play absent → passed quickly; click result
size; Flashcards id stable across editor open/close. Review next: coordinate provenance strictness,
observe-step output (returns delta only, not matched items), duplicate labels from labelled-by, id
usability (agents cannot guess root ids; consider label-based ancestor selectors).

Installed 2026-09-28T21:28:57Z via `make install` from 49a3213. SHA256 `94742a142aa5b21c4798cb4f867eac9c162d070515846a6bf02ea58f97c386ca`. Signature verified; skills match; registration unchanged. Restart pending.
