# 2026-09-30 — Native retest pass; v2 perform_action/select_text/paste; quieter diagnostics; macOS 27 indicator

## Outcome and evidence

- Native retest of follow-up items A, C and B passed in OpenCode on installed a176ad4 (IDs in
  docs/followup/2026-09-29-ui-ax-lessons-retest.md). User direction: user-interaction detection is a
  separate, non-critical follow-up (docs/followup/2026-09-30-user-intervention-detection.md); proceed
  with the other fixes.
- Fixes, with the evidence that motivated each:
  1. **Diagnostics trailer.** Every response carried `capture_quality` for advisory-only failures
     (blocking=0), repeating the text line removed on 09-29.
  2. **Missing v2 steps.** ui_perform lacked Sky's perform_secondary_action / select_text / paste
     primitives (parity chart).
  3. **paste.** Harness: background ⌘V left Gameday's search field unchanged ("OSCAR TEMPO").
  4. **Unknown grade on a clear mismatch.** The same run graded the mismatch `unknown`: the last quick
     read before the deadline had about 0 s of budget and came back incomplete. This was introduced
     by C (2026-09-29).
  5. **Menu opening.** menu-bar scenario: AXPress on a background menu title succeeded, but the state
     showed no menu. The 09-18 open check (f120db5) had been dropped in cc5e90a (09-20 safeguards).
  6. **Indicator checker.** share-indicator failed on macOS 27. Control Center status items are no
     longer windows; menu extras belong to MenuBarAgent. An AX read shows
     `com.apple.menuextra.audiovideo` while Leap streams, so ShareIndicator works and only the checker
     was stale.

## Sky reference and rationale

- The v2 steps mirror Sky's primitives. For paste, Sky writes the pasteboard and waits for the app
  to read it; it timed out in the Simulator (SKY-BEHAVIOR §5). Leap differs deliberately for plain
  text into a focused text element: it inserts through the accessibility text API with read-back, as
  press_key ⌘V already does, which works in the background and is verified. HTML and non-text focus
  keep the pasteboard route.
- Menu open: Sky returns the opened menu after a title click (after its settle). Leap waits for the
  menu to open and never re-presses, because a late-opening menu would close again. This keeps the
  09-20 no-replay rule and restores the 09-18 behavior.
- Waits: Leap-only feature. A check now ends on its last complete read rather than starting one it
  cannot finish.

## Changes

- `capture_quality` logs at info level when nothing limits the read (still durable).
- ui_perform (mac_ax): `perform_action` (selector, `name`), `select_text` (selector, `text`,
  `prefix`/`suffix`, `selection_type`), `paste` (`text`, `html`), each validated before any input.
- `Engine.paste`: verified accessibility insertion for plain text into a focused text element.
- `automationCheck`: keeps the last complete read; skips reads with less than 0.3 s left.
- `Engine.click`: AXMenuBarItem press polls up to 1 s for the menu's visible items.
- scripts/check-indicator.swift reads the AX extras menu bar (macOS 27), with the window list as
  fallback.
- Scenarios reach their start screen through the guest Home button; share-indicator waits 3 s.
- Skill and SPECIFICATION updated.

## Validation and delivery

- `make test`: 69 tests, 0 failures.
- Harness, dev bundle, Gameday:
  - set_value → select_text → type_text gave "OSCAR TEMPO" (passed).
  - perform_action Confirm → select_text cursor_after → paste " X" gave "OSCAR TEMPO X" (passed,
    `check_ms` 319); the field was cleared afterwards.
  - A perform_action without a selector was refused before any input.
  - A mismatched wait with `timeout: 3` now returns `failed` at 3013 ms.
- Scenarios (local-only logs in artifacts/test-runs/20260930-fixes/): desktop 7/7; Simulator
  ios-type-text, menu-bar and simulator-offscreen-press pass twice in varied order; share-indicator
  passes. The indicator was confirmed ON for Gameday and Device Hub reads.
- Not native acceptance for the new steps; the installed build needs a restart.

## Remaining work

- Native check after restart: a v2 paste/select_text/perform_action workflow; the menu open wait.
- The user-interaction detection follow-up (deferred).

Installed 2026-09-30T00:56:15Z via `make install` from the commit containing this entry. Binary SHA256
`a32b70d4eafd1b40f6cf6d55bc852953b36c0b89c37314a10facb2b8f6fb4b7e`. Signature verified; claude-leap skills match; registration `leap` unchanged (Claude Code; OpenCode points
at the same installed binary). Loaded MCP not yet restarted onto this build.

Addendum (user direction): scripts/install.py no longer installs this repo's skills into Codex
(`$CODEX_HOME/skills`). It removes stale copies on install, `--skills-only` and `--uninstall`. The
claude-leap, leap-3d-game-workflows and app-store-screenshots copies were removed from ~/.codex/skills.
AGENTS.md updated. Codex keeps Sky and the Xcode MCP.
