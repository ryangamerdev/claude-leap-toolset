# 2026-09-20 — Reject misleading semantic-action markers

## Outcome and evidence

Ryan saw a click at the bottom of his screen instead of on Simulator. The last two native actions returned "pressed via accessibility" and met their view-transition checks. Their AX button frames were around screen y=1031–1046, outside Simulator's y=61–841 window. Engine.click performed AXPress successfully, then unconditionally signaled the cached screen point. This demonstrates a cosmetic-coordinate defect for these observed actions, not a mouse click delivered to another application. It does not certify every input path.

## Rationale and alternatives

Semantic AX actions address elements directly and do not require trustworthy screen coordinates. Replacing them with pointer input would discard a working route; clamping a marker to the window edge or center would invent a precise target location. Suppress the marker when its geometry is unreliable, retain the action and report suppression. Mapping rotated Simulator geometry could eventually improve marker coverage, but requires validated transforms rather than guessing from this example.

## Changes

Added shared IndicatorGeometry validation: finite positive frames, full containment in the current target window, and no offscreen flag. Negative desktop coordinates remain valid for secondary displays. Validate semantic click markers before dispatch so a disappearing target is not queried afterward. Failed validation hides the old pointer and emits no new click ripple; successful AXPress reports that its location indicator was hidden. Element-based edit indicators use the same guard and no longer silently substitute window center for an invalid element. Observation/window-level markers keep their existing window-centered meaning. Coordinate input and its transport remain unchanged.

A marker whose geometry is plausible but wrong within the window remains possible; containment alone cannot establish an accurate Simulator transform. This is an honest suppression guard, not a complete geometry mapping fix. System menu elements outside the selected window may also have their semantic markers suppressed conservatively.

## Validation and delivery

Two focused IndicatorGeometryTests passed. Cases cover the recorded iPad out-of-window frame, partial clipping, offscreen flags, nil/zero/NaN geometry and valid negative-screen coordinates. No synthetic input was sent in these tests. Release build/signature and final installation identity will be retained in artifacts/test-runs/20260920-indicator/install.json; raw logs are local-only. Source skill documents semantic versus pointer behavior and suppression; refresh with scripts/install.py --skills-only and compare installed copies.

## Remaining work

After restart resume group E02D3027-C127-4760-A280-7E2FC74244C4 and establish a fresh Simulator capture. Verify group history across the MCP restart. Repeat background information/field toggle: one AX input, met postcondition, suppression reported for the invalid button frame, field restored. User-visible marker placement still requires native observation; unit tests/build do not prove it. Verify a valid visible control retains its marker in a later native case. Then continue Simulator and paired Blender work. Delta verbosity/key churn and controlled temporal evidence remain open.

## Delivery result

Signed release installed: `d5422d2833ff5ca806f5dd5bb9784388e2d5bcb6d5f7896a883ea13322c692fd`. [Install identity](../../artifacts/test-runs/20260920-indicator/install.json). Skills-only synchronization passed byte comparison. Registration unchanged; no recording-store changes. Local rollback app path is in install metadata. Native validation awaits restart.
