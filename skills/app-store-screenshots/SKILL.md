---
name: app-store-screenshots
description: Capture App Store / marketing screenshots of an iOS or iPadOS app from the Simulator — clean device pixels at native resolution, no bezel, correct orientation, optional 9:41 status bar. Capture and status bar are fully simulator-native (xcrun simctl); navigation is native-first (deep links, launch args, or an XCUITest target) and falls back to the claude-leap MCP tools only when the app offers none of those. Use when the user asks to make App Store screenshots, marketing shots, or a versioned screenshot set for iPhone/iPad.
---

# App Store screenshots from the Simulator

Apple wants the app's **screen content at the device's native pixel size, with the status bar
and home indicator, and no device bezel**. `xcrun simctl io <device> screenshot` gives exactly
that (the device framebuffer). A screen capture of the Simulator *window* is wrong: it has the
bezel and is the display's scaled size. So capture with `simctl`, not with a window screenshot.

## What is native, and where navigation comes from

- **Capture** and **status bar** are fully simulator-native: `xcrun simctl io … screenshot` and
  `xcrun simctl status_bar … override`. Do not build a wrapper around a CLI that already exists.
- **`simctl` has no tap/gesture API** (only `launch`, `openurl`, `ui`). So the *only* native ways
  to move between screens are, in order of preference:
  1. **Deep links** — `xcrun simctl openurl <udid> "myapp://screen"` if the app defines URL
     schemes (`CFBundleURLTypes`) or universal links for its screens.
  2. **Launch arguments / environment** — `xcrun simctl launch <udid> <bundle> -Screen formations`
     if the app reads an argument to open a screen (the pattern fastlane snapshot uses with a
     `SNAPSHOT`/`UITEST` flag).
  3. **XCUITest** — an Xcode UI-test target that taps by accessibility identifier and captures with
     `XCUIScreen.main.screenshot()`, run with `xcodebuild test`. This is the Apple-native,
     CI-reproducible standard (what fastlane snapshot generates). It needs a UI-test target in the
     app project.
- **Fallback: claude-leap** — if the app has no deep links, no launch-arg navigation, and you do
  not want to add a UI-test target, drive the UI with the leap MCP tools (`get_app_state`,
  `click`). This is fastest for a one-off; it is not reproducible in CI the way XCUITest is.
- `sips` (built in) rotates the capture when the app is landscape-locked (see below).

Decide navigation once: check the app for `CFBundleURLTypes` and a UI-test target. If it has deep
links, prefer them (no external driver, works headless). If it has a UI-test target, prefer
`xcodebuild test`. Otherwise use leap.

## Steps

1. **Pick the devices.** App Store Connect requires a current set of display sizes (at minimum a
   6.9" iPhone and a 13" iPad; check the current requirement, it changes). Boot the matching
   simulators. `xcrun simctl list devices available` shows names and UDIDs;
   `xcrun simctl list devices booted` shows what is running.

2. **Get the app running in each device.** `xcrun simctl install <udid> <App.app>` then
   `xcrun simctl launch <udid> <bundle-id>` (foregrounds it). Confirm with
   `xcrun simctl spawn <udid> launchctl list | grep -i <app>`.

3. **(Optional) Clean status bar** — Apple's marketing convention is 9:41, full battery and
   signal. Apply before capturing, per device:
   ```
   xcrun simctl status_bar <udid> override --time "9:41" \
     --batteryState charged --batteryLevel 100 --cellularBars 4 --dataNetwork wifi --wifiBars 3
   ```
   Undo afterwards with `xcrun simctl status_bar <udid> clear`.

4. **Navigate to each screen.**
   - *Deep links:* `xcrun simctl openurl <udid> "<scheme>://<screen>"`, then capture. Fully native.
   - *Launch args:* relaunch with the screen selector, e.g.
     `xcrun simctl launch <udid> <bundle> -startScreen formations`, then capture.
   - *XCUITest:* the test itself navigates and calls `XCUIScreen.main.screenshot()`; run it with
     `xcodebuild test -scheme <UITestScheme> -destination "id=<udid>"` and collect the attachments.
   - *leap fallback:* the app must be the Simulator's **key window** for its accessibility tree to
     appear; if a device shows only chrome, make it key via the Simulator **Window** menu (open it,
     click the device's `makeKeyAndOrderFront:` item). Then `get_app_state(app:"Simulator",
     window:"<device name>")` and `click(label:…)`. Tabbed apps keep their nav; home-menu apps
     (each screen has a **Home** button) need a state re-read after each navigation, because the
     element indices are only valid for the last rendered screen.

5. **Capture the framebuffer** (works regardless of which window is key):
   ```
   xcrun simctl io <udid> screenshot <out>.png
   ```

6. **Rotate if the app is landscape-locked.** `simctl` captures the *native-portrait*
   framebuffer, so a landscape app comes out rotated. Fix with one command:
   ```
   sips -r 90 <out>.png      # 90° clockwise; use -r 270 if it comes out upside-down
   ```
   Verify the direction once by opening the first shot, then reuse it for the rest of that app.
   A portrait app needs no rotation.

7. **Organize.** Save to a versioned folder named after the app's marketing version, e.g.
   `docs/screenshots/<version>/<platform>-<screen>-<kind>.png` →
   `docs/screenshots/0.19.0/iphone-playbook-main.png`, `ipad-formations-main.png`. Read the app's
   `MARKETING_VERSION` from the Xcode project for the folder name.

## Gotchas

- **`simctl io screenshot` ignores the Simulator window**, so you can capture a device that is not
  frontmost — but you still need it to be the key window to *navigate* it with leap.
- **Rotation direction** depends on landscapeLeft vs landscapeRight; check once per app.
- **Home-menu apps**: after tapping the in-app Home button with a non-state-returning click, the
  element table is stale; refresh with `get_app_state` (or use state-returning clicks) before the
  next label lookup.
- **`simctl` cannot tap.** If you find yourself wanting a "simctl tap" command, it does not exist;
  use deep links, launch args, XCUITest, or leap for navigation.
- **Don't add a new MCP tool for this.** `simctl` + `sips` from the shell is the whole capture
  path; navigation is native-first with leap only as the fallback driver.
- The `simctl status_bar` override persists until `clear`; always clear it when done.
