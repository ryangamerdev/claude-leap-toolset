# How gameday's `ui-ax.swift` works, and what Leap might borrow (2026-09-28)

During the Gameday runs I used a roughly 100-line helper, `~/src/gameday/scripts/ui-ax.swift`, alongside Leap. It is far less capable than Leap, but in a few cases it succeeded where Leap didn't, or it settled whether a problem was Leap's or the app's. This note explains the mechanics so you can judge which ideas are worth adopting. It is not a proposal to copy it wholesale.

## What it does
It is a single-file Swift script run with `swift scripts/ui-ax.swift APP WINDOW <command>`. It uses only public `AXUIElement` APIs: no snapshots, no evidence store, no pointer events.

- **Target:** the app is found by `localizedName` or executable name; the window by title substring (`Gameday`, `iPad Air`, `iPhone 16`). It works for Simulator guest apps because Simulator exposes the guest tree under its window.
- **Label:** the first non-empty value of `AXDescription`, `AXTitle`, `AXValue`, `AXPlaceholderValue`, `AXIdentifier`. SwiftUI puts `.accessibilityLabel` and button titles in `AXDescription`.
- **Walk:** a plain recursive `AXChildren` walk from the window, run fresh on every command.
- **`press LABEL`:** in one walk, take the first element whose label equals LABEL and that advertises `kAXPressAction`, and call `AXUIElementPerformAction` on it **immediately, in the same pass**. The raw `AXError` maps to an exit status:
  - `.success` → 0.
  - `.cannotComplete` → **3, meaning "uncertain: verify the state, never re-press"**.
  - Anything else → 1.
- **`wait` / `wait-absent TEXT [s]`:** a cheap walk every 250 ms that checks only whether any label contains TEXT. There's no snapshot and no delta.
- **`dump [ROLE] [TEXT]`:** prints `role<TAB>label`. When a role is given, unlabelled matches are included, for example `dump AXSheet`.
- **`wid`:** the CGWindowID for `screencapture -l`.

## Where it behaved differently from Leap
| Situation | Leap | ui-ax |
| --- | --- | --- |
| Mac Playbooks sheet → "New playbook" | `pressed [749] via accessibility`, no effect; a foreground pointer click also no effect | Same element pressed about 30 s later: the alert opened at once |
| iPad Save that closes the editor | Reported pass; a stray Team libraries activation followed | Same stray activation (so not Leap-specific), but it surfaced **`kAXErrorCannotComplete`**, which flagged the press as suspect |
| Mac alert name swap | Reported "Cancel", which looked like a Leap bug | Raw `AXDescription`/`AXPosition` showed the app/AppKit exposed the swap, so it was not Leap |
| Pencil → checkmark toggle (Mac route edit mode) | Not observed | `cannotComplete` although the toggle worked. Exit 3 kept the script from re-pressing, which would have turned it back off |

## Ideas that might help Leap
1. **Resolve and press in one tight pass.** ui-ax never holds an element reference across calls. It finds the element and performs the action within milliseconds, on a fresh walk. The "New playbook" failure looks like a stale or reindexed reference, or a press during the sheet's focus transition. If Leap presses a reference resolved from an earlier observation, consider re-resolving it right before `AXUIElementPerformAction`, and confirming the reference is still valid (for example by reading `AXRole`) immediately before pressing.
2. **Surface the raw `AXError` and treat `cannotComplete` as "uncertain".** In both cases above, the raw error was the most useful signal:
   - In SwiftUI it usually means the control was replaced while its action ran: toggles, Save closing an editor.
   - On Simulator it correlates with the stray second activation.
   - Suggest putting the raw code in `input_result`, and adding a verification state such as `uncertain_side_effects` with a hint to check for unexpected navigation.
3. **A lightweight predicate probe for `wait` steps.** A targeted walk that only checks "does a label containing X exist" costs milliseconds; a full observation takes seconds. Waits could poll the cheap predicate and take the full snapshot only once, when the condition resolves. That would make Simulator waits much snappier.
4. **A raw-attribute triage mode.** The most valuable use of ui-ax was **telling tool bugs from app bugs**. A Leap command that prints an element's raw attributes would let agents make that call without a second tool: `AXDescription`, `AXTitle`, `AXValue`, `AXIdentifier`, `AXPosition`/`AXSize`, `AXEnabled` and action names, with no normalization.
5. **Label fallback order.** Check that Leap includes `AXPlaceholderValue`. Placeholder-only SwiftUI text fields, like the New playbook "Name" field, have no other label.

## What *not* to borrow
ui-ax is unsafe in ways Leap deliberately isn't:
- **First match wins.** There is no ambiguity check, so it can press a hidden duplicate under an overlay; Leap's refusal and disambiguation is better.
- **No occlusion or geometry check.** It presses whatever element matches, whether visible or not.
- **No evidence, history or replay protection** beyond the exit-3 convention.
- **No pointer path**, so canvas drawing is impossible.

## Suggested experiment
Reproduce the "New playbook" case natively:
1. Open Gameday Mac → Playbook selector sheet.
2. `{"role":"AXButton","label":"New playbook"}` via Leap, then immediately the same press via `swift scripts/ui-ax.swift GamedayMac Gameday press "New playbook"`.

If only the second opens the alert, compare the element reference Leap used, including its index and when it was resolved, against a fresh walk.
