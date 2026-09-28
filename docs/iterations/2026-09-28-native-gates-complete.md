# 2026-09-28 — Checkpoint 7 native: Blender reopen, background Command-clicks, iPhone persistence

## Outcome and evidence

Native on db83c8d (restarted; Blender left open by the user):
- Blender reopen through Blender's Open dialog: Cmd+O; the installed hover move armed the directory field
  on the first click (the pre-fix build needed a dev-build retry); typed the test folder; double-click
  on `leap-mickey-0928.blend` opened it (window title/AXDocument changed; Outliner and properties show
  the three spheres; `artifacts/test-runs/20260928-blender/reopened.png`). Gate: modeled, saved,
  reopened.
- Background Command-click (Blender frontmost): Gameday Playbook tab coordinate click navigated (130
  changes, `passed`). The first step's expectation already held and was flagged
  `expectation_met_before: true` with the explanatory note (false-pass guard works natively).
- Second app: Calculator (launched and quit for the test, no user content), four background coordinate
  clicks 7 + 5 = changed the display 0 → 12. Compact legacy result (`afterQuality {complete,nodes}`).
- iPhone: reopening via Edit play opened the current play (a different record) → honest `failed`; the
  play list exposes only laid-out rows (iOS, same as Sky §6), so the new play needs scrolling. Read-only
  database check (Simulator container playbook.sqlite, `mode=ro`) found the `play` record
  "LEAP IPHONE 0928 CP5" with its notes: persistence confirmed; UI reopen pending.

## User direction

Agents normally drive Blender through its Python API (construction and rendering) and use the UI only
for what the API cannot do. The earlier plan requirement to model "without a construction script" is
superseded: the UI-only run above was a capability trial (it found the hover and capture issues);
normal Blender work follows skills/leap-3d-game-workflows (API-first, Leap for inspection/UI-only tasks).

## Changes

Documentation only: PLAN status, Blender reference notes (hover-armed clicks, secondary-window capture
caveat, API-first). Skills synced with `make skills`.

## Remaining work

iPhone UI reopen via list scroll; scroll-in-list primitive for iOS laid-out rows (Sky: same limit);
Blender secondary-window capture fallback (screen-region capture); keep exercising general apps.
