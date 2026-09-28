# 2026-09-28 — Sky-traced background clicks (Command flag) and title association

## Outcome and evidence

Sky research (read-only trace of /Users/ryan/src/sky decompiled service; report summarized here):
- Background clicks: `sendClick` (body 0x1006e98a8; flags logic 0x1006e99ec–0x1006e9d4c). If the app is
  not active and not selection-sensitive, Sky sends the click with kCGEventFlagMaskCommand and no
  activation event; macOS operates controls of an inactive window on Command-click without raising
  it. Selection-sensitive targets (web areas, clickingMayCauseSelection, Catalyst menu buttons) use
  enforceActiveState (0x10071e884 → 0x10071a8fc: activation event + down/up at AXActivationPoint, then
  poll AXFrontmost up to 2 s) and click with flags 0. Events: mouseDown/up with window fields 0x5b/0x5c,
  subtype 3, window-local location, posted via postToPid; no mouseMoved. Confidence high for flags.
- Title association: UIElementTreeTransformation.associateTitleUIElements (transform 0x100645230) is
  first in the default pipeline: a child whose AXServesAsTitleForUIElements targets are siblings is
  removed and its text moves onto the targets. Confidence medium-high.

Harness (dev build, background — Blender frontmost throughout): Gameday coordinate clicks on the
Playbook and Route library tabs each navigated (131 changes) with `passed`, where the installed build's
activation-pair delivery produced 0 changes (`failed`). Gameday now reports one "Sideline" checkbox.

Blender gate progress (installed 94d2992, foreground keys/coordinates; Blender exposes no AX content):
General scene → Delete cube → Shift+A search "uv sphere" → head; second sphere `s0.5`, `gx-1`, `gz1`;
Shift+D `x2` → ears at (±1,0,1) scale 0.5 confirmed in the properties panel. Save As opened Blender's
file browser defaulting to the user's /Users/ryan/src/blender/scenes/horror_crossroads/ — not used; a
repo test folder artifacts/test-runs/20260928-blender/ was created. Save/reopen pending.

Finding: ScreenCaptureKit window capture of Blender's secondary "Blender File View" window (correct
CGWindowID, layer 0, exact bounds) returned main-window content; a screen-region capture showed the true
file browser. Blender renders all windows through one GPU context; treat window captures of Blender
secondary windows as unreliable (open).

## Changes

- Input.withPointerGesture takes a BackgroundPointer mode: `.commandClick` (Command flag, no synthetic
  activation) or `.activateWindow` (existing activation pair). Clicks and drags choose by the target role
  (rows, cells, tables, lists, outlines, links, web areas, menu buttons, text inputs → activate;
  otherwise Command), using AXUIElementCopyElementAtPosition for coordinate targets. Caller modifiers
  win. Scroll keeps activation (background scroll passed natively earlier).
- Walker implements associateTitleUIElements: batch includes AXServesAsTitleForUIElements; a child that
  titles only siblings is skipped and its text becomes the target's description when it has none.

## Validation and delivery

`swift test`: 61 tests, 0 failures. Harness results above. Native restart verification pending.

## Remaining work

Native: background coordinate + index clicks on Gameday and another app (Finder sidebar item, a
non-selection button in System Settings or TextEdit toolbar in a new document); Sideline single element.
Finish Blender save to artifacts/test-runs/20260928-blender/ and reopen. iPhone reopen via navigation.
