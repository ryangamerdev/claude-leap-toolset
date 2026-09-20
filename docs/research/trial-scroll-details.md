# Feature trial: scrolling — Sky then Leap

Target: native Gameday, Sideline, saved TRIAL LEAP play information. Filter panel at top, normalized scrollbar value 0. Search and selections unchanged. Both APIs target the filter scroll area by its current element index. Test order: down one page, down one page, up one page, up one page. No foreground override requested.

| Action | Sky scrollbar | Leap before fix |
|---|---:|---:|
| Initial | 0 | 0 |
| Down 1 | 0.7296969696969697 | 0 |
| Down 1 | 1 | 0 |
| Up 1 | 0.2703030303030303 | 0 |
| Up 1 | 0 | 0 |

Sky used `scrollApp.scroll(17, direction, 1)` with an AX observation after each. Leap used `scroll(app, element_index:19, direction, pages:1)` with automatic observations (states #14–17). Sky finished at the original top position before Leap began. Thus the difference is demonstrated under the same app state, not inferred from tool success messages.

## Fix

Leap previously sent only CGEvent wheel events to the background process. Gameday did not move. Whole-page, indexed, background scroll requests now prefer accessibility page actions on the target or its nearest ancestor exposing the action. macOS actions describe content movement: AXScrollUpByPage moves content upward to expose the page below; AXScrollDownByPage exposes the page above. Prior live tests confirmed that mapping in this app. Horizontal equivalents use the corresponding content direction but have not been exercised here.

Multiple whole pages invoke bounded individual page actions; if an action fails, the error reports how many page requests were already accepted and avoids replaying the request through a second input path. The normal post-action state remains the evidence of actual movement. Output distinguishes accessibility requests from wheel-event dispatch, avoiding the old unconditional “scrolled” wording.

Exact pixel distances, fractional pages, coordinate-only targets, foreground mode, and elements without AX page actions retain wheel dispatch. These paths are not fixed or validated by this narrow feature change. Native accessibility page size may differ slightly from Sky's pixel/page convention; compare direction, real movement, boundaries and reversibility first, then quantify distance.

## Install/restart checkpoint

Build and install without a separate pre-install test cycle, as requested. Leave Gameday at the top of the filter panel. After restarting the Codex session, repeat the exact four actions with Leap and record scrollbar values. No plays or notes were changed by this test. The full coach workflow remains complete; this is a focused scroll regression.

Signed build installed at `/Users/ryan/Applications/claude-leap.app`. Previous bundle: `/Users/ryan/.codex/backups/leap-scroll-20260919-235513/claude-leap.app`. Native verification pending session restart.

## Post-restart verification — passed for indexed whole-page vertical scrolling

Native Leap MCP started from scrollbar 0 and repeated the exact four calls with the installed build:

| Action | Sky | Fixed Leap |
|---|---:|---:|
| Initial | 0 | 0 |
| Down 1 | 0.7296969696969697 | 0.7175757575757575 |
| Down 1 | 1 | 1 |
| Up 1 | 0.2703030303030303 | 0.2824242424242424 |
| Up 1 | 0 | 0 |

Leap states #2–5 confirm real movement, correct direction, bottom/top boundaries, and return to the starting position. Each call reports the accessibility path. Native page size differs slightly from Sky's: 0.01212 of the scroll range per interior step. Exact distance parity is not claimed. Gameday changed from background to frontmost during the first call; source of that focus change remains unisolated and is not covered by this scroll pass. Search remained TRIAL LEAP; no play edits occurred.

This feature checkpoint is complete for indexed whole-page up/down scrolling in Gameday. Fractional-page, exact-pixel, coordinate-target, horizontal, and other-app scrolling remain outside this verification. No additional installation or restart is needed for this verified case.


## CAM-01 — coordinate half-page wheel, 2026-09-20

Evidence: `artifacts/test-runs/20260920-cam01-scroll/` contains Sky screenshots/state, Leap MCP scripts/responses/screenshots and the build log. Gameday window 1080×748 at screen (306,210), filter scrollbar starts at 0, DART 62 DEVILS T-BAT (7 of 55). No filters or plays changed.

1. Sky `scroll([150,450], down, {pixels:240})` rejected the request: “macOS scroll accepts pages, not pixels.” Exact pixels are therefore an additional Leap capability, not a supported Sky macOS comparison here.
2. Sky coordinate `down, 0.5` moved scrollbar 0 → 0.3908045977011494; `up, 0.5` restored 0. Screenshots saved at each checkpoint. Focused AX element remained the football field; Sky output alone does not establish the OS frontmost application.
3. Native Leap connector returned `Transport closed` before any UI call. The installed binary initialized successfully through `scripts/mcp-call.py`; subsequent Leap observations/actions used that stdio MCP harness. This is not a native-connector pass.
4. Installed Leap, background, same point and down 0.5: dispatched wheel events but scrollbar stayed 0, AX tree unchanged.
5. Explicit `foreground:true`, same request: header confirmed frontmost, scrollbar still 0, AX tree unchanged. Thus foreground activation did not fix this failure.

Candidate fix: wheel routing now sets the separate top-left window-relative location through `CGEventSetWindowLocation`, in addition to global screen location and target window IDs, matching the coordinate convention already verified for mouse gestures. Wheel deltas and event type are preserved. Missing local routing is a source-level finding; causality and the fix remain pending live verification. No success claim follows from build completion.

Restart checkpoint: after installation, reconnect the native MCP and repeat coordinate half-page down/up at (150,450), initially in background, then foreground if needed. Verify actual scrollbar movement and restore the top. Test exact pixels after half-page passes. Keep CAM-01/SCR-04 at RECHECK until that succeeds.

Build succeeded; installed at `/Users/ryan/Applications/claude-leap.app`. Backup: `/Users/ryan/src/claude-leap/artifacts/backups/leap-wheel-20260920-015445/claude-leap.app`. Installed SHA-256: `599fc62ab3322c76e13c78543cc06667e3eeee33d11b87f184ae47f6a9967faf`. Verification pending restart.


### Native restart verification: local position alone failed

Native connector reconnected successfully. States #1–3 show scrollbar 0 before and after down 0.5 at (150,450), first background, then explicitly frontmost. Window frame stayed (306,210), 1080×748. Evidence: `leap/04-native-restart.json`. The first routing candidate did not resolve the issue.

Sky disassembly inspection then identified an additional wheel-specific field: factory 0x100729f30 writes a dynamically stored field at 0x10072a07c–0x10072a090; initializer 0x10071b654 sets that field to 0x33 (51). It writes the target window ID, then fields 91/92 and the separate local position. The relevant reference excerpts are retained as `sky/wheel-routing-reference.asm`. Leap now also sets field 51 for wheel events only. The semantic name is not supplied by the stripped reference; the field number and assigned value are directly observed. No virtual mouse device or global cursor fallback is introduced.

Second candidate build/install: verification deferred to the next session restart, per the requested workflow. Repeat background down/up half-page, then foreground if needed. Gameday remains at filter scrollbar 0; foreground activation was used for diagnosis.


### Window-field-51 build: native verification passed

Installed SHA-256 `4aaa3693b131d30b15bc4db914918adab856346100d40e0c044987711faed033` verified after restart through the native Leap MCP. Evidence: `leap/05-wheel51-native-pass.json`, `leap/06-page-bounds.json`.

| Case | Actual scrollbar sequence | Focus/window |
|---|---|---|
| Coordinate half-page down/up | 0 → 0.3312434691745036 → 0 | Remained background, frame unchanged |
| Coordinate 240-pixel down/up | 0 → 0.2507836990595611 → 0 | Remained background, frame unchanged |
| Explicit foreground half-page down/up | 0 → 0.3312434691745036 → 0 | Frontmost, same frame and exact movement as background |
| Indexed pages down/down/up/up | 0 → 0.4806687565308255 → 0.9613375130616509 → 0.4806687565308255 → 0 | Frontmost; AX path |
| Indexed three pages down/up | 0 → 1 → 0 | Both boundaries verified |

Sky's coordinate half-page was 0.3908045977011494, versus Leap's 0.3312434691745036. Page-distance conventions differ; actual movement, direction, reversibility and Leap foreground/background equivalence passed. Pixel requests produce movement and reverse correctly; exact rendered pixel displacement was not independently measured. Sky macOS rejected pixel arguments. No horizontal/nested-list/general-app certification is inferred. Filters, active play and window geometry remained unchanged. CAM-01 is tested for its vertical Gameday scope. No further install/restart is needed for this fix.
