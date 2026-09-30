# 2026-09-29 — Xcode 27 agent tools for devices (research, skill guidance)

## Outcome and evidence

User asked to check Apple's documentation on how agents interact with Device Hub. Findings and
live probes: [research note](../research/xcode27-device-interaction.md). In short:
- Device Hub itself is a human UI whose only automation surface is a URL scheme.
- Apple's agent route is the Xcode MCP server (`xcrun mcpbridge`) and its DeviceInteraction tools:
  device-point touches, gestures, hardware buttons, device keyboard, orientation, and a hierarchy
  with `hitPoint`s.
- Probe on an iOS 27 iPad (M4): after approval (triggered by XcodeOpenWorkspace on Gameday),
  capture took 1.1 s and tapping the Settings hitPoint opened Settings in 1.9 s.
- The Gameday iOS 18.0 simulators are not eligible.

## Sky reference and rationale

Sky has no Device Hub or Xcode integration; it used host accessibility for the Simulator, with the
same rotation and typing limits as Leap's mac_ax route. Apple's tool is better for iOS 27+ guest
apps, so the skill now points agents to it there. Leap stays the route for Mac apps, older runtimes,
Device Hub chrome and evidence-backed workflows. A Leap `xcode` backend wrapping mcpbridge (in
place of the WDA runner) is a candidate awaiting a user decision: it requires Xcode to be running
and an approval flow.

## Changes

- The skill's ui-details reference now contains Xcode DeviceInteraction guidance.
- Research note added; tool schemas and probe transcripts retained in
  artifacts/reference/xcode27-agent/. Exported Apple skills are ignored (regenerable).
- No binary change.

## Validation and delivery

Probes only (the Xcode MCP was driven directly through a stdio client; this is not Leap acceptance).
The iOS 27 iPad (M4) that the probe booted was shut down again. Gameday.xcodeproj was opened in
Xcode by the approval step. Skills synced with `make skills`; no restart needed for the binary,
though the host may cache skill text.

## Remaining work

- Decide whether to build a Leap `xcode` backend, or to register the `xcode` MCP alongside Leap.
- The native retest of follow-up items A, C and B is still pending.

Addendum (2026-09-29, user request): the Xcode MCP is registered as `xcode` (`/usr/bin/xcrun mcpbridge`)
for Claude Code (user scope), Codex (`tool_timeout_sec = 600`, `startup_timeout_sec = 30`) and
OpenCode (`~/.config/opencode/opencode.json`, timeout 600000). All three report it connected.
Backups: `~/.codex/config.toml.bak-before-xcode`, `~/.config/opencode/opencode.json.bak-before-xcode`.
Each host needs a restart to load it. Leap itself is registered in Claude Code only, not in Codex
(removed at the 09-20 pause) or OpenCode.
Leap was then registered in OpenCode as well (`leap`, installed app binary, timeout 600000);
`opencode mcp list` reports it connected. Codex still has no Leap entry.
