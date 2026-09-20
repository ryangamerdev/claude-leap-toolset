# 2026-09-20 — Backend comparison and exact orientation

## Outcome and evidence

Goal: reliable Sky-equivalent Gameday operation. The installed6df9b406 candidate after restart permitted coordinate dispatch; effect on the information control still failed. Sky semantic click opened information, and a later screenshot-coordinate click also opened it. Leap explicit mac_ax information toggle passed natively (interaction55CD79A1-DAC5-4B0E-9554-C7D6214BEAF1); Previous play restored5 of11 (C35F72A5-4A26-4C4A-97C3-97C825EE8681). Host AXPress worked despite invalid offscreen geometry; diagnostic correctly suppressed pointer marker. Mac session D9D3B120-F107-4C7E-B28B-5E2B59071903 is closed.

WDA session3ADD85CE-E190-4536-BA94-D9E99F4865AA: Show field tap E1C81830-71F5-44F5-9234-45C63DED135D failed expectation; Next play F7D36401-99D7-46D7-B66F-31E5C256CE7D passed6 of11. Direct W3C100ms touch diagnostic also had no effect (not MCP acceptance). Landscape then tap F1AA59B4-3738-4144-A8A1-7F6126659281 failed toggle. No evidence of a generic lower-screen input failure or a confirmed app defect.

User observed upside-down display after LANDSCAPE request. LANDSCAPE_RIGHT A05F4C75-A351-4815-A46A-B66DCCBA41D7 failed because Leap sent the public alias verbatim. Pinned WDA FBOrientationCommands.m requires UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT. Direct backend restoration with that exact value succeeded; fresh Sky screenshot showed upright. WDA session closed; app field and original play restored. The attempted Sky scroll used a stale visual orientation and establishes no scroll pass.

## Rationale and alternatives

Sky-equivalent mac_ax operation already works for this semantic action. Do not force adoption of XCTest or keep guessing coordinate transforms to justify it. Prioritize paired Sky/Mac-backend tests; keep WDA explicit with its demonstrated gaps. The reference includes wrapper code and compiled native components, not a complete original native implementation. No additional material requested from user.

The concrete correction is protocol translation, not a tap workaround. WDA GET/orientation collapses opposite directions. Equal bounds/tree can therefore conceal a180-degree change. Acquire exact interface rotation and physical device direction before and after each WDA tree; refuse coordinate reuse when either changes or is unavailable. Interface and physical directions differ on landscape, so preserve both rather than infer one from the other. No automatic replay, implicit backend fallback or app edits.

## Changes

WDAClient maps public LANDSCAPE_RIGHT and PORTRAIT_UPSIDEDOWN to pinned backend values. Observations add orientationIdentity/orientationStable; unstable acquisition is incomplete. AutomationModel/Engine require stable exact WDA identity for coordinate provenance, rejecting older snapshots without it. Existing coarse orientation remains compatible; Mac comparison unchanged. Fault fixture exposes new read endpoints. Source skill updated with verified Mac path, WDA limitations and rotation semantics; stale checkpoint removed. PLAN/FEATURES/handoff prioritize Sky-equivalent acceptance.

## Validation and delivery

Ten focused AutomationModel tests passed, including alias translation and opposite/unstable/missing orientation identity. Installed-binary protocol fault fixture passed (harness, not native acceptance); [results](../../artifacts/test-runs/20260920-wda-hit-diagnostics/contract-results.json). Signed release build/install completed; [install identity](../../artifacts/test-runs/20260920-wda-hit-diagnostics/install.json), SHA25688c424d98e1bdbb6388e6b7c4b6c5bc0a12e412e2116809f64279b9191d48149. Skills-only install completed and both source/installed copies compared equal. Registration leap unchanged. Build/test/backend-debug logs and rollback are ignored/local-only under artifacts; raw native snapshots/results remain in ignored .leap. Small direct diagnostic/restore responses retained in artifacts/test-runs/20260920-wda-hit-diagnostics. Loaded native MCP still uses the previous binary; the fix is not yet a native pass.

## Remaining work

After restart read exact WDA orientation metadata without rotating Gameday. Then pair Sky/Mac Leap filter scroll, field double-click/drag and reset using fresh screenshots; expose any missing preferred-tool capability instead of silently falling back. Information-button XCTest failure, expensive WDA scans, identity churn, iPhone and full desktop/Blender gate remain open. Landscape-only requirement preserved. No blanket parity claim.
