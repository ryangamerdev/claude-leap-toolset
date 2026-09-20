# 2026-09-20 — Desktop creation regression and metadata uncertainty

## Outcome and evidence

Restarted0c63b3e passed native desktop scroll-effect detection down/up: interactionFBE50B51-960C-42F1-9FE3-0924298B6113 reported movement_observed with scrollbar0→0.4806687565→0 and scoped visual change. Sky sideline PASS filtering, play selection and information display worked. Sky created SKY ACCEPTANCE 0920 - Slant Flat using default2X2 SLOTS, assigned2 Step Slant to1 and Flat to2, entered player/coaching notes, saved, searched and reopened. Reopened information showed exact coaching and both player notes. Route assignments acknowledged; named selected routes were not rechecked in reopened editor.

Leap New play interaction744B3022-A07A-4A35-B680-02875C0A20A4 opened the editor but expectation became unknown. Initial observation hit deadline; subsequent settled71-node reads consistently had three failures on the same AXTextArea: AXIdentifier twice and AXDescription, all -25200. Value, children and controls were present. Explicit foregroundC428A4BB-E256-452E-8624-FC349F58B747 left the same failures. Closed Leap session0A917C45-9764-4C36-B8B1-67C5AA37613A; unsaved New Play1 remains open. User says all data is test data and need not be restored; desktop and iPad creation repeats take priority before Blender.

## Rationale and alternatives

This is a refactor regression in intent orchestration's global completeness requirement, not demonstrated lost text input. Historical docs/research/trial-leap.details.md steps11–21 record successful Leap route/notes/save/search/reopen before intent rebuild. Legacy Engine.actionSession checks indexed elements/process, and setValue performs targeted text replacement; it does not impose AutomationEngine's global completeness guard.

Sky reference checked: native/ghidra/decompiled/all/names-demangled.txt lines37740ff and part-0025.c0x1006e30a4 expose value(for:) returning (AXError, optional AXPartialValue);0x1006e48d8 values(for:) is throwing and has explicit error branches. This supports a field-level acquisition model but does not prove Sky's entire high-level policy. Stronger empirical comparison: live Sky completed this exact editor. No claim that Sky universally ignores failures. Preserve uncertainty instead of removing all guards or treating errors as known absence.

## Changes

Only AXError.failure for AXTextArea AXIdentifier/AXDescription is classified as advisory optional metadata. Per-element missing metadata is retained in unavailableFields; no silent fallback. Missing description marks label unavailable unless a title supplies it. Role-qualified unrelated selectors and explicit observed IDs remain usable; metadata-dependent potentially matching selectors remain uncertain. Shared selectionReliable prevents unknown metadata from establishing uniqueness, count or absence. ui_observe exposes selectorComplete and includes unavailableFields in default fields. Value, children, role, security-subrole and transport errors retain blocking semantics. Source skill explains query/action behavior; standing instructions reflect user priority/test-data scope.

## Validation and delivery

Four ObservationQualityTests passed, including missing metadata selector ambiguity/absence, reliable ID value assertion, advisory metadata and blocking transport/state errors. Signed build and codesign verification passed. Installed SHA2566a80e2b3b12dd20098e8678931ba874445fc42f2a15a41982c120fbe26cd4aa9; [install metadata](../../artifacts/test-runs/20260920-editor-metadata/install.json). Native old-build results retained in [results](../../artifacts/test-runs/20260920-editor-metadata/native-results.json), [editor screenshot](../../artifacts/test-runs/20260920-editor-metadata/editor.png). Original .leap paths and build/test logs/rollback are local-only ignored artifacts. Skills-only install completed; Claude/Codex/source directories matched. Registration leap/history preserved. New installed binary awaits MCP restart/native acceptance; build is not a native pass. Commit/push before handoff.

## Remaining work

Restart and resume existing New Play1 editor (do not create another). Role-qualify Play title as textfield; set LEAP ACCEPTANCE0920 - Slant Flat with space between ACCEPTANCE and0920 as specified in handoff. Assign same two routes/notes as Sky, save/search/reopen and verify. Then paired iPad creation/save/reopen and paired Blender. No new Sky input or geometry defect inferred from this metadata issue. Full end-to-end gate incomplete.
