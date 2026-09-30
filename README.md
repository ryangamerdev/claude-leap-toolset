# Leap

Open-source computer use for AI agents. Leap is a Model Context Protocol (MCP) server that lets
an agent (Claude Code, OpenCode, or any MCP client) read and operate native desktop
applications through the platform accessibility tree, the way a screen reader does, with
screenshots as the fallback rather than the default.

It runs locally, works in the background without taking your mouse, keyboard or frontmost
window, and records what it did so an agent (or you) can review the evidence afterwards.

**Status:** macOS is implemented and in daily use. **Windows is not implemented yet and is the
most wanted contribution**; see [Porting Leap to Windows](docs/WINDOWS-PORT.md) and the pinned
tracking issue. Linux contributions are welcome too.

License: [GPL-3.0-or-later](LICENSE). Forks and derivative works must stay under the GPL.

## Why Leap

Commercial assistants now ship "computer use" for the Mac and Windows, but they are
proprietary and tied to one vendor's models and accounts. Leap provides the same class of
capability as an open, model-agnostic building block anyone can inspect, extend and self-host.

Compared with other open projects in this space, Leap combines in one server:

- **Accessibility-first observation.** `get_app_state` returns the key window as a compact,
  indexed text tree with stable element indices and line diffs between states, so most steps
  need no image at all.
- **Background operation.** Actions go through accessibility actions (`AXPress`, value and
  selected-text writes) first, then events posted directly to the target process. No tool
  activates the app, takes keyboard focus or moves the real cursor unless you opt in with
  `foreground: true`.
- **Verified multi-step workflows.** `ui_perform` runs up to 50 steps with fresh targeting,
  preconditions, bounded waits and expectations. Execution, dispatch and verification are
  reported separately, and uncertain input is never replayed.
- **Durable evidence.** Observations, inputs, outcomes and failure screenshots are journaled
  in a project-local SQLite store and can be queried after a restart (`recording_*`,
  `interaction_*`, `session_history`, `ui_diff`, `diagnostic_query`).
- **iOS Simulator.** Guest apps can be driven through a pinned WebDriverAgent runner (`wda`
  backend) or through the Simulator/Device Hub accessibility tree.
- **Visible activity.** A coloured pointer wedge and ripple show where the agent acts, and the
  macOS screen-recording indicator names the window being operated.
- **Agent skills.** [skills/](skills) contains the playbooks agents load on demand.

Related open projects worth knowing (each covers part of this space): agent-desktop,
Cua Driver, open-computer-use, Peekaboo, Windows-MCP, mobile-mcp and appium-mcp. Contributions
that borrow good ideas across projects are welcome, subject to each license.

## Two properties that matter

**You keep your computer.** Text goes in through the accessibility text system, buttons through
AX `Press`, and anything left over is posted to the target process. You can keep typing in your
own window while the agent works in another app. `foreground: true` is an explicit opt-in for
apps that ignore posted events; it interrupts you, so the bundled skill tells the agent to ask
first.

**You can see what it is doing.** Leap draws its own pointer: a filled wedge whose tip sits on
the action, coloured by action (coral = click, teal = edit, blue = scroll, violet = drag,
grey = read), with one sonar ring per interaction. It is a click-through overlay that never
takes focus. `LEAP_OVERLAY=0` disables it. While a session is working in a window, Leap also
holds a small ScreenCaptureKit stream on it so macOS shows its own recording indicator naming
the window; frames are discarded and the stream is released after 90 s idle
(`LEAP_SHARE_INDICATOR=0` disables it).

## Requirements (macOS)

- macOS 14 (Sonoma) or later. Developed on macOS 14 through 27.
- A Swift 6.1+ toolchain. `scripts/install-swift-pkg.py` installs a pinned swift.org toolchain
  user-scope if your Xcode is older.
- Permissions granted once to **Leap** (the signed app bundle):
  - Privacy & Security > **Accessibility**: required.
  - Privacy & Security > **Screen & System Audio Recording**: required for screenshots only.
  The `permissions` tool reports both and can raise the prompts.
- For the `wda` Simulator backend: Xcode and a booted Simulator (see `scripts/wda.py`).

## Install for Claude Code

```bash
git clone https://github.com/gignit/leap-mcp.git
cd leap-mcp
python3 scripts/install.py
```

This builds and signs `dist/Leap.app` if needed, copies it to `~/Applications/Leap.app`
(with `ditto`, so the signature and permission grants survive), copies each skill under
`skills/` to `~/.claude/skills/<name>`, creates `~/.config/leap/leap.json` if absent, and
registers the `leap` MCP server at the installed path. Restart the Claude Code session
afterwards. `--uninstall` reverses it; `--skills-only` refreshes only the skills.

Signing: `scripts/bundle.py` uses the first code-signing identity it finds, or
`--identity "Developer ID Application: ..."`. An ad-hoc signature (`--identity -`) works, but
macOS will ask for permissions again after each rebuild.

Manual registration:

```bash
claude mcp add --scope user leap -- ~/Applications/Leap.app/Contents/MacOS/leap
```

OpenCode (`~/.config/opencode/opencode.json`):

```json
{ "mcp": { "leap": { "type": "local", "command": ["/Users/<you>/Applications/Leap.app/Contents/MacOS/leap"] } } }
```

Any other stdio MCP client can launch the same binary.

### Why an app bundle

macOS attributes privacy permissions to the responsible process, which for a plain binary
launched by an agent host is the host itself. Leap ships as a signed bundle with its own
bundle identifier, and on launch re-executes itself with `responsibility_spawnattrs_setdisclaim`
([Disclaim.swift](Sources/leap/Disclaim.swift), looked up with `dlsym`; if missing, Leap runs
under the host's identity). System Settings then lists **Leap** under Accessibility and Screen
Recording. The bare `swift build` binary does not disclaim, so development runs use the host's
grant.

## Tools

Interactive loop: `list_apps`, `get_app_state`, `click`, `set_value`, `type_text`,
`select_text`, `press_key`, `perform_action`, `scroll`, `drag`, `paste`, `activate`, `batch`,
`wait_for`, `screenshot`, `permissions`.

Intent workflows: `target_list`, `session_open`, `ui_observe`, `ui_inspect`, `ui_perform`,
`session_history`, `session_close`, `verified_action`.

Evidence: `bind_project`, `recording_start`/`stop`/`query`/`nodes`/`review`/`sessions`/`group`,
`interaction_timeline`/`delta`/`result`, `ui_to_text`, `ui_diff`, `leap_asset`,
`evidence_read`, `diagnostic_query`.

Run `python3 scripts/mcp-call.py tools` for full schemas. The playbook agents follow is
[skills/leap/SKILL.md](skills/leap/SKILL.md); configuration is in
[docs/configuration.md](docs/configuration.md).

### State format

```
## Calculator — window "" 574x321 at screen (936,139) [background]
[3] StaticText value="0" desc="main display" id=_NS:16 actions=ShowMenu
  [5] Button "2" desc="two"
```

- `[n]` is the element index used by actions; it is stable for the life of the window.
- Subsequent states are diffs: `+` added, `~` changed, removed indices listed compactly.
- Flags: `[focused] [selected] [disabled] [settable]`; `actions=` lists secondary actions for
  `perform_action`. Frames appear with `include_frames=true`.

## Build and test

```bash
python3 scripts/build.py                     # swift build with the pinned toolchain
python3 scripts/build.py test                # unit tests (or: swift test)
python3 scripts/mcp-call.py tools            # talk to the server like an agent
python3 scripts/mcp-call.py call get_app_state '{"app":"Calculator"}'
python3 scripts/mcp-call.py script Tests/menu-bar.json   # multi-call scenario in one session
python3 -B scripts/test-mcp-handshake.py     # protocol regression
```

`script` mode runs every call against one server process, which is the only way element
indices stay meaningful. `@capture` extracts a value from a result (`$var` substitutes it),
`@expect`/`@absent` assert on it. `make scenarios` replays every scenario.
`LEAP_BIN` selects the binary under test.

## Layout

```
Sources/LeapCore/   accessibility walk, sessions/diffs, actions, input, capture, recording,
                    evidence store, intent workflows, WebDriverAgent client
Sources/leap/       MCP server: tool schemas, dispatch, transport, permissions identity
Tests/              unit tests and JSON MCP scenarios
scripts/            build, bundle, install, MCP client, WebDriverAgent helper, test harnesses
skills/             agent skills installed alongside the server
docs/               configuration, Windows port guide, iteration history
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The highest-impact work right now:

1. A Windows implementation (UI Automation) with the same tool contract.
2. Portable, app-agnostic regression scenarios (for example against TextEdit or Calculator).
3. Linux (AT-SPI) support.

Security reports: see [SECURITY.md](SECURITY.md).

## License

Copyright (C) 2026 Bridgetone, LLC and the Leap contributors.

Leap is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version. It is distributed WITHOUT ANY WARRANTY; see
[LICENSE](LICENSE).
