# Follow-up: detect user interaction during agent work (Sky `userIntervened`)

Status: open, not critical (user direction, 2026-09-30). Deferred behind the current fixes.

## Problem

Leap cannot tell when the person at the Mac is using the target app while an agent acts. On
2026-09-28, runs were invalidated because the user was typing and switching screens at the same time,
and their input interleaved with Leap's (docs/iterations/2026-09-28-resume-review.md). Leap's current
guards only catch the consequences: stale elements, a relaunched process, a moved window, or a changed
target identity.

## How Sky does it (reference)

- Error `userIntervened` (-10016), sent to the model as "The user changed '<app>'. Re-query the latest
  state with get_app_state before sending more actions." The action is not applied
  (node/sky .../mac/errors.js; SKY-BEHAVIOR §7).
- Native code (strings only): `ComputerUseUserInteractionMonitor`,
  `UserInterruptedIntervention(requiresRequery, debounceDeadline)`,
  `clearUserInterruptedInterventionAfterStateRequery`, and "The user is still interacting with '…'".
- Behavior: physical input on the target app sets a flag; actions are refused until a state read
  clears it, with a debounce while input continues.

## Candidate for Leap (to design against Sky first)

- Watch physical input with a listen-only event tap or `CGEventSourceSecondsSinceLastEventType`
  (HID state), filtered to events aimed at the target pid or window, ignoring Leap's own synthetic
  events (source state id / user-data tag).
- Refuse element and coordinate actions after interaction until `get_app_state` or `ui_observe`;
  report "user is still interacting" while within the debounce window.
- ui_perform: stop the workflow with `execution: "stopped"` and `reason: "user_intervened"`, and
  never replay.
- Needs: Input Monitoring permission implications (a listen-only tap may require it), and a test
  with real input.
