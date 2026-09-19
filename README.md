# claude-leap

Native macOS computer use for AI agents, built accessibility-first. A stdio MCP server
written in Swift that lets an agent read and operate any Mac app the way a screen reader
does — through the accessibility tree — with screenshots as the fallback, not the default.

It reproduces the architecture that makes ChatGPT Desktop's "Computer Use" effective,
on public frameworks (Accessibility, CoreGraphics events, ScreenCaptureKit) plus one
private libsystem call, `responsibility_spawnattrs_setdisclaim`, looked up with `dlsym` at
launch so the signed bundle owns its own TCC identity ("claude-leap" in System Settings).
If the symbol is missing the server logs that and runs under the launching app's identity
instead; nothing else depends on it.

| Capability | How |
|---|---|
| Indexed accessibility tree with **stable element indices** and **diffs** between states | `AXUIElement` walk, per-session index registry, line diff |
| Actions that **never steal focus** and **never move your cursor** | AX `Press` / `SetSelectedText` / `SetValue` first, `CGEvent.postToPid` otherwise |
| **Window-scoped screenshots** whose pixel coords equal window points | ScreenCaptureKit `SCScreenshotManager` |
| **Batching** of predictable sequences into one call | `batch` tool; every action can also return the fresh state |
| Background launch of the target app | `NSWorkspace.openApplication(activates: false)` |
| xdotool-style key chords (`super+s`, `ctrl+shift+Tab`, `KP_0`) | `Keys.swift` |
| **Visible activity indicator** — a virtual pointer + sonar ripple where the agent acts | `Overlay.swift`, a click-through `screenSaver`-level window |

## Two properties that matter

**You keep your computer.** No tool activates an app, takes keyboard focus, or moves the
real cursor. Text goes in through the accessibility text system (which SwiftUI and AppKit
bindings observe), buttons go through AX `Press`, and anything left over is posted straight
to the target process. You can keep typing in your own window while the agent works in
another app. `foreground: true` is an explicit opt-in for apps that ignore posted events;
it interrupts you, so the agent is instructed to ask first.

**You can see what it is doing.** Because the agent never borrows your cursor, it draws its
own: a pointer glyph with a drop shadow that pulses slowly, plus a coloured ripple that
expands and fades at each interaction (coral = click, teal = edit, blue = scroll, violet =
drag). It is a click-through overlay at screen-saver window level, so it floats over
everything, is never clickable, and never takes focus. `LEAP_OVERLAY=0` disables it.

**macOS shows it too.** While a session is working in a window, leap holds a tiny
ScreenCaptureKit stream on that window, so macOS lights its own screen-recording indicator in
the menu bar (the Control Center item whose menu names the capturing app and the window). That
is the same system signal you see during ChatGPT's computer use; it is not a remote-desktop
feature, just a consequence of streaming a window. Frames are discarded; the stream is released
after 90 s idle. `LEAP_SHARE_INDICATOR=0` disables it; `tests/share-indicator.json` verifies it.

Verify it is really there without needing Screen Recording:

```bash
swiftc -O -o /tmp/check-overlay scripts/check-overlay.swift && /tmp/check-overlay
# owner="claude-leap" layer=1000 alpha=1.0 bounds=0,0 1728x1117
```

## Requirements

- macOS 14+ (Sonoma). Verified on 14.7.2.
- Swift 6.1+ toolchain (the MCP Swift SDK needs it). Xcode 16.0 ships 6.0, so this repo
  uses the swift.org **6.4.0** toolchain installed user-scope by
  `scripts/install-swift-pkg.py` — no Xcode or OS upgrade required.
- Permissions, granted once to **claude-leap** (the signed bundle — see below):
  - Privacy & Security › **Accessibility** — required for everything. macOS shows a
    dialog on first use; accept it.
  - Privacy & Security › **Screen Recording** — required for screenshots only. macOS
    does *not* show a second dialog: it adds **claude-leap** to the list unchecked. Open
    the pane and switch it on. (`open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"`
    — System Settings may flash its previous pane first; that is a known deep-link quirk.)
  The `permissions` tool reports both and can raise the prompts.
  Dev builds run under Claude Code's own grant (its helper is listed as **claude**).

## Build and test

```bash
python3 scripts/install-swift-pkg.py 6.4.0   # once
python3 scripts/build.py                     # swift build with the pinned toolchain
python3 scripts/build.py test                # unit tests
python3 scripts/mcp-call.py tools            # talk to the server exactly like an agent
python3 scripts/mcp-call.py call get_app_state '{"app":"Calculator"}'
python3 scripts/mcp-call.py call batch '{"app":"Calculator","actions":[{"tool":"click","element_index":20},{"tool":"click","element_index":13},{"tool":"click","element_index":16},{"tool":"click","element_index":6}]}'
python3 scripts/mcp-call.py script tests/index-stability.json   # multi-call test in ONE session
```

`script` mode runs every call against a single server process, which is how Claude Code
uses it — and the only way element indices are meaningful, since the registry lives in the
server. `@capture` pulls a value out of the previous result (`$var` substitutes it into
later calls) and `@expect` asserts on it, so tests do not hardcode indices.

All scripts print full command output and exit codes; nothing is truncated.

## Build the app bundle (own permissions identity)

```bash
python3 scripts/bundle.py        # release build → dist/claude-leap.app, signed with your Developer ID
```

macOS attributes privacy permissions to the *responsible process*, which for a plain
binary launched by Claude Code is Claude Code itself — so prompts say "claude" and the
grant belongs to it. The bundle fixes that two ways: it has its own bundle id
(`com.bridgetone.claude-leap`) and Developer ID signature, and on launch the binary
re-execs itself with `responsibility_spawnattrs_setdisclaim` ([Disclaim.swift](Sources/claude-leap/Disclaim.swift))
so TCC treats it as its own responsible process. `tccd` then logs
`Sub:{com.bridgetone.claude-leap} Resp:{identifier=com.bridgetone.claude-leap}` and
System Settings shows **claude-leap** under Accessibility and Screen Recording. Grant
both once; the Developer ID signature keeps the grant valid across rebuilds.

The bare `swift build` binary deliberately does *not* disclaim (it would end up under an
unsigned identity with no grants), so dev runs keep using the grant given to Claude Code.

## Install for Claude Code (server + skill)

```bash
python3 scripts/install.py
```

This builds and signs the bundle if needed, registers the `leap` MCP server at user scope, and
symlinks `skills/claude-leap` into `~/.claude/skills/claude-leap`. Restart the Claude Code session
afterwards. `--uninstall` reverses it.

**Why a skill as well as server instructions.** Claude Code truncates long MCP server
instructions (the model sees roughly the first 2 KB), so the server's `instructions` string is
kept to a short summary and the full playbook — tree grammar, menu-bar navigation, what text
entry works where (including the iOS Simulator), the error strings and what to do about them,
Simulator specifics, verification habits, and the confirmation policy — lives in
[skills/claude-leap/SKILL.md](skills/claude-leap/SKILL.md), which the model loads on demand.
This mirrors how ChatGPT's computer use ships: a bundled plugin whose `SKILL.md` explains the
tools, with the service itself saying very little.

Manual registration, if you prefer:

```bash
claude mcp add --scope user leap -- /Users/ryan/src/claude-leap/dist/claude-leap.app/Contents/MacOS/claude-leap
```

or in `~/.claude.json` / a project `.mcp.json`:

```json
{
  "mcpServers": {
    "leap": {
      "command": "/Users/ryan/src/claude-leap/dist/claude-leap.app/Contents/MacOS/claude-leap"
    }
  }
}
```

For development against the debug build, `LEAP_BIN=…/.build/out/Products/Debug/claude-leap`
makes `scripts/mcp-call.py` use that binary instead.

## Tools

`list_apps`, `get_app_state`, `screenshot`, `click`, `drag`, `scroll`, `press_key`,
`type_text`, `set_value`, `perform_action`, `paste`, `activate`, `batch`, `permissions`.
Run `scripts/mcp-call.py tools` for the full schemas. The server's `instructions`
(sent on `initialize`) describe the intended workflow to the agent.

### State format

```
## Calculator — window "" 574x321 at screen (936,139) [background]
[3] StaticText value="0" desc="main display" id=_NS:16 @17,22 545x56 actions=ShowMenu
  [5] Button "2" desc="two" @398,224 59x49
```

- `[n]` is the element index used by actions; it is stable for the life of the window.
- `@x,y w×h` are window-relative points. With `scale=1` (default) the screenshot is
  1 px per point, so the same numbers address the image.
- Subsequent states are diffs: `+` added, `~` changed, `-` removed, unchanged omitted.
- Flags: `[focused] [selected] [disabled] [settable]`; `actions=` lists secondary
  accessibility actions for `perform_action`.

## Layout

```
Sources/LeapCore/      AXTree, AppSession (indices + diff), Engine (actions), Input (CGEvent),
                       Capture (ScreenCaptureKit), AppResolver, WindowInfo, Keys, Permissions
Sources/claude-leap/   MCP server: tool schemas, dispatch, agent instructions
Tests/LeapCoreTests/   unit tests
scripts/               install-swift-pkg.py, build.py, mcp-call.py, mine-codex-cua.py
```

## Comparison notes

`scripts/mine-codex-cua.py THREAD_ID` reads a local Codex rollout (read-only) and prints
how its computer-use REPL was actually used — useful for keeping this project honest
about what "as good or better" means.
