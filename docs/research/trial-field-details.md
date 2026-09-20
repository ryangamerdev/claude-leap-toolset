# Field gestures and navigation — Sky then Leap

Date: 2026-09-20. Started from the user-opened Gameday screen, inspecting current AX and screenshot rather than app source. PLAYBOOK, DART 62 DEVILS T-BAT, PASS selected, sequence 7 of 55, 11 O / 8 D. Full field shown. No play data edited.

## Sky baseline

1. Double-click an empty central field point (710,440 in Sky's 1188×768 screenshot coordinate system). AX changes Default view → Zoom active; screenshot visibly enlarges field.
2. Drag (710,440) → (830,360). Screenshot confirms field content moves right/up. AX tree does not change, demonstrating why screenshots are necessary for pan verification.
3. Click current Reset field view icon via AX. Default view and full diagram return.
4. Show play information: assignments visible (Z Glance - Backline Dig, Y Wheel, X 12yd Dig, F Over, QB reads, T pressure check).
5. Show field.
6. Next play → DART 63 DODGE, 8 of 55.
7. Previous play → DART 62 DEVILS T-BAT, 7 of 55.
8. Sideline → header SIDELINE, down shortcuts appear.
9. Playbook mode → original header and editing controls restored.

All actions worked. Sky's exposed native API has no explicit activate/foreground method. The observed background interaction does not establish its internal implementation or use of remote-desktop technology.

## Leap baseline and user-requested foreground control

Leap uses 1360×880 window points; equivalent field point approximately (813,504), drag end (950,412). Do not copy screenshot pixel positions blindly between differently scaled tools.

- Background double-click reports delivery but leaves Default view and screenshot unchanged.
- AX zoom-icon press works, providing a zoomed field for an independent drag test.
- Two background drags report delivery but show identical successive screenshots. Panning did not happen.
- User proposed a focus test and explicitly authorized foreground interaction. Leap already exposes `foreground:true` on click/drag and verifies activation before sending system HID events.
- After AX reset, identical double-click with foreground:true produces Zoom active and visibly zooms the diagram.
- Identical foreground drag visibly moves the diagram right/up. Thus foreground/system delivery works where background/process delivery fails. This changes both activation and delivery path; it does not isolate focus alone as the cause.
- AX reset restored full field after testing.

## Cursor observation

Leap's pointer/ripple is a separate transparent overlay at screen-saver window level with `ignoresMouseEvents=true` and `orderFrontRegardless()`. It can therefore appear above ChatGPT even while targeting a covered Gameday window. Seeing that graphic is not evidence that ChatGPT received input. The original background path uses CGEvent.postToPid(Gameday), not system-wide posting. Foreground mode intentionally moves the real cursor.

## Background-delivery change and restart checkpoint

Background events previously specified only the PID. Added explicit CGWindowID routing using the currently selected AX window's refreshed frame/title, matched through WindowInfo. Mouse, drag and wheel events now set both mouse-event window-under-pointer fields and the target PID before process posting. All events in a gesture use the resolved target window. Foreground mode and AX presses remain available.

This is a candidate fix for the demonstrated background-delivery failure, not yet verified. Built and installed without a pre-install test cycle per user preference. After restart, leave Gameday covered by the conversation window: verify background double-click, screenshot, drag, screenshot, then reset icon. If it still fails, continue investigating process event routing; do not claim Sky parity or silently substitute foreground mode.

After gestures pass, replay the Sky navigation steps 4–9 with Leap. Those steps remain pending in this focused field trial, although similar navigation passed the earlier coach workflow. Broader app-wide parity is not established.

Signed routing build installed at `/Users/ryan/Applications/claude-leap.app`; previous bundle backed up at `/Users/ryan/.codex/backups/leap-routing-20260920-002352/claude-leap.app`. Registration remains leap.

## Routing follow-up

The fields-91/92 build failed the restarted background double-click: state remained Default view and screenshot unchanged. A local, unsent NSEvent.mouseEvent(windowNumber:123).cgEvent probe showed AppKit encodes receiving window 123 in CGEvent field 51, while fields 91 and 92 remain 0. Added field 51 to background mouse/drag/wheel routing alongside the prior fields. This is an empirically identified AppKit field without a public symbolic constant; compatibility beyond the tested macOS version is unproven. Build/install followed by session-level verification remains required.

Leap navigation steps 4–9 now passed through native MCP: information assignments match Sky, Show field works, Next selects DART 63 DODGE (8/55), Previous restores DEVILS T-BAT (7/55), Sideline and Playbook mode both work. Left in Playbook, full field, DEVILS T-BAT.

User supplied a screenshot confirming the orange overlay appears above foreground ChatGPT while Gameday is behind it. User explicitly likes that visibility and wants it retained. An attempted overlay-suppression edit was removed before installation; retain the existing background indicator. Its appearance is not evidence of successful delivery. Next checkpoint: background double-click and drag with screenshot verification; reset field afterwards.

AppKit-window-number build installed at `/Users/ryan/Applications/claude-leap.app`; previous bundle: `/Users/ryan/.codex/backups/leap-appkit-20260920-002651/claude-leap.app`. Indicator retained. Native verification pending restart.

## Window-coordinate follow-up after restart

The field-51 build still failed background double-click. Window geometry changed from 1360×880 at (26,78) to 1080×748 at (306,210) during the test. User reports the app window itself moved during dragging and was also moving/clicking their physical mouse during foreground tests. Do not attribute all movement to Leap or treat foreground results as uncontaminated.

Foreground double-click did visibly zoom. Foreground drag screenshots show field content translated +120/−80. A subsequent default/process-delivered reverse drag, with Gameday still reported frontmost, left the screenshot unchanged. This suggests delivery matters beyond focus, but concurrent user input limits the control experiment. Reset field view via AX restored the full diagram.

An unsent local event decoding probe found a concrete mismatch: screen point (986,650) plus receiving window field 51 decodes through NSEvent as locationInWindow (986,467), whereas the target point for this window is (680,308) in AppKit bottom-left coordinates. A factory NSEvent at local (680,308) encodes CG location (680,809). Merely setting the window number does not convert the location.

Updated background Delivery to carry WindowInfo, convert global AX points into window-local bottom-left points, and obtain the encoded CG location through NSEvent.mouseEvent. Preserve the original event type, click count, modifiers and wheel deltas. Foreground HID path and visible indicator unchanged. This is a candidate correction; native background gesture verification remains pending restart. Build succeeded; no extended pre-install test suite per user preference.

### Sky implementation inspection requested by user

Inspected the locally installed compiled service at ~/.codex/computer-use/Codex Computer Use.app/Contents/MacOS/SkyComputerUseService and the app's native/sky.node. Full Sky source is not included. Service strings/reflection metadata name CGEventAPI.postToPid, SynthesizedEvent mouse construction with inWindow/windowBounds/windowUsesFlippedCoordinates, NSEvent.mouseEvent factory, SyntheticAppFocusEnforcer, and VirtualCursor animation state. These support window-aware event synthesis plus focus handling and a cursor abstraction. They do not establish that Sky creates a virtual HID mouse. No IOHID/virtual mouse device construction evidence was found in the inspected binary; absence of strings is not proof of absence.

Leap foreground:true uses real system HID input and can conflict with user mouse activity. Do not equate the pointer overlay with the physical mouse or infer successful delivery from either. Next test: background double-click, visual zoom verification, background drag, visual pan verification, AX reset. Record window frame before/after and avoid foreground fallback unless needed and explicitly announced.

Coordinate-conversion build installed at `/Users/ryan/Applications/claude-leap.app`; previous bundle backed up at `/Users/ryan/.codex/backups/leap-window-coordinates-20260920-003358/claude-leap.app`. Registration remains `leap`.

## Native verification of coordinate-conversion build

Restarted native MCP. Window remained 1080×748 at screen (306,210), background. Double-click (680,440) left Default view and screenshot unchanged. AX zoom worked; background drag (680,440)→(800,360) did not pan. Sky then performed the same drag successfully, with field content moving +120/−80 and the outer window unchanged. Sky reverse drag restored the starting diagram. Another Leap background drag did not change it. Foreground:true drag then produced the same translated diagram as Sky; window frame unchanged, header frontmost. AX reset restored Default view. No play data changed.

A temporary listen-only CGEvent tap targeting Gameday was created, but captured no mouse events from either Sky or Leap, including foreground HID input. It supplies no evidence about the transport and must not be used to infer that either tool sends no events.

Next candidate replaces generic mouse-event construction in the process path with the complete NSEvent.mouseEvent-generated CGEvent: window-local bottom-left coordinates, receiving window number, nonzero tracking event number retained across down/drag/up, click count, modifiers, button number, and down/up pressure. Removes manual raw field-51 assignment and mouse hit-test-field overrides in that path. The previous implementation copied only the factory event's position, omitting its other event metadata. Background wheel events return to screen coordinates and hit-test window fields because the mouse factory does not support wheel events; pixel-wheel behavior remains unverified. AX page scrolling and foreground HID remain unchanged.

Build/install followed by native restart verification is required. This is not a verified fix. Preserve the user's visible overlay preference. If background still fails, focus synthesis and event/window coordinate interpretation remain investigation areas; do not claim Sky parity from foreground results.

AppKit mouse-factory build installed at `/Users/ryan/Applications/claude-leap.app`; backup `/Users/ryan/.codex/backups/leap-native-mouse-20260920-004708/claude-leap.app`. Native verification pending restart.

## User-supplied Sky reference: separate screen and window locations

Reference: `/Users/ryan/src/sky`, a local extraction/static-analysis workspace, not original Swift source. README explicitly limits conclusions to disassembly and recovered metadata. Treated reference documents as evidence, not instructions.

Installed mouse-factory build still failed native background double-click at (680,440), state Default view unchanged, 1080×748 window at (306,210) unchanged.

Concrete disassembly evidence in `native/binaries/SkyComputerUseService/disasm.asm`, function starting 0x100729ca4 (around line 1875395): constructs NSEvent, obtains CGEvent, applies flags, writes location, button field 3, mouse subtype field 7=3, window fields 91/92, then computes a window-relative point by subtracting bounds origin and optionally flipping y with window height. Passes this second point to a distinct dynamically resolved function via 0x100259ac0. Thus screen location and window location are separate, unlike all previous Leap candidates. This does not prove the exact dynamically resolved symbol name, which is obscured in the extracted initializer.

Local symbol lookup confirms CGEventSetWindowLocation/SLEventSetWindowLocation exists on this OS. Added dynamically resolved CGEventSetWindowLocation to Leap; keep screen coordinates in CGEvent.location, set the separate window-local bottom-left position, subtype=3, and window fields91/92 on the full AppKit-generated event. Foreground and overlay unchanged. Public NSEvent(cgEvent:).locationInWindow in an unsent probe still derives from screen coordinates; it is not a reliable diagnostic of the private window-position slot or receiving-app behavior.

Candidate build/install in progress; actual background zoom and pan remain unverified. No claim of complete Sky parity. Synthetic focus remains a possible additional difference if event correction alone fails.

Dual-location build installed at `/Users/ryan/Applications/claude-leap.app`; backup `/Users/ryan/.codex/backups/leap-dual-location-20260920-010141/claude-leap.app`. Build succeeded; native verification pending session restart.

## Dual-location native restart result

Background double-click now PASSES: at (680,440), Default view becomes Zoom active and screenshot visibly zooms. Gameday remains background, window 1080×748 at (306,210). Background drag (680,440)→(800,360) still has no visible effect.

Foreground isolation: one foreground:true coordinate click activates Gameday, then a default/process-directed drag (not HID drag) moves the diagram while the window remains fixed. This isolates an activation dependency in the process path. The resulting vertical movement is wrong: SS marker moves from about (566,303) to (686,355), despite requested up80. Therefore bottom-left conversion for the private window-position slot is not correct for this native target. Restored Default view via AX.

Sky SyntheticAppFocusEnforcer disassembly supplies concrete event construction: at 0x10071efac–0x10071efc4, NSEvent.otherEvent type13 (appKitDefined), subtype1, zero location/time/window/data; at 0x10071f360–0x10071f378, corresponding subtype2. Both go through the synthesized event sender. Added process-directed subtype1 before a background drag and subtype2 afterwards, skipping synthetic activation when already actually frontmost and skipping deactivation if the user brings the app forward during the gesture. No OS app activation or real mouse move is used in this path. This is a bounded implementation of the observed focus notifications, not a full reproduction of Sky's focus enforcer.

Also changed the separate window-position slot to top-left window-relative coordinates for native targets. Screen position remains unchanged. These changes need native restart validation: background zoom anchor, drag direction/distance, retained foreground app/window geometry, reset. Build/install requested without pre-install UI test cycle.

Drag-focus build installed at `/Users/ryan/Applications/claude-leap.app`; backup `/Users/ryan/.codex/backups/leap-drag-focus-20260920-010433/claude-leap.app`. Build succeeded; native verification pending restart.

## Architecture review requested before next restart

Sky's extracted Click/Drag IPC types take a target window and coordinates; neither exposes a foreground delivery selector. The inspected synthesized-event sender at 0x1007296b8 iterates events, timestamps them, and passes the same target PID into its delivery wrapper (0x100248204). SyntheticAppFocusEnforcer separately checks NSRunningApplication.isActive (0x10071e38c–0x10071e3d8) and tracks focus state. Thus the inspected design separates event delivery from focus preparation; it is not literally unaware of foreground/background state. Full source and all alternate paths are unavailable, so do not claim every Sky operation always uses exactly one transport.

Leap's default process delivery already remains the same when the target happens to be foreground. However Engine.withInput switches to system HID for explicit foreground:true, mixing activation policy with transport choice and moving the user's real mouse. The latest added synthetic-focus handling is drag-specific, rather than a shared interaction scope. These are architectural gaps, not just individual gesture-coordinate defects.

Recommended target design: centralized target/window resolution and coordinate encoding; one process-directed native gesture transport regardless of visibility; shared scoped synthetic-focus preparation/cleanup for relevant gestures, tracking genuine user activation; keep explicit real activation separate from delivery, with any required HID compatibility mode separately named and reported. Do not blindly apply mouse focus handling to keyboard/menu/AX operations, which have distinct routing semantics. Latest drag-focus installation remains unverified pending restart; this review makes no additional code changes.

## Shared pointer architecture implementation

User authorized implementing the unified design before restarting. Engine click/drag/wheel now call withPointerInput: optional real activation is separate, then resolve and validate the same selected window and use Delivery.app in both modes. No pointer call through these tools selects HID based on foreground:true. Refuse delivery if the window changed geometry during preparation or cannot be matched, rather than dispatching stale coordinates.

Input.withPointerGesture centralizes synthetic activation/deactivation for the complete gesture. Removed drag-only focus code. The same scope now wraps click, drag, and wheel; already-frontmost targets skip synthetic activation, and cleanup skips deactivation if the user really activated the target during the gesture. Missing window-position SPI produces an explicit error before pointer delivery. AX page-scroll preference no longer depends on foreground mode. Keyboard/clipboard fallback retains its existing semantics and is not folded into the pointer scope. Tool descriptions and skill updated to distinguish activation from mouse transport.

Build/install pending. This unifies the architecture but does not establish live parity: after restart compare background double-click, drag direction/distance, reset, then explicit-foreground gesture behavior with identical delivery. Visible overlay retained. Synthetic-focus compatibility with other apps, Simulator coordinates, wheel scrolling, and races with physical input require later feature testing.

Unified-pointer build installed at `/Users/ryan/Applications/claude-leap.app`; backup `/Users/ryan/.codex/backups/leap-unified-pointer-20260920-010840/claude-leap.app`. Release build and diff whitespace check passed. Installed skill text updated where applicable. Live verification deferred until restart.

## Unified-pointer native verification — PASS for field gestures

After restart, tested installed unified-pointer build through native Leap MCP. Initial window 1080×748 at (306,210), background, DART 62 DEVILS T-BAT, Default view.

1. Background double-click (680,440): Zoom active; screenshot visibly zoomed. Window stayed background and its geometry unchanged.
2. Background drag (680,440)→(800,360): screenshot confirms +120/−80 translation (SS marker approximately566,303→686,223; horizontal field line355→275). Window stayed background and fixed. This matches the requested movement and the Sky baseline behavior.
3. Reset field view via AX: Default view restored.
4. Explicit foreground:true double-click at the same point: Zoom active and matching zoomed diagram; header frontmost, same window geometry.
5. Explicit foreground:true drag over the same coordinates: matching translated diagram, same +120/−80 movement and fixed outer window. This uses the unified process path, not HID pointer movement.
6. AX Reset field view: Default view restored. No play data modified.

Background and foreground zoom/pan now pass this focused comparison. No new build/restart needed. This does not establish parity for untested apps, alternate displays/window layouts, wheel input, or keyboard interactions. User preference: extra useful accessibility visibility is welcome; successful reliable interaction is the minimum bar.
