# Porting Leap to Windows

Leap currently runs only on macOS. A Windows implementation is the most wanted contribution.
This guide describes the contract a port must keep, how the macOS code maps to Windows APIs,
and a suggested order of work. Coordinate in the pinned "Windows support" issue before starting
a large piece so work is not duplicated.

## What must stay the same

Agents and skills depend on the MCP contract, not the platform. A Windows server should expose
the same tool names, parameters and response shapes (see `Sources/leap/Tools.swift` and
`python3 scripts/mcp-call.py tools`), including:

- `get_app_state` returns the target window as an indexed text tree with stable element
  indices for the life of the window, and later reads as diffs.
- Actions accept `element_index` or `label`; each returns the updated diff.
- Background-first: no tool activates the app, steals keyboard focus or moves the real cursor
  unless the caller passes `foreground: true`.
- Uncertain input is reported as uncertain and never replayed automatically.
- `ui_perform` reports execution, dispatch and verification separately.
- Evidence (recordings, snapshots, diagnostics) is journaled in the project-local SQLite store
  with the same schema, so evidence tools work unchanged.

Where Windows cannot provide a guarantee (for example background keyboard input to some apps),
refuse with an explicit error rather than silently falling back to global input.

## macOS to Windows mapping

| Concern | macOS (current) | Windows candidate |
|---|---|---|
| Accessibility tree | `AXUIElement` walk (`AXTree.swift`, `AppSession.swift`) | UI Automation (`IUIAutomation`, cached `TreeWalker`/`CacheRequest`) |
| Semantic actions | `AXPress`, `AXValue`, selected-text range (`Engine.swift`) | `InvokePattern`, `ValuePattern`, `TogglePattern`, `SelectionItemPattern`, `TextPattern`, `ScrollPattern`, `ExpandCollapsePattern` |
| Background pointer/keys | `CGEvent.postToPid` (`Input.swift`) | `PostMessage`/`SendMessage` of `WM_*` messages to the target HWND; `SendInput` only with `foreground: true` |
| Window discovery | `CGWindowListCopyWindowInfo` (`WindowInfo.swift`) | `EnumWindows`, `GetWindowThreadProcessId`, DWM frame bounds |
| App resolution/launch | `NSWorkspace` (`AppResolver.swift`) | Process enumeration, AppUserModelID for packaged apps, `ShellExecuteEx` without activation |
| Screenshots | ScreenCaptureKit (`Capture.swift`) | `Windows.Graphics.Capture` (or `PrintWindow` as fallback) |
| Activity overlay | click-through `NSWindow` (`Overlay.swift`) | layered, transparent, `WS_EX_TRANSPARENT` topmost window |
| Change events for recording | AX notifications (`Recording.swift`) | UIA event handlers (structure, property, focus) |
| Permissions | TCC Accessibility / Screen Recording (`Permissions.swift`, `Disclaim.swift`) | UIAccess/integrity-level limits; elevated targets need an elevated server |
| Key chords | `Keys.swift` (xdotool-style names) | map the same names to virtual-key codes |

Platform-independent pieces that can be shared or ported directly: the tool schemas, the
selector/expectation model (`AutomationModel.swift`), the evidence store and query tools
(`Evidence.swift`, `Recording.swift` storage), diagnostics, diff rendering and the WebDriverAgent
client (Simulator control stays macOS-only).

## Language and structure

Swift runs on Windows, and the MCP Swift SDK is cross-platform, so one option is a
`LeapWindows` target behind the same `Sources/leap` server with a platform protocol extracted
from `Engine`. A separate implementation (for example C#/.NET or Rust with the `windows` crate,
both strong for UI Automation) is also acceptable if it keeps the MCP contract and evidence
schema. Please propose the choice in the tracking issue first.

Suggested steps:

1. Read-only `list_apps` and `get_app_state` over UI Automation with stable indices and diffs.
2. Semantic actions through UIA patterns (`click`, `set_value`, `perform_action`, `scroll`).
3. Background text and key input to a target window; explicit refusal where unsupported.
4. `screenshot` and the activity overlay.
5. Recording/evidence parity and `ui_perform`.
6. Installer registering the server with MCP clients, and a Windows section in `skills/leap`.

## Testing

Add unit tests for pure logic and JSON MCP scenarios (`Tests/*.json`, run with
`scripts/mcp-call.py script`) against apps that ship with Windows, such as Notepad and
Calculator, so anyone can reproduce them. Report what was verified by driving real apps through
an MCP client separately from harness results.
