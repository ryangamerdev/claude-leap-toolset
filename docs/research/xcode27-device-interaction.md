# Xcode 27 agent support for devices (Device Hub, Xcode MCP DeviceInteraction)

Researched 2026-09-29 on macOS 27 / Xcode 27.0 (DeviceHub 255.2.6.6, xcode-tools 25317).
Sources: Apple docs, the installed Xcode, and live probes. Evidence is kept in
artifacts/reference/xcode27-agent/ (tool schemas, probe transcripts, hierarchies). The exported
Apple skills are local-only (ignored); regenerate them with `xcrun agent skills export <dir>`.

## What Apple provides

- **Device Hub** (`Xcode.app/Contents/Applications/DeviceHub.app`, `com.apple.dt.Devices`) replaces
  Simulator.app for simulated and physical devices ([Device Hub](https://developer.apple.com/documentation/xcode/device-hub)).
  - The app is a human UI: pointer and keyboard gestures, bezel buttons, and Controls and Device
    menus ([Interacting with your app in Device Hub](https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub)).
  - Its only automation surface is the `devices://device/open?id=<UDID>` URL scheme.
  - Command line: `devicectl` (install, launch, files, info, `--json-output`) and `simctl`
    ([Interacting with devices using the command line](https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line)).
- **Xcode MCP server** ([Giving external agents access to Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)):
  - Registration: `claude mcp add --transport stdio xcode -- xcrun mcpbridge`.
  - Enable it under Xcode › Settings › Intelligence › "Allow external agents to use Xcode tools".
  - `xcrun mcp-server` manages it, including headless mode and approvals.
  - An agent is approved when it first calls `XcodeOpenWorkspace` or `XcodeNewProject`.
  - It exposes 52 tools: build, test, previews, the debugger, project editing, and **device interaction**.
- **Device interaction tools** (bundled skill `device-interaction`):
  - `DeviceInteractionStartSession(deviceIdentifier, sessionIdentifier)` starts a session without a
    workspace. `DeviceInteractionStartWorkspaceSession` starts one bound to a workspace, which
    `DeviceInteractionInstallAndRun` needs.
  - `DeviceInteractionSynthesize(interactSessionKey, interactionCommand, activationBundleId?)`
    runs a command, then returns file paths to a screenshot, a thumbnail, logs, and a UI hierarchy.
    - The hierarchy is an XCUITest-style tree per app. It carries element frames, `hitPoint`
      coordinates, identifiers, labels and values, the device and UI orientation, and the bundle id and pid.
    - Commands:
      - Tap (`t x y [dur]`), double tap (`d`), swipe (`t .. f ..`), `drag`, multi-touch (`mt`).
      - Hardware buttons (`b h/p/u/d`) and orientation.
      - Keyboard text (`sender keyboard kbd <text>`, with `\u{000A}` for Return).
      - Wait (`w`), tvOS remote (`r ...`) and watchOS crown.
    - Coordinates are device points; the skill says to always use `hitPoint`.
  - `DeviceInteractionEndSession`.
  - Apple's skill asks the main agent to delegate interaction to a subagent. That is a workflow
    convention; the tools themselves work without one.

## Probe results (live)

- Before approval, every tool refused ("Call XcodeOpenWorkspace … first"). Opening
  `/Users/ryan/src/gameday/Gameday.xcodeproj` approved the agent.
- The Gameday simulators (iPad Air M2 and iPhone 16, **iOS 18.0**) are not eligible. Only iOS 27
  runtimes are listed ("Cannot select specified device", followed by the eligible list).
- iOS 27 iPad Air 11-inch (M4), with no app build:
  - Starting the session booted the device, and the first capture took 31.5 s.
  - The next capture took 1.1 s.
  - Tap `t 492 624.8` (the Settings icon's hitPoint) took 1.9 s including the capture and opened
    Settings, as shown by the Settings card in the hierarchy.
  - `applicationState: NotRun` refers to the session's app, since no app was installed.
- The session key is the `sessionIdentifier` string. A used identifier cannot be reused right away.

## Comparison with Leap's routes to a Simulator guest app

| | Leap mac_ax via Device Hub host AX | Leap wda backend | Xcode DeviceInteraction |
|---|---|---|---|
| Setup | none | repo WDA runner per device | Xcode running, MCP enabled, agent approved |
| Runtimes | any | any | iOS 27 only in this Xcode (18.0 refused) |
| Coordinates | host window; `[rotated]` frames unusable | device points | device points plus hitPoint |
| Orientation | inferred (rotated tag) | tracked | reported per app |
| Actions | AXPress, value/text via AX, host pointer | WDA taps, limited keys | touches, gestures, hardware buttons, device keyboard |
| Typing | AX value or host keystrokes (minor glitches) | limited | device keyboard (`kbd`) |
| Element press by identity | yes (AXPress) | yes | no (coordinates only) |
| Evidence | Leap snapshots, deltas, history | Leap | files per call |

Sky reference: Sky has no Device Hub or Xcode integration. It drove the Simulator through host
accessibility, with the same rotation and typing limits Leap has on that route (SKY-BEHAVIOR §6).
For guest apps on iOS 27 runtimes, Apple's tool is better than both Sky's approach and Leap's
host-AX approach: real touch events in device coordinates, correct orientation, and the device keyboard.

## Implications for Leap

1. **Guidance (done 2026-09-29):**
   - The skill tells agents to use Xcode's device-interaction tools for guest apps on iOS 27+
     simulators when the `xcode` MCP is available.
   - Leap remains the tool for Mac apps, Device Hub chrome, older runtimes, and verified workflows
     with retained evidence.
2. **Candidate backend (not built):**
   - A Leap `xcode` backend would call `xcrun mcpbridge` like the WDA adapter does. It would map
     selectors to the hierarchy's `hitPoint`, parse the hierarchy into Leap's normalized nodes, and
     keep Leap's before/expect checks and evidence.
   - This would replace the custom WDA runner for iOS 27 devices.
   - It needs a decision on requiring Xcode to be running and on its approval flow.
3. The Gameday acceptance devices run iOS 18.0. Using Apple's route would need iOS 27 devices with
   Gameday installed (`DeviceInteractionInstallAndRun` builds and installs it).

Addendum 2026-09-30: `DeviceInteractionStartSession(deviceIdentifier: "My Mac")` was refused with the
eligible list (iOS 27 and tvOS 27 simulators only). The Xcode MCP cannot operate Mac app UI; for
GamedayMac it can build/run/test/debug, and Leap drives the UI.
