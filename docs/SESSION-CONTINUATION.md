# Session continuation — claude-leap (read this first after compaction)

Repo: `~/src/claude-leap` → github.com/ryangamerdev/claude-leap-toolset (branch main, push after every meaningful commit).
Owner: Ryan Wyler (ryan@bridgetone.com). Working dir of the Claude Code session is `~/src/gameday` (a *different* repo — his SwiftUI football app; don't commit there).

## Goal
Build **claude-leap**: a native macOS computer-use MCP server that gives Claude parity-or-better with
ChatGPT Desktop / Codex "Computer Use" (OpenAI's **Sky** service). Parity is judged against the
recorded Codex session for Ryan's Gameday app, not against guesses.

## Non-negotiable working rules (Ryan has corrected me on each of these)
1. **Never guess; check how Sky/Codex did it first.** Sources, in order: the Codex rollout transcript
   (`/tmp/astra/full-transcript.txt`, per-call, 3,550 records), Sky's API doc it hands the model
   (`/tmp/astra/sky-api-doc.md`), Sky's binary (`~/.codex/computer-use/Codex Computer Use.app/Contents/MacOS/SkyComputerUseService`
   — use `nm -u` for imports and `strings`), live observation via the monitors below.
2. **No output truncation that hides failures.** Don't pipe through `head`/`tail`/`sed -n` to "summarize";
   use Python scripts that print full output and exit codes (`scripts/*.py` are the pattern). GNU `timeout`
   does not exist on this Mac.
3. **Don't invent patterns.** I invented a ppid watchdog once; Sky uses flock singleton + client refcount +
   inactivity timeout. I replaced it. Same for anything else: confirm the pattern, then implement.
4. **Never steal focus or move the real cursor.** `foreground: true` is an explicit opt-in only.
5. **Overlay**: the pointer is a *face emoji* (facial expressions only, random per action kind) that
   **pulses once, slowly** (no rocking, no double-thump), plus one sonar ring per action. Ryan sees it.
6. Commit messages carry the rationale. **No `Co-Authored-By` trailer** (his global CLAUDE.md).
7. When the bundle is rebuilt, **tell him to restart the session** so the registered MCP picks it up.
8. Close the loop: exercise real behavior (drive Gameday/Simulator) before claiming done.

## Architecture (what exists, all working)
- Swift package, tools-version 5.10, built with the **swift.org 6.4.0 toolchain** (`TOOLCHAINS=org.swift.640202609131a`;
  Xcode 16.0 ships 6.0 and the MCP Swift SDK 0.12.1 needs 6.1+). `scripts/build.py`, `scripts/bundle.py`
  (→ `dist/claude-leap.app`, signed **Developer ID Application: BRIDGETONE, LLC**, bundle id `com.bridgetone.claude-leap`).
- Registered in Claude Code at user scope as `leap` → `dist/claude-leap.app/Contents/MacOS/claude-leap`.
  Permissions (Accessibility + Screen Recording) are granted to **claude-leap** itself thanks to
  `Disclaim.swift` (`responsibility_spawnattrs_setdisclaim` re-exec, only when running from the bundle).
- `Sources/LeapCore`: AXTree (walker; per-attribute fallback for Chromium; offscreen elements kept and
  flagged; SwiftUI id noise filtered; AXShowMenu hidden), AppSession (content-keyed **stable indices**,
  diff, stale-element guard, sets AXManualAccessibility/AXEnhancedUserInterface), Engine (actions;
  window targeting via `get_app_state(window:)`; label targeting; **AX-first press_key**: menu items by
  key equivalent, ⌘A/C/V/X via AX text API, Return→AXConfirm, Escape→AXCancel, keystroke fallback),
  Input (CGEvent postToPid fallback), Capture (ScreenCaptureKit window shots, 1 px = 1 pt), Overlay (face pointer).
- `Sources/claude-leap`: MCP server (tools: list_apps, get_app_state, screenshot(save_path), click, drag,
  scroll, press_key, type_text, set_value, perform_action, paste, activate, batch, permissions),
  Inactivity (idle timeout, Sky pattern), Disclaim, main (AppKit run loop, .accessory).
- Test harness: `scripts/mcp-call.py` (`tools` / `call` / `script FILE.json` with `@capture`/`@expect`);
  `LEAP_BIN=dist/...` to exercise the bundle. Tests in `tests/*.json`. `scripts/mine-codex-cua.py --stats`.

## Verified facts about Sky (evidence, not inference)
- Imports (nm -u): AXUIElementPerformAction/SetAttributeValue/CopyElementAtPosition, SCScreenshotManager,
  SCShareableContent, SCStream, NSRunningApplication, CGEventGetFlags. **No CGEventPost, no
  AXUIElementPostKeyboardEvent** → Sky never synthesizes input. Clicks = AX Press (coords → CopyElementAtPosition);
  typing = AX text API; ⌘chords = menu items; arrows/Return on tvOS Simulator produced "no change" every time.
- Architecture: one flock-guarded singleton service (`computeruse.sock.lock`) + thin per-connection MCP
  clients over a Unix socket; `shouldTerminateWhenNoClientsRemain`; `inactivityTask`; `turn-ended` notify hook.
- UI: virtual cursor (`VirtualCursor`/`CursorView`, overlay window) that rocks; a blue "remote control"
  badge on the controlled window's title bar; live thumbnails of controlled apps streamed into the chat
  (`RemoteHostedPIP*`, SCStream video) — **claude-leap lacks the badge and the live thumbnails**.
- Tree format: no coordinates; menu bar included in tree; removed elements as ID ranges; trailing
  "The focused UI element is …" line; append-only IDs (mine are stable by content — better; keep).
- "The user changed X. Re-query…" = its stale-state guard (I have staleElement).

## In flight right now (state as of 2026-09-18 ~19:55 PT, just before compaction)
Last commit: d39998e. Bundle rebuilt and matches HEAD; Ryan has NOT yet restarted the session since
the last rebuild — tell him to restart so the registered `leap` server picks up: AX-first press_key,
Chromium tree support, include_frames/ranges/footer, idle timeout.

1. **Full-detail review of the Codex transcript by sub-agents** — LAUNCHED 2026-09-18 ~19:45 PT: 17 agents,
   one per `/tmp/astra/slice-00..16.txt`, checklist in `/tmp/astra/REVIEW-CHECKLIST.md`, reports to
   `/tmp/astra/report-NN.md`. NEXT STEP after compaction: check which reports exist (`ls /tmp/astra/report-*.md`),
   read them (they are compact), consolidate into `docs/SKY-BEHAVIOR.md` in this repo, then turn findings into
   leap changes. Do not re-run the review. Each agent must read its slice end-to-end (no grep) and
   write `/tmp/astra/report-<slice>.md` answering: per pressKey key → did state change; typeText/setValue/
   paste/selectText behavior+failures; click/drag/scroll by coordinate; Simulator specifics (rotation,
   tvOS focus); anything about activation/focus/cursor/overlay; exact state grammar; timings; error
   taxonomy + recovery; anything Sky does that claude-leap doesn't. Then consolidate.
2. **Live monitors** (may have died with compaction/session restart; check `pgrep`): `/tmp/astra-monitor/monitor`
   (frontmost/mouse/windows 10 Hz → `ui.log`, single writer now), `sampler.sh` (→ `api.log`),
   `log stream` (→ `system.log`). Waiting for Ryan to send Astra a short task
   ("Use Computer Use to open the Formations tab in the Gameday Mac app and take a screenshot") to capture
   the badge/cursor overlay windows (owner/layer/bounds) and confirm frontmost never changes.
3. DONE (commit d39998e): frames off by default (`include_frames`), removed-ID ranges, focused footer.
   STILL TODO: menu bar in the tree — wait for the reviewer reports to see how Sky's state behaves
   after clicking a menu-bar item before copying it.
4. Bigger follow-ups: singleton service + thin client architecture; per-window "remote control" badge;
   optional live preview panel; typing into background **Electron/Chromium** editors does not work
   (Codex uses CDP for browsers) — ChatGPT's composer could not be filled by leap.

## Environment notes
- ChatGPT.app pid ~65223, Sky service pid ~65336 (starts/stops with ChatGPT). iPhone 16 simulator
  (udid 08385748-DE3D-45D0-A0DA-75F69B0191B5) booted with `local.gameday.ios`; app is landscape-only
  by Codex's design (rotate via Simulator toolbar "Rotate"). Gameday Mac app: `~/Applications/Gameday.app`.
- Stale claude-leap processes once blocked all SCK captures (replayd churn) — kill them; idle timeout now reaps.

## Post-compaction status (2026-09-18, after the transcript review)

- All 17 reviewer reports were read; consolidated into `docs/SKY-BEHAVIOR.md` (grammar, ID
  semantics, input evidence, control-plane errors, timing, parity map). Do **not** re-run the review.
- Implemented from it (commit ba8d3d0, bundle rebuilt in `dist/claude-leap.app`): menu bar + open
  menus in the tree, Escape cancels an open menu, relaunch / not-active guards (`actionSession`),
  AX messaging timeout 5 s, `Selected text:` footer, ambiguous-app refusal, label ties prefer the
  pressable element. Tests: `tests/menu-bar.json`, `tests/relaunch-guard.json` (quits and relaunches
  Gameday), plus the three older ones — all pass with `scripts/mcp-call.py script`.
- **The registered `leap` MCP server is still the old bundle until the user restarts the session.**
- Open items, in priority order: (1) verify `type_text` on an iOS Simulator text field with
  read-back (Sky's weakest spot); (2) tvOS focus keys with screenshot diff; (3) long iOS lists vs
  the 1,500-node cap; (4) singleton service + thin clients; (5) per-window remote-control badge /
  live thumbnail panel.
- ShareIndicator (SCStream on the controlled window) added so macOS's own screen-recording
  indicator shows during a session, like Sky. Test: `tests/share-indicator.json`. Bundle rebuilt;
  **restart the session again** to load it.
