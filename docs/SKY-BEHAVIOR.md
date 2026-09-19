# What the Codex/Sky computer-use service actually does — evidence from the recorded session

Source: the full Codex session transcript (`/tmp/astra/full-transcript.txt`, 3,550 records,
2026-09-16 21:40Z → 2026-09-19 02:28Z), split into 17 slices and read end to end, tool call by
tool call, by 17 reviewers working from one checklist (`/tmp/astra/REVIEW-CHECKLIST.md`).
Per-slice reports: `/tmp/astra/report-00.md … report-16.md`. Record numbers below (`#1409`)
are transcript records. "Sky" is OpenAI's `SkyComputerUseService`; the agent drove it through
the `cua_repl` JS REPL. Slices 02 and 08 were `chrome-devtools` only (Hudl data pulled with
in-page `fetch`, bypassing the UI) and contribute nothing about Sky.

The last section maps every finding to claude-leap: matched, exceeded, or still a gap.

## 1. API surface the agent used

`cua.getApp(nameOrBundleIdOrPath)` returns an `App` handle **and prints the full tree of its key
window**. Methods used: `getAXState({disableDiffing?, emit?})`, `getScreenshot({emit?})`,
`getAXStateAndScreenshot()`, `click(indexOr[x,y], {mouseButton?, clickCount?})`, `drag([x,y],[x,y])`,
`scroll(indexOr[x,y], 'down', pages)`, `pressKey('super+q')`, `typeText`, `setValue(index, text)`,
`paste`, `performSecondaryAction(index, 'Raise'|'Cancel'|'Edit filters'|'AXScrollToBottom')`,
`cua.rewriteDocumentation()` (re-emits the 50 KB first-use API doc, 2–5 ms; called at the start of
most user turns), `cua.listApps()` (JSON with duplicate entries per bundle id).
`selectText` exists but was never called (0 of ~1,450 Sky calls).

Call counts over the session: click 1,045 (52 failed), pressKey 237 (39 failed; 130 were
`super+q`), typeText 38 (6 failed), setValue 27 (1 failed), performSecondaryAction 31 (7 failed),
drag 25, scroll 11, paste 3 (all 3 failed).

The agent almost never defined helpers. The exceptions: a `clickTablet(label)` that re-read the
full tree and regex-matched `button … Description: <label>,` before every click (#2228), a loop
re-fetching `getAXState({disableDiffing:true, emit:false})` to re-resolve an index before each
click (#113), and `fs.writeFile(path, await X.getScreenshot({emit:false}))` to archive JPEGs.
Everything else was one-line chains: `await app.click(46); await app.getAXState();`.

## 2. Targeting apps and windows

- `getApp` accepts a display name, a bundle id, or a full `.app` path. Path targeting goes through
  LaunchServices, so a dead process yields `NSCocoaErrorDomain Code=256 … procNotFound: no eligible
  process with specified descriptor` from `_LSAnnotateAndSendAppleEventWithOptions` (#452, #3522).
- Ambiguity is refused, not guessed: `Ambiguous app identifier 'local.gameday.mac'. Multiple apps
  share this bundle identifier: … Use an app name or full app path instead.` (#297, #697, #2341).
  Unknown id: `Invalid app: com.gameday.app` (#8, #1500s).
- There is **no window parameter**. The handle follows the app's key window: the Simulator handle
  silently switched from iPad to iPhone (#2817) and from Apple TV to iPhone (#1409). Devices are
  switched by opening Simulator's **Window** menu and clicking `iPhone 16 – iOS 18.0,
  ID: makeKeyAndOrderFront:` (#623, #1403/#1409, #2817 …) or by closing a device window (#658).
- Activation: `performSecondaryAction(<window>, 'Raise')` before every `super+q` (every window root
  advertises `Secondary Actions: Raise`). No `activate`/`focus` API exists. Nothing in 3,550 records
  mentions frontmost, cursor, pointer, PiP, badge or "remote control" — the overlay is invisible to
  the model.

## 3. State text grammar (verbatim forms)

Full tree:
```
Window: "Gameday", App: Gameday.
0 standard window Gameday, Secondary Actions: Raise, ID: SwiftUI.ModifiedContent<…512 chars…>
	1 container
		2 button Team library: Higley High School Knights · Freshman
		65 text field (settable) Search plays
113 menu bar
	114 GamedayMac
	115 File

The focused UI element is 0 standard window Gameday, Secondary Actions: Raise, ID: …
```
- One tab per depth. Line = `<id> <role phrase>[ (<flags>)] <title>[, Description:][, Value:]
  [, Placeholder:][, ID:][, Help:][, Secondary Actions: a, b]`. **Attribute order is not fixed**
  (`Secondary Actions` before `ID` on windows, after it on iOS buttons; multi-line `Description:`
  is moved after `Secondary Actions:` and emitted with raw newlines).
- Flags: `(selected)`, `(selectable)`, `(disabled)`, `(settable)`, `(float)`, combined
  `(disabled, settable, float)`. `(disabled)` replaces `(settable)` on disabled text fields.
- Menu-bar items and menu items have **no role word** (`115 File`, `8 All leagues, ID: menuAction:`,
  `7 (disabled) Move Window to Left Side of Screen`). SwiftUI Picker groups likewise (`18 View`).
- Role phrases seen: standard window, sheet, container, text, button, text field (settable),
  pop up button, menu, menu bar, scroll area, collection, list, outline, row (selected|selectable),
  split group, splitter (disabled, settable, float), radio button, checkbox, switch, tab group, image,
  link, unknown (SwiftUI custom views, e.g. player markers `26 unknown Offense LT`), scroll bar
  (settable, float), value indicator, increment/decrement arrow/page button, close/minimize/full
  screen button, toolbar, element (iOS timers/progress), Group (settable) (SwiftUI TextEditor),
  HTML content (Mac WKWebView, with DOM roles `email field (settable)`, `heading`, `link`).
- Long values are cut at exactly **512 characters**; the SwiftUI window `ID:` is dumped raw every
  time (~500 wasted characters per full tree). Raw AX action names leak (`AXScrollToTop`).
- Containers are capped at 100 children: `container (showing 0-100 of 144 items)` (#2259, #3178),
  `outline (showing 0-19 of 100 items)` in Finder. Bottom controls of long lists were hidden by this.
- Sheets: header becomes `Window: ""` (SwiftUI sheet) or `Window: "Unknown"` (NSAlert-style,
  root `sheet Description: alert`, buttons `ID: action-button-1/2`); **all main-window IDs are listed
  as removed** and the sheet is `+`-added; on dismissal the window comes back renumbered with the
  sheet's ID as root (`~87 standard window Gameday`) — root is 0 again only after `getApp`.
- Trailers (never both): `The focused UI element is …` **or** a `Selected:` block
  (`\t8 row (selected)`, then `Note: Pay special attention to the content selected by the user…`),
  sometimes `Selected text:` fenced block with the same note (#605, #796). The focused line is
  omitted on many main-window states with no derivable rule; it never named an iOS control (always
  the Simulator window).
- Diff:
```
The following is a diff from the previous accessibility tree for Window: "Gameday" with ~ and + representing changed and added elements, respectively. Removed elements are summarized by ID range.
Removed element IDs: 9, 13, 17-74, 76-77, 86-89, 106, 124-129
~ 74 text field (settable) Description: Search plays, Value: OSCAR
+	121 container
```
  No-change form: `There has been no change in the accessibility tree for Window: "Gameday".`
- `getAXStateAndScreenshot` text is byte-identical to `getAXState`; only the record header's
  `images=1` reveals a screenshot. `getScreenshot()` alone prints nothing. Screenshots are JPEG,
  Simulator iPhone window 888×509 (#191, #3487). No size/format text is ever emitted.
- Multiple emissions in one REPL call are **concatenated with no separator**
  (`…Secondary Actions: RaiseThe following is a diff…`), and an error from a later statement can
  print before an earlier statement's text.

## 4. Element IDs and diff semantics (the weak spot)

IDs are a running per-session counter assigned in traversal order, **bound to AX element identity,
not to content**:
- `~ id` frequently denotes a **different element, even a different role**, at the same ID
  (#879, #996, #2696 scroll area → text field, #2780 Cancel → Discard, #3529 sheet → window,
  #3548 button Playbook → text Formations).
- Unchanged elements are reported removed and re-added with new IDs (#3543: Offense, Defense,
  Playbook … removed 10-16 and re-added as 123–129).
- Removed IDs are reused inside the same diff (#375, #1099); a `+` line can re-add an ID never
  listed as removed (#493); one diff omitted additions later reported removed (#2744).
- After a reinstall the whole app subtree is removed and re-created above the previous max (#1411).
- `getApp` and `getAXState({disableDiffing:true})` restart numbering at 0; `getAXState` never does;
  a Window-menu popup tree is 1-based (`1 Window, Secondary Actions: Cancel, Pick`).
- "No change" was demonstrably **false** at #358 (pop-up had changed, menu closed), #2468/#2470
  (timer-driven screen), and after `The user changed` recoveries (#1900s). The agent's remedy was
  always `getAXState({disableDiffing:true})`.
- `The element ID is no longer valid. Try to get the on-screen content again…` (-10005) fires when
  two clicks on the same element are batched (#102), ~35 s after a menu opened (#1407, re-read
  returned identical IDs and the retry worked), and after user interaction; once the failed click
  had **taken effect anyway** (#357). `The element was invalidated, and an attempt was made to
  refetch it, but … multiple elements were found that match the criteria` when labels are
  duplicated (2×, slice 15). `elementHasNoFrame` on a Save button inside a closing sheet (#1095).

## 5. Input mechanisms — what the text proves

**Clicks.** ~95 % by element index; all attributable diffs came from index clicks. Coordinate
clicks: reliable on the Mac app (#239–#247, #301–#304, #1670, right-click `{mouseButton:'right'}`
and `{clickCount:2}` on the Mac canvas, slice 13) and on childless iOS containers where nothing
else works (`Football field` markers #743, #889, #1734; the `tab group` segmented control #3135).
But on the Simulator they also failed instantly with `windowNotFoundAtPosition((1573.0, 463.0))`
(#1793–#1802, #3460s — fractional global points missing the window) or produced "no change"
(#172–#192, slices 03, 14, 15). `drag` moved a Mac route waypoint (#727, 14.4 → 17.6 yd), swiped an
iPhone field (#1413), moved a wheel picker (#2188); vertical drags/scrolls on iOS lists produced no
AX change (#2293, #2304, #3075–#3078) — the agent scrolled by clicking far-down `text` elements or
`performSecondaryAction(23,'AXScrollToBottom')`.

**Keys.** `pressKey` returns an **empty RESULT** in 13–100 ms; success is indistinguishable from a
no-op without a follow-up read.
- `super+q`: the quit mechanism (130 uses). Works (confirmed by `pgrep` exit 1 and by the
  `procNotFound` error whenever `getAXState()` was chained after it — #1164, #1523, #2700, #3522).
  Fails to quit while a modal sheet is up, and so does clicking `Quit Gameday, ID: terminate:` (#675,
  #679); dismissing the sheet fixed it.
- `super+a`: reliably selected all before `typeText` replaced a Mac field (#797, #808, #2750).
  `super+w` (1 of 2 ok), `super+shift+g` + `Return` in Finder (worked), `super+k` in Simulator
  (software keyboard appeared in the tree). `super+shift+k`, `'t'`, `'End'`, `'space'` on an iPad
  notes field: no change (#2240s).
- **Arrow keys / Return / Escape on tvOS: zero evidence.** All ~120 presses went to the Apple TV
  Simulator window, whose tree exposes no app content (only Home/Save Screen); every one returned
  "There has been no change". Every "TV checks passed" claim rests on screenshots not in the dump.
- Arrow keys on the **Mac** app: `Right` did nothing (#1267) until the agent changed the app's own
  key handling (#1272 reinstall), then advanced the play counter (#1273, #1287, #1300, #2353). So
  Sky's key delivery does reach the Mac app; `Left` was never individually verified.
- `Escape`: dismissed a rebuilt sheet (#3536) but not the older alert (#3519) — app-dependent.
  `space` toggled on the Mac (#67, #69). `Return`/`Escape` ended route drawing (#303/#304, inferred).
  One `Tab` with unclear effect.

**Text.**
- `setValue(index, text)`: 26 of 27 worked — Mac fields, iOS fields (#2260, #2280), web fields
  (#1627). Failed silently on `slider (settable, float)` (#2187) and with
  `unknownType(Optional(197))` on `Group (settable, unknown)` = SwiftUI TextEditor (#2247). It
  changes the value but did **not** trigger the app's "Save notes" affordance (#3496).
- `typeText`: works on Mac after `click(field)` (32/38), **replaces a pre-selected value** (#1094),
  and on the **iOS Simulator silently types nothing** (#1771, #1955, #2243, #2272) in most cases
  (worked once at #1684 and on iPad at #2605, #3130). Into a SwiftUI TextEditor it no-op'd once and
  worked after `click; pressKey('Tab'); typeText` (#3500).
- `paste`: 3/3 failed with `Timed out waiting for the application to read the clipboard`
  (#2245, #2278, #1958) — all in the Simulator.
- Empty iOS fields print their **placeholder as `Value:`** and switch to `Value: <text>,
  Placeholder: <ph>` once typed; Mac fields print `Value:` and `Placeholder:` separately.

## 6. iOS / iPadOS / tvOS Simulator

- iPhone and iPad windows expose the simulated app's tree **flattened under one `container`**;
  every element carries `Secondary Actions: Cancel`, its label in `Description:`, SF Symbol names as
  `ID:` (`house`, `plus`, `shuffle`, `chevron.left`), progress as `element Value: 40%`, keyboard /
  predictive bar / Dictation as elements once the keyboard is up. Only laid-out rows appear (Mac
  shows all rows). Focus is always reported on the Simulator window. The iPad exposed its tree
  only intermittently at first (#574 chrome only, #591 full).
- Not exposed: tvOS app content (ever), WKWebView contents inside iOS (Hudl login had to be done by
  the human, #3041), segmented-picker segments (childless `tab group`), the iOS `Football field`
  canvas (childless; Mac exposes player buttons).
- Simulator chrome is normal AX: hardware buttons, `toolbar` Home / Save Screen / Rotate,
  `Capture Pointer` / `Capture Keyboard` checkboxes (iPad), the Window menu with Fit Screen /
  Point Accurate / Pixel Accurate and the device list. Rotate clicks produce no AX change.
- Coordinate actions convert to fractional global points; see §5 for their failure modes.
- Simulator actions cost 1.5–11 s vs ~1.1 s on the Mac; first read after a reinstall 4–5.5 s.

## 7. Control-plane messages (the ones a client must reproduce)

| Text | When | Recovery |
|---|---|---|
| `The user changed '<app path>'. Re-query the latest state with `get_app_state` before sending more actions.` (~40×, status=failed, 8 ms – 19 s; only on actions, never on bare reads; the requested action was **not** applied) | process replaced by a rebuild/relaunch, `install-simulator.py` switching devices, or the human interacting | bare `getAXState()` then retry; twice the agent asked the user to stop touching the app |
| `Computer Use is not active for '<app path>'. You first must call `get_app_state` to get the latest state before doing other Computer Use actions…` | first action after a new user turn or a 4–15 min idle gap | `getAXState()` (renumbers from 0); agent then always did `getAXState({emit:false})` before `pressKey` |
| `Computer Use server error -10005: The element ID is no longer valid…` / `elementHasNoFrame` / `… multiple elements were found that match the criteria` | stale or duplicate element | `getAXState({disableDiffing:true})`, re-click |
| `Computer Use server error -10005: timeoutReached` (11×) | ≈5 s on state reads/`getApp` (Dock 5075 ms), 17–20 s on click batches during saves | retry; **the actions had already applied** (#1663, #1665) |
| `… procNotFound …` | any call after the process quit | re-`getApp` |
| `windowNotFoundAtPosition((x.x, y.y))` | coordinate action off the target window (Simulator) | switch to index |
| `noWindowsAvailable` | app with no window yet | wait |

Failed batches still execute their earlier statements (#1821, #1953).

## 8. Timing (ms, from record headers)

| shape | Mac | Simulator |
|---|---|---|
| bare `getAXState` | 27–250 (median ≈80; spikes 5.5 s, 43.5 s) | 170–5,520 (median ≈1,250) |
| `click + getAXState` | 400–2,600, median ≈1,400 (max 6.2 s during saves) | 1,100–6,000, median ≈1,900 |
| `+ getScreenshot` | +0–1,200 | up to 10.5 s |
| `getApp` | 130–900 (26.1 s once right after a reinstall) | 300–800 |
| `pressKey` alone | 13–100 | 71–98 |
| `rewriteDocumentation` | 2–5 | — |

The ≈1.4 s floor on click+state is a post-click settle, not tree-read cost (screenshots did not
add to it in slice 16).

## 9. Agent behavior worth copying

- Action + verification in **one round trip** (`click; getAXState`), screenshots only at layout
  milestones or when the user asked; cross-app batches (`sim.click; sim.getAXState; app.getAXState`).
- Verified through AX text (`4 matching plays`, `1 / 86 → 2 / 86`) and shell ground truth
  (`pgrep`, `sqlite3` on the simulator container) rather than trusting the UI or its own claims.
- Quit → reinstall → `getApp` → exercise → `super+q` loop, with `Raise` before quit.
- Bypassed the UI when a data path existed (Hudl JSON via in-page `fetch`).
- Bad habits also on record: asserting tvOS/Dock results with no supporting state (#435, #627,
  #1258), and continuing after errors it did not acknowledge (#1465).

## 10. Parity map — Sky behavior → claude-leap

| Sky | claude-leap (HEAD) | Status |
|---|---|---|
| AX-only clicks/values/menu presses; never activates the app | AXPress / AX text API first; background `postToPid` events as fallback; activation only with `foreground=true` | matched |
| Menu bar in every full tree; clicking a title returns the open menu; device switching via Window menu | `MenuBar`/`MenuBarItem` lines in every tree; open menus rendered with their items (probe: AXPress opens a background app's menu, frontmost unchanged); Escape → `AXCancel` on the open menu | matched (ba8d3d0) |
| `The user changed '<app>'` / `Computer Use is not active` gates | `actionSession`: relaunch (new pid) and no-state-yet guards refuse element/label actions until `get_app_state`; header flags `[new process … indices restart]` | matched (ba8d3d0) |
| `timeoutReached` ≈5 s | `AXUIElementSetMessagingTimeout(app, 5)` → `cannotComplete` error instead of a hang | matched (ba8d3d0) |
| Ambiguous bundle id refused with paths | prefer frontmost, then the only copy with windows, else refuse with paths | exceeded |
| Positional, reused IDs; `~` may be a different element; false "no change" | content-keyed stable indices for the life of the window; `staleElement` guard checks role/size before acting; diff computed from rendered lines | exceeded |
| Placeholder printed as `Value:` on iOS | `value=` and `placeholder=` distinct | exceeded |
| 512-char raw SwiftUI IDs, `_NS:` ids, `AXScrollToTop` leaks | SwiftUI/`_NS:` ids dropped, actions rendered without `AX` prefix, Press/Raise/ShowMenu/Pick hidden | exceeded |
| Coordinate actions miss the Simulator (`windowNotFoundAtPosition`) | CGEvent `postToPid` at window-relative points hits the iOS canvas; `[offscreen]` flag for rotated frames | exceeded |
| `typeText` silently types nothing on iOS; `paste` times out | `type_text(element)` inserts via AX selected text and **reads back** to verify, else keystrokes; paste restores the pasteboard | exceeded (verify on iOS text fields remains on the checklist) |
| Selected / Selected text trailers | `Focused element: [n]` + `Selected text: "…"`; `[selected]` inline flags | matched |
| Container child cap `(showing 0-100 of N)` | global 1,500-node cap with `… (tree truncated …)`; uninformative containers elided | different; watch long iOS lists |
| No window parameter (handle follows key window) | `get_app_state(window:)` pins a window; header lists the others | exceeded |
| `super+q` via Raise + key chord | `press_key` maps ⌘-chords to the matching menu item (File › Quit) without activation | matched |
| Arrow keys reach the Mac app; tvOS unproven | posted keystrokes to the pid; tvOS untested here too | matched; **open**: test tvOS focus keys with a screenshot diff |
| Continuous `SCStream` of the controlled window → macOS's screen-recording indicator (Control Center `AudioVideoModule` menu-bar item, names the app and window); live thumbnails and a badge in the ChatGPT window (RemoteHostedPIP) | `ShareIndicator` holds a 1 fps `SCStream` on the window being worked on, so the same system indicator shows while a session is active (verified with `scripts/check-indicator.swift`); released after 90 s idle or exit; `LEAP_SHARE_INDICATOR=0` disables. No thumbnail panel (Claude Code has no place to show one) | matched (indicator); gap (thumbnails, cosmetic) |
| Singleton service + thin clients (`computeruse.sock`), `turn-ended` hook | one server per Claude Code session, idle reaper | gap (architecture follow-up) |
| Auto-relaunch after reinstall (`getApp` by path) | `AppResolver.resolve` launches in the background if not running | matched |
