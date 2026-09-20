# Gameday coach workflow — Leap replay

Date: 2026-09-19 (America/Phoenix). Native Gameday `local.gameday.mac`, Higley High School Knights · Freshman, Freshman 2026. Replay of [Sky's ordered trial](trial-sky-details.md), using native `mcp__leap__` tools. Status: all 21 workflow steps completed after restart. Zoom fix verified through native MCP. The automatic-reveal fallback is installed and its failure handling verified through native MCP. Gameday ignores AXScrollToVisible, so successful automatic reveal is not established; direct AXPress works. See the final verification section.

## Starting state

User explicitly reset the filters between trials. There are 87 plays because Sky saved `TRIAL SKY - Halftime Slant Flat`. Leap's eventual test play must be named `TRIAL LEAP - Halftime Slant Flat`; all other actions and text follow the Sky report.

## Ordered results so far

| Step | Leap action/result | Comparison |
|---|---|---|
| 01 | Reset filters succeeds; no change from user's clean state. | Same baseline, plus Sky's saved play. |
| 02a | PASS selects successfully; 54 matching plays. Reported coordinate fallback at window (207,-363) despite offscreen flag. | Successful state change, but negative coordinate fallback deserves separate investigation after restart. |
| 02b | Defense front 3–4 selects via AX; PASS loses selected state; 13 matching plays. | Confirms Sky's result even with an observation between clicks. Gameday filter semantics, not evidence of a Sky stale-index mistake. |
| 03 | Set Search plays to OSCAR via verified AX selection replacement; 2 matching plays. | Same result. |
| 04 | Select ANY OSCAR BRADY · 3-4 via AX; 1 of 2; 7 O / 7 D. | Same result. |
| 05 | Show play information; same LT/LG/C/RG/RT/T assignments and no coaching notes. | Same result. |
| 06 | Show field; explicit screenshot displays diagram/blocking and front. | Same result. |
| 07 | Zoom to 150 percent executes. Screenshot confirms zoom, but the returned tree loses all Sideline controls. Reset field view, Next play, and 3rd down requests return missing-label errors without taking action. A fresh get_app_state still has only 18 nodes. | Leap defect blocks semantic replay. Sky retained access after a fresh observation. |
| 07 resumed | Fresh native MCP tree exposes Reset field view, Next play, Show play information and Search plays. Reset succeeds; Default view returns. | Zoom pruning fix verified. |
| 08 | Next play selects ANY OSCAR VICK · 3-4, 2 of 2. | Same as Sky. |
| 09 | 3rd down clears search; 0 matching plays. | Same as Sky. |
| 10 | Clear filters request rejects a stale element; user confirms they clicked Clear filters themselves. Playbook mode opens with 87 plays. | User performed the recovery action; correct stale-target rejection by Leap. |
| 11 | Select Brady play; New play opens default 2X2 SLOTS, PASS, Any defense, 11 O / 0 D. | Same as Sky. |
| 12 | Title TRIAL LEAP - Halftime Slant Flat; exact baseline coaching notes and HALFTIME-TRIAL tag added. Text writes verified. | Existing tag reused and selected. |
| 13–14 | Receiver 1 selected; Find a route = 2 Step Slant; exact route assigned; exact baseline player note entered. | Same as Sky; route edit/mirror enabled. |
| 15–16 | Receiver 2 selected; Find a route = Flat; exact Flat assigned; exact baseline player note entered. | Same as Sky. |
| 17 | Mirror Original → Mirrored; screenshot shows both routes and selected Flat card; mirror restored to Original. | Same as Sky. |
| 18 | Save closes editor; old Brady play remains active. Save uses coordinate fallback at valid window point (1304,68). | Same app behavior as Sky; persistence checked next. |
| 19 | Reset filters gives 88 plays; search TRIAL LEAP gives exactly 1. | Saved new play found. |
| 20 | Select trial play, enter Sideline; header matches, 1 of 1. | Same as Sky. |
| 21 | Show play information displays exact coaching notes and both receiver notes. | Save/reopen verified; no Gameday relaunch test. |

## Defect L1: visible Sideline subtree incorrectly pruned after zoom

Severity: blocks AX-based operation of the main view. Reproduction: open Sideline field and click Zoom to 150 percent. Native MCP state #9 reports settled but only shows the window, top navigation, window controls, and menu bar. State #10 is unchanged. Screenshot still shows Search plays, Reset field view, Show play information, Previous/Next and down shortcuts.

Root cause: `AXWalker` used shallow-container center-point hit testing to decide whether an entire subtree was hidden. A signed raw AX diagnostic confirms that Gameday's underlying controls still exist and are enabled, but hit tests return a separate, empty AXGroup covering most of the main content (screen frame 65.5,212,1313.5,758). Its parent chain does not include the visible Sideline container. Thus hit-test ancestry is not a valid basis for removing that container. The precise purpose of that app overlay was not established.

An initial multi-point variation also failed the live read-only regression. It was discarded. Final fix removes hit-test-based subtree pruning from `Sources/LeapCore/AXTree.swift`. Existing zero-size skipping and offscreen annotations remain. Tradeoff: inactive SwiftUI tabs may contribute extra nodes again, as they did in Sky. Prefer complete actionable state over falsely hiding the live interface.

Validation before the user's request to stop pre-install testing: original signed binary fails `scripts/test-gameday-zoom.py` against the zoomed screen; initial multi-point candidate also fails. Existing five unit tests passed on the initial candidate. Final removal is built/signed/installed without another test run, per the user; native-session verification is pending restart. After the user restarted, native MCP state #1 exposed all four controls; state #2 successfully reset the field, and states #3–27 completed the replay. The final pruning removal now passes the actual workflow.

## Regression runner launch issue

Standalone Python-spawned signed servers hung before MCP initialization when sharing the runner's process session. Starting the child with `start_new_session=True` immediately restored initialization and AX access. Applied this to `scripts/mcp-call.py`; no server startup change was required. `scripts/test-gameday-zoom.py` is a read-only live regression requiring Gameday already showing a zoomed Sideline field.

## Positive observations and remaining concerns

- Label-based AX presses and verified search text replacement worked through step 06.
- Automatic state diffs were concise before the zoom failure; screenshots were requested only for field geometry.
- Missing-label failures prevented unintended actions after the tree collapsed.
- PASS action used a negative offscreen coordinate despite the tool advising label/index targeting for offscreen controls. The expected selection changed, but investigate whether fallback scroll/reveal and coordinate validation need improvement.
- State unexpectedly switched background → frontmost after Show play information, although foreground was not requested. Attribution is uncertain because the user also interacts with the app; do not yet classify as focus-stealing defect.
- `TRIAL LEAP - Halftime Slant Flat` now exists alongside the Sky trial play. No existing play was edited or deleted. Both trial plays remain available for review.

## Second fix and next restart checkpoint

The first restart checkpoint is complete. The entire comparative workflow is complete; no replay from the beginning is needed.

Defect L2: `Engine.click` falls back from failed AXPress to synthesized coordinates without considering the offscreen warning. Observed PASS click at window (207,-363) demonstrates the path; the expected selection changed, but those coordinates are not a reliable target. Added a guard after the AX attempt and before event dispatch: if an indexed target was offscreen and its point lies outside the refreshed window frame, return an explicit error directing the caller to scroll it into view. Successful offscreen AXPress remains supported (important for Simulator coordinate quirks).

Per the user's preference, built and installed immediately without a pre-install test cycle. Next restart: verify the new guard through native MCP and use scroll/re-read to recover if it fires. Keep Gameday open; it is displaying the saved TRIAL LEAP play's information panel in Sideline. The ordered comparison does not need repeating.

## Comparison outcome

Both backends completed filtering, play inspection, field zoom/reset, next-play navigation, route-library selection, mirroring, notes, save, search and reopening. Leap required a code fix to avoid losing visible content after zoom. Removing visibility pruning adds disabled inactive-tab nodes, similar to Sky; displayed diagnostic output filtered disabled lines for readability, without changing the underlying tool state.

Both exposed Gameday's filter replacement behavior, empty third-down result, Save retaining the previous active play, and editor 0 D versus viewer 7 D under Any defense. These are app observations, not established Leap defects. Route assignment names remain partly visual; AX enables editing/mirroring but does not mark the assigned library card selected.

No timing benchmark was performed. Neither trial tested persistence across Gameday relaunch or graded football strategy. The user's Clear filters action is the sole explicit manual substitution in the replay.

Installed final signed build at `/Users/ryan/Applications/claude-leap.app`. Previous bundle backed up at `/Users/ryan/.codex/backups/leap-zoom-20260919-234256/claude-leap.app`. MCP registration remains `leap`.

Second signed build (offscreen coordinate guard) installed at `/Users/ryan/Applications/claude-leap.app`; previous bundle: `/Users/ryan/.codex/backups/leap-offscreen-20260919-234709/claude-leap.app`. Native verification pending restart. Sky fallback internals were not verified; automatic AXScrollToVisible plus fresh frame validation is a possible improvement over the current explicit-error recovery.

## L2 revision: automatic reveal before coordinate fallback

The guard-only implementation is superseded. `Engine.click` now keeps AXPress first, then checks fresh element geometry against the window and enclosing AXScrollArea viewports. A partially visible target uses the centre of its visible portion; an explicit element-relative point must itself be visible. If the target is clipped, Leap requests `AXScrollToVisible`, revalidates the original element identity, and waits up to 1.8 seconds for two consecutive visible positions to agree. It reads the point once more before dispatching the coordinate click. Unsupported reveal, a stale/recycled target, or an unstable/invisible result stops without a coordinate click. The caller receives recovery instructions. Menu targets retain their existing handling because popup menus may lie outside the application window.

This uses live frames rather than the prior snapshot's offscreen flag and also catches rows clipped inside a scroll view while still inside the overall window. It does not reintroduce hit-test pruning. No successful AXPress is followed by a reveal or second click. Apps that do not implement AXScrollToVisible still require an explicit scroll action; no guessed wheel events are generated. Sky's internal fallback behavior remains unverified.

Build/install only per user preference; native verification follows the next session restart. Check automatic reveal where supported and clear refusal where unsupported, then normal visible clicks. The comparative coach workflow itself is already complete.

Automatic-reveal signed build installed at `/Users/ryan/Applications/claude-leap.app`; previous bundle backed up at `/Users/ryan/.codex/backups/leap-reveal-20260919-234901/claude-leap.app`. Registration remains `leap`.


## Final native-session verification after automatic-reveal install

- State #1: PASS is outside the window at approximately (149,-386), inside filter ScrollArea [19]; saved TRIAL LEAP coaching/player notes remain present.
- Ordinary click by index [21] succeeds via AXPress, selects PASS, and leaves scrolling unchanged. This confirms offscreen semantic presses still work.
- To deliberately exercise the coordinate path without relying on intermittent AXPress failure, called click with the observed PASS element plus element-relative offset (58,23). Leap requests AXScrollToVisible, waits, then reports that the position did not become visible/stable and sends **no coordinate click**. Fresh state confirms the scroll value is still 0.7987538940809968. Thus Gameday accepts the reveal request without accomplishing it; automatic-reveal success cannot be claimed here.
- The existing background `scroll(up, pages:2)` dispatch also produces no observed scroll change. Its tool text says dispatched scrolling; this is not proof of app response.
- Explicit `perform_action(ScrollUpByPage)` changes scrollbar value to 1 (moves away from the desired top). `ScrollDownByPage` then changes it to 0.2824242424242424, and another to 0. Those app AX action names behave opposite to the expected viewport movement. This is another reason not to blindly substitute page actions in automatic reveal.
- At the top, the same element-relative coordinate click is dispatched at valid window point (207,296). No selection change is observed. A following plain AXPress deselects PASS correctly. Coordinate dispatch success remains distinct from application response.
- Reopened the saved TRIAL LEAP play and Show play information; exact coaching notes and both player notes remain intact. Left the filter pane at its top with PASS deselected and search TRIAL LEAP intact.

Outcome: the incorrect offscreen coordinate fallback is prevented, direct AX interaction remains functional, and recovery through explicit AX scroll actions is possible. Successful automatic reveal remains app-dependent and was **not** demonstrated in Gameday. No further code change or session restart is required for the installed behavior. A future improvement could add bounded, feedback-driven scrolling when reveal is ignored, but must handle inverted action direction, clipping, and stale targets; it is not part of this verified implementation.

## Dedicated scroll comparison and fix

See [feature scroll trial](trial-scroll-details.md). Identical one-page down/down/up/up calls succeeded with Sky and produced no movement with Leap. Added AX page-action preference for whole-page indexed background scrolling, with content-direction mapping and explicit dispatch/request wording. Build/install checkpoint: restart and repeat those four calls; pixel/fractional/coordinate scroll remains unverified wheel fallback.

Scroll fix verified after restart: indexed whole-page down/down/up/up moved 0 → 0.7176 → 1 → 0.2824 → 0, matching Sky's direction, boundaries and reversibility with a slightly smaller native page size. See `trial-scroll-details.md` for the side-by-side values and scope limits.

### Field gesture follow-up: unified pointer delivery verified

See trial-field-details.md for the full investigation. Native MCP restart verification now passes background and explicit-foreground double-click zoom, drag right120/up80, and AX reset. Same field results in both modes; background app remained background and window position/size did not change. Pointer delivery no longer switches to HID for foreground:true. No play data changed. Broader parity remains feature-specific.
