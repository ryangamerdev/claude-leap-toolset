# 2026-09-30 — Rename claude-leap to Leap

## Outcome

User direction: the product is called **leap** (repo folder `leap-mcp`). Choices confirmed by
question: product `leap`, change the bundle id, rename the GitHub repo.

## Changes

- App `Leap.app`, executable `leap`, bundle id `com.bridgetone.leap` (was `claude-leap.app`,
  `com.bridgetone.claude-leap`). Swift target/source dir `Sources/leap`. The MCP registration name
  `leap` is unchanged.
- Skill `skills/leap` (was `skills/claude-leap`); cross-references in the xcode,
  leap-3d-game-workflows and app-store-screenshots skills updated.
- The installer installs `~/Applications/Leap.app` and removes the pre-rename app and skill copies
  (Claude and Codex) on install, `--skills-only` and `--uninstall`.
- GitHub: `ryangamerdev/claude-leap-toolset` renamed to `ryangamerdev/leap-mcp` (gh); remote updated.
- Host configs: Claude re-registered by the installer; OpenCode `leap.command` points at the new
  binary (backup `opencode.json.bak-before-leap-rename`); the Codex project-trust entry moved from
  `/Users/ryan/src/claude-leap` to `/Users/ryan/src/leap-mcp` (Leap is still not registered in Codex).
- Removed the pre-rename build directory `.build/arm64-apple-macosx` (index with the old paths).
- History (iterations, research, artifacts, review docs) keeps the old name as written at the time.

## Tradeoff

A new bundle id is a new TCC identity: Accessibility and Screen Recording must be granted to
"Leap" once. The old "claude-leap" entries in System Settings can be removed.

## Validation

`make test` 69/69; the release bundle signs as `com.bridgetone.leap`; `claude mcp get leap` and
`opencode mcp list` report the new binary connected. Native tool use awaits the restart and the
permission grant.

## Native acceptance after rename (2026-09-30, OpenCode)

- Permissions: Accessibility granted to "Leap"; Screen Recording still reports MISSING in the running
  process after the grant (macOS applies it to newly started processes; recheck after restart).
- Gameday Mac verification guide, Leap in place of ui-ax: session 60796137. The 49 rendered receiver
  route cards (name + "Used by N") match the read-only database exactly as multisets; the 20 unmatched
  DB routes all sort after the last rendered card (lazy grid, as the guide notes). Interaction
  D1C3F219: Finish editing routes (Used by absent) → Playbook → set_value → select_text → type_text
  ("OSCAR TEMPO") → perform_action Confirm → select_text cursor_after → paste " X" (verified AX,
  clipboard untouched) → cleared. All passed. This is the first native pass of the v2
  select_text/perform_action/paste steps and of verified paste.

## Screen Recording registration (2026-09-30)

Problem: after the rename, "Leap" never appeared under Screen & System Audio Recording.
`permissions(prompt:true)` called a bare `CGRequestScreenCaptureAccess()`; tccd logged "Notifying for
access kTCCServiceScreenCapture … Leap.app", but no list entry was created (Settings listed only
com.bridgetone.claude-leap).

Sky reference: `SlimCore.ScreenRecordingPermission.validateAuthorization(withSystemSettings:)`
(decompiled part-0072.c:16387) opens System Settings at the Screen Recording pane
(`settingsDestination`), checks the Settings window is present (470–600 pt size check), and only then
calls `CGRequestScreenCaptureAccess()`. It also has a drag-in tile fallback (`SystemSettingsAccessCoordinator`).

Change: `Permissions.requestScreenRecording()` opens
`x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`, waits for Settings,
then requests. New `leap --request-permissions` mode (after the TCC disclaim re-exec, so it asks as
"Leap"): Accessibility prompt + Screen Recording request, prints status, exits. `install.py` runs it
after registration, and its closing message names the + fallback.

Evidence: at install, tccd published `Modify kTCCServiceScreenCapture com.bridgetone.leap`, and
SecurityPrivacyExtension listed a new `com.bridgetone.leap` entry (none, then full once enabled). A
fresh `leap --request-permissions` reports accessibility=granted screen_recording=granted.
Tradeoff: the install opens System Settings on the user's screen when Screen Recording is missing.
