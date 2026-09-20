# Detailed native UI operations

Read only for text editing, menus, coordinates, screenshots or Simulator-specific behavior.

## Reading the tree

- `[42] Button "Save" [settable] [selected] [disabled] [focused] actions=ShowMenu,Cancel`.
  Indices are content-keyed within the current window session. Reobserve after state changes;
  label changes and replaced or recycled nodes can change identity. The tool validates targets.
- `disable_diff=true` for a full tree; `include_frames=true` only when you need coordinates.
- Header: `## App — window "Title" WxH at screen (x,y) [background|frontmost]`, then
  `Other windows of App: …` — `get_app_state(window: "iPhone 16")` targets one and sticks.
- Footer: `Focused element: [n]`, `Selected text: "…"` (what the user has selected is often what
  they mean).
- `[offscreen: coords unreliable]` elements are still pressable by index (Simulator after rotation).
- `MenuBar` / `MenuBarItem "Window"` lines are the app's menu bar. Click a title: the menu opens on
  screen without activating the app and the diff lists its `MenuItem`s to click (this is how you
  switch Simulator device windows — Window › "iPhone 16 – iOS 18.0" — or quit: File › Quit).
  `press_key Escape` or `perform_action Cancel` closes it.
- iOS elements: labels in `desc=`, `actions=Cancel` on everything, SF Symbol names as `id=`.
  Only laid-out rows are present on iOS; Mac lists expose all rows.

## Text entry (what actually works)

- Replace: `set_value(element, value)`. Accessibility paths are verified by read-back (clearing
  with `""` works; numeric/boolean controls take numbers / true|false). If a write changed the field
  into something unexpected you get an "Outcome uncertain" error and nothing is retried — read the
  state and decide.
- Append / type: `type_text(element_index, text)`. Accessibility insert (verified) → accessibility
  value append (verified) → keystrokes. The result text says which path ran; the **keystroke path is
  dispatched, not verified**, so confirm it in the returned diff. In the iOS Simulator keystrokes are
  not delivered to a background window; the accessibility paths are what work there.
- Edit inside text: `select_text(element, text, prefix, suffix, selection_type)` then `type_text`
  (replaces the selection) or `selection_type: cursor_after` then type to insert.
- `type_text` sends `\n` as Return and many composers submit on Return: use `set_value` or `paste`
  for multi-line text. `paste(text, html)` restores the user's clipboard afterwards.
- `press_key` ⌘-chords press the matching menu item (File › Quit, Edit › Select All via the AX
  text API); Return → AXConfirm, Escape → AXCancel / close menu; else a keystroke to the focused
  element. Focus the field first (set_value/type_text with element_index) unless it is an
  app-level shortcut. `press_key` targets the app; it cannot fire global shortcuts. With a pinned
  window that is not the app's key window, leap makes it key first or refuses with a clear message
  rather than typing into the wrong window.
- `paste` is dispatched (⌘V) and restores the user's clipboard only if they did not copy something
  in the meantime; verify insertion in the diff.

## Errors you will see and what to do

- `The UI changed since the last state: element [n] …` — the user or the app moved things;
  `get_app_state` and use fresh indices. Nothing was done.
- `<App> was relaunched (new process) since the last state` — quit/crash/reinstall; call
  `get_app_state`, the header says `[new process … indices restart]`.
- `No state has been read for <App> in this session` — call `get_app_state` before using indices.
- `"Label" is ambiguous (N matches): …` — use the listed `element_index`.
- `Ambiguous app "…": several copies share it` — pass the full `.app` path.
- `cannotComplete` — acknowledgement is uncertain. Inspect returned state/check evidence; never repeat input solely because this error occurred.
- `Outcome uncertain: …` — a write changed the field but not into the expected text. Not retried.
- `Batch stopped at step N … Completed steps (already applied)` — resume after the listed steps.
- `wait_for timed out …` — the condition never held; the last observed element state is included.
- `(action applied; state unavailable afterwards …)` — the action ran (e.g. Save closed the
  window); only the follow-up read failed. Do not repeat the action; call `get_app_state`.
- `Keyboard input would go to … key window, not to the selected window` — use accessibility edits
  by element_index, or `foreground=true`.
- Screenshot unavailable → the window is minimized or on another Space.

## Capturing screens to files

`screenshot(app, save_path)` writes the window to disk (parent folders created) and returns only
a text confirmation, so you can capture many screens without flooding context; add `embed=true`
to also see one inline. Target a device with `window` (`"iPhone 16"`, `"iPad Air"`). For a
documentation pass, save under `docs/screenshots/<app-version>/<platform>-<screen>-<kind>.png`,
e.g. `docs/screenshots/0.19.0/desktop-playbook-main.png`, `ipad-flashcards-main.png`. Navigate to
each screen (click the tab, read the text state to confirm you are there), then capture.

## Coordinates and foreground

- Prefer indices. Use `x,y` (window points; get them from `include_frames=true` or the screenshot,
  which is 1 px per point at scale 1, crops included) for canvases without accessibility: Blender's
  viewport, drawing surfaces, the iOS "Football field"-style custom views, segmented controls with
  no children. Coordinate clicks/drags are posted to the app's process in the background; they are
  **dispatched, not verified** — most apps honour them, some canvases do not, so check the diff or
  a screenshot. Coordinates are re-based on the window's current position at action time.
- `foreground=true` explicitly activates the app when synthesized input is needed. Mouse
  gestures retain the same window-targeted delivery in either mode and never move the real
  cursor. Click, drag, and wheel delivery share scoped synthetic-focus preparation/cleanup.
  Keyboard fallback may still use system HID events. Announce explicit activation because it
  changes the user’s frontmost app.

## Simulator specifics

- `get_app_state("Simulator", window: "iPhone 16")`; the simulated app's tree is exposed for
  iPhone/iPad. tvOS exposes **no app content** — for Apple TV use screenshots and `press_key`
  Up/Down/Left/Right/Return, and confirm with a second screenshot.
- Rotate / device switching: toolbar `Rotate` button, or the Window menu (see above).
- After reinstalling the app under test, the tree comes back as a fresh subtree; read state again.
