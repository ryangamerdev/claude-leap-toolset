# 2026-09-28 — Blender modeling/save via Leap; hover move before clicks

## Outcome and evidence

Blender (no AX content; screenshots + keys + coordinates), foreground, installed 94d2992 plus dev-build
harness for the save dialog:
- UI-built Mickey head: General scene, delete cube, Add-menu search "uv sphere" (head), second sphere
  `s0.5` `gx-1` `gz1`, Shift+D `x2`. Properties panel showed exact transforms.
- Save As: Blender's file browser defaulted to the user's horror_crossroads project folder; not used.
  Two installed-build clicks on the directory field landed visually (overlay at the field) but did not
  enter edit mode. With a process-directed mouseMoved before mouse-down (dev build), the field entered
  edit mode with its text selected (screen capture). Directory typed; the filename click then missed
  edit mode, so Return saved the default name: `artifacts/test-runs/Untitled.blend` (window AXDocument).
  Nothing was written to the user's Blender project. Moved to
  `artifacts/test-runs/20260928-blender/leap-mickey-0928.blend` (121 KB, tracked evidence).
- Read-only verification (Blender CLI `-b --python-expr` listing objects, no construction):
  Sphere (0,0,0) scale 1; Sphere.001 (-1,0,1) scale 0.5; Sphere.002 (1,0,1) scale 0.5; Camera; Light.
- Screen truth vs capture: SCK window capture of Blender's file browser returned main-window content;
  `screencapture -R` of the same region was correct (see sky-command-click entry).
- User interaction: the user's terminal was frontmost mid-test and the user flagged the open dialog;
  finishing the save raised Blender over it briefly.

## Sky reference

Sky's click builder (0x10072b12c) sends mouseDown/up with no mouseMoved. Leap deliberately differs:
hover-driven UIs (Blender, games, web hover menus) arm a control only after the pointer moves onto it,
and the evidence above shows clicks otherwise land cold. A process-directed move does not move the
user's cursor.

## Changes

Input.click prepends a routed mouseMoved at the click point (same flags, clickGap before mouse-down).

## Validation and delivery

`swift test`: 61 tests, 0 failures. Harness: Blender directory field entered edit mode after the change.

## Remaining work

Native after restart: Blender reopen through the UI (Cmd+O, directory + filename via hover-armed clicks)
and visual check; filename-field click reliability; iPhone reopen; background Command-click on Gameday and
a second app; one Sideline element.

Installed 2026-09-28T21:54:37Z via `make install` from db83c8d. SHA256 `6fe767f7d90e0b04be77996ca29108383f7e28dd5e7235283fe411170b3e480e`. Signature verified; skills match; registration unchanged. Restart pending.
