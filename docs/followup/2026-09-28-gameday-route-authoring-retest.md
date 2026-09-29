# Leap re-test: Gameday route-authoring checks after the feedback fixes (2026-09-28)

Re-ran the Gameday hybrid route-authoring checks with `mac_ax` against the updated Leap. Every outcome was confirmed against the app's SQLite records.

The test play was a fresh, untouched twin of last run's (EARLY 52 X-MERCEDES T-FLAT, id `DC072E3A…`). Its Y assignment references the shared route "5yd Drive" with wording "5yd Mesh" and an offset. Its X assignment references "Flat" with wording "4yd Mesh", an offset and a mirror override.

Sessions (project `/Users/ryan/src/gameday`):
- Mac `46983CA2-4027-42C5-BC93-66DDF51A54D0`
- iPad Air `6D4275D1-E217-48F1-922A-9057FE3DCB57`
- iPhone 16 `D2F5B0E8-6D97-4498-95C1-21760D7F996D`

## Results by requested case

| # | Case | Result |
| --- | --- | --- |
| 1 | Alert buttons by label; reported label = effect | **Pass for Leap.** Discard changes, Cancel and Change Route by label: reported `target.label` matched the SQLite effect every time. The Create-scenario mismatch is an **app/AppKit accessibility defect**, not Leap (see below). The "Target identity changed" refusal was never triggered. |
| 2 | Hidden layers and plain label selectors | **Partial.** Pass: the role-only text field chose "Search plays" (`disambiguated: "topmost (hit-test)"`), and alert "Cancel" vs the editor Cancel chose the alert (`disambiguated: "modal sheet"`). **Fail:** `{"role":"AXButton","label":"Save"}` with the full-window route editor open still returns "Selector matches 2 elements" (details below). **New:** a single match that is hidden under the editor is pressed without warning. |
| 3 | Simulator transition, no wait | **Pass.** The first click after opening the full-screen editor succeeded with `observation_retries: 1` (iPad, three times). The same shows on another step after a save transition. |
| 4 | Error messages | **Pass.** `Step 1: unknown field(s) ["bogus"]; allowed: [...]`. The bad selector key names `["match"]`, but **not the step index** (minor). `fields` is accepted on observe steps. |
| 5 | `root` as an ID prefix | **Pass.** `root: "w/AXWindow[Gameday]#0/AXGroup[]#0"` now matches (both Saves live under it). `root` on `…/AXSheet[alert]#0` scoped alert buttons correctly. `within: "iPhone 16 – iOS 18.0"` (the window label) did not narrow, since every node is under the window; that behavior is fine. |
| 6 | `set_value` with the current value | **Pass.** "value unchanged: [34] already holds this value; nothing sent (the app sees no edit)". |

## Case 2 failure detail: overlapping Save pair
With Gameday's full-window contextual route editor open on the Mac:
- `…/AXButton[Save]#0` (play editor, covered): frame `[1263.5,45.5,81,45]`, **enabled: false**
- `…/AXButton[Save]#1` (route editor, on top): frame `[1263,54.5,75.5,45]`, enabled: true

The covered button's center (1304,68) lies inside the top button's frame, so a hit-test at either center returns Save#1. Yet the selector still reports 2 matches. Neither is inside an AXSheet (the editor is an in-window overlay).

Suggest:
- apply the hit-test tie-break when frames overlap;
- and/or prefer the only **enabled** match when exactly one is enabled.

## New: a single covered match is pressed without warning
After the Mac play editor opened, `{"role":"AXButton","label":"Create scenario"}` matched exactly one element: the browse screen's button **underneath** the editor. Leap pressed it through accessibility and reported success; it had no visible effect.

With a single match there is no ambiguity check, so the occlusion check never runs. Suggest running the same topmost/hit-test check on single matches and refusing or flagging "target is covered by another layer".

## New: foreground pointer click at coordinates had no effect on the Mac alert
`click` at window (680,562) inside the Create-scenario sheet, a pointer route, both default and with `arguments.foreground: true`: acknowledged, no UI change. Leap's hint about SwiftUI ignoring background pointer events was shown on the first attempt.

Pressing the same element through accessibility worked. So either synthesized pointer events don't reach AppKit alert sheets, or the coordinates were off: window points vs the sheet's coordinate space in a titled window. Worth a native check.

## Not Leap: the Mac Create-scenario alert exposes swapped button names
SwiftUI code: `Button("Cancel", role: .cancel) {}` followed by `Button("Create scenario") { … }` in an `.alert` that has two `TextField`s. Leap and an independent AXUIElement script agree:

| AX element | AXDescription | Position | Drawn text | Action (SQLite-confirmed) |
| --- | --- | --- | --- | --- |
| `action-button-2` | "Create scenario" | upper | Cancel | cancels (no record) |
| `action-button-1` | "Cancel" | lower | Create scenario | creates the scenario |

The description-to-action swap is in the accessibility tree itself, which also misleads VoiceOver. On iPad and iPhone the same alert maps correctly. This is recorded for the Gameday app. For Leap, the only mitigation would be a cross-check against the drawn text, which isn't in scope.

## Other observations
- The iPhone Simulator window toolbar has its own "Home" (device home) button. A plain `{"label":"Home"}` was correctly refused as ambiguous with the app's Home. `root` on the app group resolved it.
- On iOS, only the topmost full-screen cover is exposed, so Save/Cancel were never ambiguous on the simulators.
- The Gameday app issue remains: on the iPad, Team libraries appears after saves. Seen this run after a plain play save and after a scenario save.

## Update: the iPad "Team libraries after Save" is caused by Simulator accessibility presses
Previously reported as a Gameday app issue; it is not. A/B test on the iPad Air simulator (session `6D4275D1-E217-48F1-922A-9057FE3DCB57`), same play and one-field change:
- A **pointer** `click` at Save's screenshot position saved the play and stayed on Playbook. `wait "New team"` for 10 s: absent.
- An **AXPress** on `{"role":"AXButton","label":"Save"}` saved the play, then the full-screen Team libraries view appeared within about 5 s.
- The same AXPress through an independent AXUIElement tool (`scripts/ui-ax.swift` in gameday) did the same. That tool got `kAXErrorCannotComplete` from `AXUIElementPerformAction`, because Save disappears as the editor overlay closes.

Team libraries is only presented by the app's header "Team library" button, top-left under the closed editor. So a remote AXPress on a control that vanishes mid-action appears to produce a second activation or tap that lands on another element. The reported Save host frame is transposed or negative (`[104.8,-258.3,48.6,87.4]`), so a fallback activation point derived from that geometry is a plausible cause.

Suggestions:
- When AXPress on a Simulator element returns cannot-complete, or the element vanishes, surface a warning that a stray activation may have occurred, and include a post-action check.
- Offer a "pointer-preferred" mode for controls known to dismiss their container, when screenshot geometry is available.

## Update: Gameday fixed the Mac alert name swap (commit 13fa475)
The swapped Create/Cancel names came from SwiftUI text-field alerts on macOS: accessibility names are applied in declaration order while AppKit orders buttons default-first. Gameday now declares the primary action first. The Mac Route Info, Create scenario and Create variation alerts map correctly, so Leap needs no change for this case.

## New observations (Mac session `46983CA2-4027-42C5-BC93-66DDF51A54D0`, 23:36–23:40Z)
1. **An AXPress inside a SwiftUI sheet was acknowledged but had no effect.** `{"role":"AXButton","label":"New playbook"}` inside the Playbooks sheet returned `pressed [749] via accessibility`, but no alert appeared: the screenshot was byte-identical, and the delta showed only a focus change. A foreground pointer click at its frame center (346,704) also had no effect. An independent `AXUIElementPerformAction(kAXPressAction)` on the same element, from gameday `scripts/ui-ax.swift` about 30 s later, opened the alert at once. Possibly Leap pressed a stale element reference, or the press landed during the sheet's focus transition. Worth a native repro.
2. **`press_key` with `foreground: true` still refused.** It returned "the app refused to make it key from the background… Use … foreground=true", although `arguments.foreground: true` was set. The message contradicts the argument. Either the flag isn't read for `press_key`, or activation failed and the message should say so.
3. **ui_observe dumps.** An `AXSheet` with an empty label is easy to miss. Gameday's own helper filtered it out, which is a Gameday tooling issue; noting it in case Leap's compact outputs also drop unlabeled containers.
