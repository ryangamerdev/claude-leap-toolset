# claude-leap

Native macOS computer use for AI agents, built accessibility-first. A stdio MCP server
written in Swift that lets an agent read and operate any Mac app the way a screen reader
does — through the accessibility tree — with screenshots as the fallback, not the default.

It reproduces the architecture that makes ChatGPT Desktop's "Computer Use" effective,
on public APIs only:

| Capability | How |
|---|---|
| Indexed accessibility tree with **stable element indices** and **diffs** between states | `AXUIElement` walk, per-window index registry, line diff |
| Actions **without stealing focus** — the app you're working in stays frontmost | `CGEvent.postToPid`, AX `Press`/`SetValue` when available |
| **Window-scoped screenshots** whose pixel coords equal window points | ScreenCaptureKit `SCScreenshotManager` |
| **Batching** of predictable sequences into one call | `batch` tool; every action can also return the fresh state |
| Background launch of the target app | `NSWorkspace.openApplication(activates: false)` |
| xdotool-style key chords (`super+s`, `ctrl+shift+Tab`, `KP_0`) | `Keys.swift` |

## Requirements

- macOS 14+ (Sonoma). Verified on 14.7.2.
- Swift 6.1+ toolchain (the MCP Swift SDK needs it). Xcode 16.0 ships 6.0, so this repo
  uses the swift.org **6.4.0** toolchain installed user-scope by
  `scripts/install-swift-pkg.py` — no Xcode or OS upgrade required.
- Permissions for the process that launches the server (for Claude Code that is the
  Claude Code helper, shown as **claude** in System Settings):
  - Privacy & Security › **Accessibility** — required for everything.
  - Privacy & Security › **Screen Recording** — required for screenshots only.
  The `permissions` tool reports both and can raise the system prompts.

## Build and test

```bash
python3 scripts/install-swift-pkg.py 6.4.0   # once
python3 scripts/build.py                     # swift build with the pinned toolchain
python3 scripts/build.py test                # unit tests
python3 scripts/mcp-call.py tools            # talk to the server exactly like an agent
python3 scripts/mcp-call.py call get_app_state '{"app":"Calculator"}'
python3 scripts/mcp-call.py call batch '{"app":"Calculator","actions":[{"tool":"click","element_index":20},{"tool":"click","element_index":13},{"tool":"click","element_index":16},{"tool":"click","element_index":6}]}'
```

All scripts print full command output and exit codes; nothing is truncated.

## Register with Claude Code

Add to `~/.claude.json` (user scope) or `.mcp.json` in a project:

```json
{
  "mcpServers": {
    "leap": {
      "command": "/Users/ryan/src/claude-leap/.build/out/Products/Debug/claude-leap"
    }
  }
}
```

`swift build --show-bin-path` (with `TOOLCHAINS=org.swift.640202609131a`) prints the
directory if it moves.

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
