# Leap feature checklist

Updated: 2026-09-20. This is the working acceptance checklist for **native macOS and Simulator computer use at least as effective as Sky**. Extra useful accessibility detail, stronger identity checks, clearer results, and fewer screenshots are welcome improvements. Matching Sky's internal implementation or reproducing its defects is not the objective.

Success means an agent can discover an unfamiliar app, understand its current state, act on the intended target, and verify the outcome while the user keeps using their computer. A successful tool response alone does not prove a successful action.

Agent-facing contract: expose actions, expectations and useful evidence retrieval; keep database and capture mechanics internal. Project binding should be a one-time setup, with simple continuation handles.

Current execution order and restart checkpoint: [PLAN.md](PLAN.md). Resume context: [SESSION-CONTINUATION.md](SESSION-CONTINUATION.md). Design: [durable observations](research/observation-session-design.md). These documents distinguish historical passes from the latest installed but unverified candidate.

## Status and promotion rules

Use the status words below instead of checkbox marks. Status applies only to the scope stated in the row; an implementation or an old test script is not a live pass.

| Status | Meaning | Next step |
|---|---|---|
| **RESEARCH** | Required behavior, approach, or comparison is not understood well enough. | Establish an observable acceptance case and investigate. |
| **DEFERRED** | Deliberately outside the current campaign; no implementation or pass implied. | Revisit only after the stated prerequisite. |
| **PENDING** | Defined work has not started: a capability needs implementation or a workflow still needs its first execution. | Implement or begin the paired trial, as applicable. |
| **PARTIAL** | A defined portion exists, but required behavior remains unimplemented. | Complete the named gaps; validate implemented portions separately. |
| **IMPLEMENTED** | Code exists; adequate live evidence has not been recorded here. | Exercise the installed MCP and record results. |
| **TESTED** | A named live scenario passed with observable evidence. | Expand coverage and repeat for certification. |
| **CERTIFIED** | The declared scope passed repeatably on the installed build, including relevant foreground/background, recovery, and regression cases. | Maintain the evidence; reopen after relevant changes. |
| **FAILED** | The required outcome was attempted and did not happen; no later pass closes that case. | Diagnose and fix or provide a verified equivalent recovery. |
| **RECHECK** | Earlier evidence exists, but changed code or incomplete coverage prevents treating it as a current pass. | Run the specific regression, not the entire project by default. |

**No feature is certified yet.** Certification is an internal evidence standard, not a claim of external approval. A row can be certified for a narrow declared scope without certifying all of Leap. Whole-row status cannot be promoted from one subcase; split the scope or retain the broader row as unverified. TESTED refers to the named evidence build, not automatically the newest installed binary. New failure → FAILED; a fix without live verification → IMPLEMENTED; relevant changes to a passed path → RECHECK. Retain prior evidence rather than erasing failed attempts.

Priority: **P0** = target correctness, user control, or core workflow; **P1** = broader native/Simulator parity; **P2** = robustness or efficiency beyond the core. Priority is importance within its phase, not execution order. Deferred rows are not blockers for the current campaign; follow PLAN.md.

## Evidence index

| ID | Evidence | Interpretation |
|---|---|---|
| FIELD | [Field gestures and navigation](research/trial-field-details.md) | Recorded unified-pointer build passed Gameday background and explicit-foreground double-click, pan right120/up80, and reset. Window stayed fixed. Earlier failed candidates are history, not current failures. |
| COACH | [Leap coach workflow](research/trial-leap.details.md), [ordered Sky baseline](research/trial-sky-details.md) | Filtering, inspection, route assignment, notes, mirror, save/search/reopen. One clear-filters recovery was performed by the user. |
| SCROLL | [Scroll comparison](research/trial-scroll-details.md) | CAM-01 wheel-field-51 build passed native half-page down/up in both focus modes, pixel movement/reversal and indexed boundaries. Exact pixel distance is not certified; older focus ambiguity is superseded for these scoped cases. |
| NAV | [Navigation and recovery](research/trial-navigation-details.md) | CAM-02 autonomous empty-search and third-down recovery passed; historical manual recovery no longer blocks these cases. |
| EDIT | [Editor persistence and AXPress](research/trial-editor-details.md) | Notes persisted despite misleading Save error. Installed AXPress guard awaits native verification; changed-route persistence remains open. |
| DESIGN | [Session/event design](research/observation-session-design.md) | Reviewed direction from Runner, Tracer and local source. First recording slice implemented; see [checkpoint](research/recording-v1-checkpoint.md). Temporal expectations remain pending. |
| REVIEW | [2026-09-18 code review](REVIEW-2026-09-18-astra.md) | Earlier findings, implementation dispositions, and some test claims. Not certification of the current build. |
| SKY | [Recorded Sky behavior](SKY-BEHAVIOR.md) | Historical observed contract and limitations, not authoritative documentation of every current Sky path. |
| REF | `/Users/ryan/src/sky/README.md` and native disassembly | Local extracted reference, not original Swift source. Explains architecture; does not establish live success. |
| CODE | [Tool definitions](../Sources/claude-leap/Tools.swift), [Engine](../Sources/LeapCore/Engine.swift), [Input](../Sources/LeapCore/Input.swift), [skill](../skills/claude-leap/SKILL.md) | Implementation evidence only unless paired with a live report. |

## Discovery, identity, and observation

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| OBS-01 | P0 | Discover running apps; resolve name, bundle ID, or full app path; refuse ambiguous targets. | IMPLEMENTED | CODE/REVIEW; exercise duplicates and unknown names deliberately. |
| OBS-02 | P1 | Launch an installed target in the background and obtain usable state. | IMPLEMENTED | CODE; verify cold launch without stealing focus. |
| OBS-03 | P0 | Read actionable AX roles, names, values, selection, enabled state, and actions. | TESTED | COACH/FIELD, native Gameday. Other frameworks remain. |
| OBS-04 | P0 | Preserve live controls after zoom, overlays, and navigation. | TESTED | COACH zoom-pruning regression and FIELD; live field controls remain accessible. |
| OBS-05 | P0 | Provide useful extra AX visibility without presenting disabled or hidden nodes as actionable. | TESTED | Gameday inactive tabs are exposed with disabled/offscreen annotations. Broader action gating still needs coverage. |
| OBS-06 | P0 | Stable element targeting; reject stale identities after user interaction. | TESTED | COACH clear-filters race rejected a stale target. Identical sibling/recycled-row cases remain. |
| OBS-07 | P0 | Full state and diffs accurately describe changes, removals, and their baseline. | RECHECK | COACH/FIELD basic transitions passed; the new build stops internal wait_for polling from advancing the rendered baseline (unverified), and presentation changes can cause false churn. DATA-03 must test skipped/internal observations and independent consumers. |
| OBS-08 | P0 | Relaunch detection invalidates old process/element targets. | RECHECK | REVIEW and existing relaunch runner; repeat on current installed build. |
| OBS-09 | P0 | Explicit window selection sticks; ambiguity is refused; no silent switch to another Simulator/device window. | IMPLEMENTED | CODE/REVIEW; multiwindow operation needs comparative live trial. |
| OBS-10 | P0 | Report window geometry and map observations to current coordinates. | TESTED | FIELD fixed geometry and correct pan; moved/resized-window recovery remains OBS-11. |
| OBS-11 | P0 | A move/resize between read and action is rebased safely or rejected before delivery. | RECHECK | New pointer guard installed; deliberately exercise movement during preparation. |
| OBS-12 | P1 | Observe sheets, alerts, menus, nested scroll views, and virtualized collections without losing targets. | RECHECK | COACH editor transitions and REVIEW; broaden to AppKit dialogs and recycled lists. |
| OBS-13 | P1 | Show focused element, selected text, and per-target capabilities accurately. | IMPLEMENTED | CODE/REVIEW; validate against actual selection and platform limitations. |
| OBS-14 | P1 | Long content and large trees remain discoverable without silent loss or excessive noise. | RESEARCH | SKY describes truncation limitations; define retrieval and output-budget cases for Leap. |

## Pointer input and user coexistence

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| PTR-01 | P0 | Semantic click by index or unique label changes the intended control. | TESTED | COACH/FIELD. Duplicate labels require explicit index. |
| PTR-02 | P0 | Offscreen AXPress remains usable when the app supports it. | TESTED | COACH offscreen PASS press worked without scrolling. |
| PTR-03 | P0 | Definitively unsupported AXPress never falls through to invalid/clipped coordinates. | RECHECK | Historical clipped-target refusal passed; new ambiguous-AXPress guard changes this path. Repeat safe refusal and supported fallback separately; see RUN-AXPRESS. |
| PTR-04 | P1 | Automatically reveal a clipped target and complete the intended action. | FAILED | Gameday accepts AXScrollToVisible but does not reveal it. Safe refusal works; successful automatic reveal does not. |
| PTR-05 | P1 | Recover when reveal is ignored using bounded scrolling, fresh identity checks, and visible geometry. | PENDING | Existing manual AX-scroll recovery worked; automated feedback-driven recovery is not implemented. |
| PTR-06 | P0 | Coordinate double-click zooms the intended canvas point in background and foreground. | TESTED | FIELD latest unified-pointer pass, native Gameday. |
| PTR-07 | P0 | Coordinate drag pans the canvas in the requested direction and distance in both modes. | TESTED | FIELD +120/−80, matching screenshots and fixed outer window. |
| PTR-08 | P0 | Reset/full-view icon restores the diagram and usable AX controls. | TESTED | FIELD repeated AX reset to Default view. |
| PTR-09 | P0 | One window-targeted pointer path regardless of foreground status; activation does not switch to real-mouse HID. | TESTED | CODE plus FIELD identical foreground/background zoom/pan results. |
| PTR-10 | P0 | Background gestures preserve the user's foreground app and target window geometry. | TESTED | FIELD background header and unchanged bounds; extended concurrent user input remains PTR-12. |
| PTR-11 | P0 | Explicit activation brings the requested app forward without changing gesture semantics. | TESTED | FIELD foreground:true; standalone activate tool and window-raise variants remain to test. |
| PTR-12 | P0 | User mouse/keyboard activity, focus changes, cancellation, and errors during gestures do not corrupt either app's input state. | RESEARCH | Earlier concurrent physical input confounded HID tests. Controlled coexistence/race coverage is still required. |
| PTR-13 | P1 | Single coordinate clicks, right/middle clicks, triple-clicks, and modifier-clicks work correctly. | RECHECK | Earlier coordinate Save worked, but transport changed; test each variant separately. |
| PTR-14 | P1 | Drag editable objects, route waypoints, sliders, and reordered rows; preserve modifiers. | IMPLEMENTED | Drag exists; only field panning has the current comparative pass. |
| PTR-15 | P0 | Visible virtual pointer/ripple indicates the intended target without intercepting input. | TESTED | User observations plus FIELD/CODE. Retain visibility even over an overlapping foreground window. |
| PTR-16 | P1 | Retarget safely across overlapping windows, negative display origins, Retina scales, and multiple displays. | RESEARCH | Single-window geometry passed; no general coordinate-space certification. |
| PTR-17 | P0 | Unsupported routing APIs or missing windows produce clear failure before input. | IMPLEMENTED | New SPI/window guards; exercise those error branches. |

## Scrolling

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| SCR-01 | P0 | Indexed whole-page vertical scroll moves correctly, reaches both bounds, and reverses. | TESTED | SCROLL: 0→0.7176→1→0.2824→0; Sky 0→0.7297→1→0.2703→0. Exact page-size parity is not claimed. |
| SCR-02 | P0 | Scrolling preserves background focus and behaves equivalently with explicit foreground activation. | TESTED | CAM-01 native restart: wheel half-page 0→0.3312434692→0 in both modes; background preserved and window unchanged. Gameday scope. |
| SCR-03 | P1 | Horizontal page scrolling has correct direction, bounds, and recovery. | IMPLEMENTED | CODE action mapping; no live horizontal comparison. |
| SCR-04 | P1 | Coordinate-only, pixel, and fractional-page wheel requests actually move content. | TESTED | CAM-01 field-51 routing fix passed native MCP: half-page and 240-pixel down/up move and restore. Exact pixel displacement not measured; Sky page distance differs and macOS pixels rejected. |
| SCR-05 | P1 | Nested containers, long lists, and virtualized rows scroll the intended region. | IMPLEMENTED | Ancestor AX-page routing exists; test nested/virtualized cases. |
| SCR-06 | P0 | Partial multi-page failure reports completed work and never replays accepted pages. | IMPLEMENTED | CODE/REVIEW; failure injection/live recovery case needed. |

## Text, keyboard, and secondary actions

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| TXT-01 | P0 | Replace search/title/notes exactly and verify the full resulting value. | TESTED | COACH search, title, coaching notes, player notes. |
| TXT-02 | P0 | Append or replace selection with type_text without duplication or lost caret intent. | RECHECK | REVIEW describes fixes; run explicit append/selection/uncertain-write scenarios. |
| TXT-03 | P1 | select_text supports exact match, prefix/suffix disambiguation, and caret-before/after insertion. | IMPLEMENTED | Tool and runner exist; runner presence alone is not a pass. |
| TXT-04 | P1 | Unicode, emoji, multiline text, long values, and empty-string clearing remain exact. | RECHECK | Historical coverage is incomplete; avoid unintentional Return submission. |
| TXT-05 | P1 | Numeric and boolean AX values work for sliders, toggles, and checkboxes. | IMPLEMENTED | REVIEW/CODE typed conversion; live control matrix needed. |
| TXT-06 | P0 | Plain/HTML paste inserts correctly and preserves the user's clipboard, including a concurrent copy. | RECHECK | Clipboard race fix in REVIEW; no current successful end-to-end paste evidence. |
| KEY-01 | P0 | Return, Escape, Tab, arrows, function keys, and modifier chords reach the intended target. | RECHECK | Existing keyboard runners and historical evidence; verify current build and app families. |
| KEY-02 | P0 | Menu shortcuts and semantic confirm/cancel work without needless activation. | RECHECK | AX-first implementation; test menus, modal cancellation, and shortcut collisions. |
| KEY-03 | P0 | Pinned-window keyboard input cannot leak into another key window. | RECHECK | REVIEW guard; deliberately test two windows and refused focus change. |
| KEY-04 | P1 | Listed secondary AX actions work: expand/collapse, increment/decrement, show menu, confirm/cancel, raise. | IMPLEMENTED | Scroll-page evidence is tracked in SCR-01; it does not prove these other action families. Individual live trials pending. |

## Screenshots and visual fallback

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| VIS-01 | P0 | Capture the selected app window while covered, without including the covering chat window. | TESTED | FIELD background screenshots. |
| VIS-02 | P0 | Screenshot points match action coordinates and state identifies the scale. | TESTED | FIELD at 1080×748 and scale1; alternate scales/displays remain PTR-16. |
| VIS-03 | P1 | Explicit window capture selects the intended Simulator/device window. | RECHECK | Earlier schema report described success; repeat controlled multiwindow capture and subsequent targeting. |
| VIS-04 | P1 | Crop, scale, PNG/JPEG save, parent-directory creation, embed/save-only modes work. | RECHECK | REVIEW fixes and prior save-only report; current complete format/crop matrix not recorded. |
| VIS-05 | P0 | Text-only observation is the default; screenshots remain available for canvas-only state. | TESTED | COACH/FIELD AX-first workflow and explicit visual verification. |
| VIS-06 | P1 | Minimized/off-Space/unavailable capture fails clearly without confusing another window for the target. | IMPLEMENTED | Needs deliberate error-path tests. |

## Runtime, outcomes, and recovery

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| RUN-01 | P0 | Installed stdio MCP initializes and exposes current tools after session restart. | TESTED | Repeated native sessions including FIELD; compatibility transport installed. |
| RUN-02 | P0 | Claude Desktop/Code and Codex discover the same current schemas without renaming leap. | RECHECK | User confirmed fresh Claude ToolSearch schema earlier. Cross-client current-build matrix remains. |
| RUN-03 | P0 | Build/sign/install preserves registration and permissions identity, with recoverable previous bundle. | TESTED | FIELD installation checkpoints and resumed native tools. Wider OS/TCC matrix remains. |
| RUN-04 | P0 | Distinguish verified state changes, dispatched input, partial success, and unavailable post-action observation. | FAILED | EDIT demonstrated false no-action reporting after persisted Save. RUN-AXPRESS guards duplicate fallback but full typed outcomes/fresh error evidence remain DATA-01. |
| RUN-05 | P0 | Serialize tool calls and complete batches without interleaving target/focus state. | RECHECK | REVIEW implementation; concurrent-request and mixed-gesture regression needed. |
| RUN-06 | P0 | batch stops on failure, identifies completed steps, and avoids duplicate edits on recovery. | IMPLEMENTED | CODE and existing runner; exercise partial-failure recovery explicitly. |
| RUN-07 | P0 | Settling and wait_for handle asynchronous changes and bounded timeouts without treating stillness as completion. | IMPLEMENTED | Budgeted read/quality correction now implemented; native recheck pending. Historical failure: Native Save: synchronous AX acquisition overran a 3-second polling budget by roughly 14 seconds. Current-state checks work, but strict deadline handling remains open; recording-save-native-trial.md. |
| RUN-08 | P0 | Invalid/extreme inputs are bounded and rejected without crashes or unintended actions. | RECHECK | REVIEW records adversarial numeric checks; changed pointer routing needs current regression. |
| RUN-09 | P0 | Permissions diagnostics distinguish AX from capture permissions and explain recovery. | IMPLEMENTED | Tool exists; test denied/revoked permissions and installed identity without granting anything automatically. |
| RUN-10 | P0 | App allowlisting, secure-text redaction, and user-authorized action boundaries remain effective. | RECHECK | REVIEW partial coverage; current negative tests required. |
| RUN-11 | P0 | Cancellation/stop releases pressed inputs and synthetic focus; no stuck gesture or runaway activity. | PENDING | REVIEW leaves explicit stop mechanism open; define client-cancel behavior and cleanup guarantees. |
| RUN-12 | P1 | Idle cleanup releases capture indicators/resources and recovers on next use. | IMPLEMENTED | CODE/runner; sustained idle/reconnect test needed. |
| RUN-13 | P1 | Explicit target/session handles support independent windows without shared pinning surprises. | RESEARCH | REVIEW proposes handles; determine whether current serialized app sessions satisfy required workflows first. |
| RUN-14 | P0 | Structured outcomes separately report dispatch, API acknowledgement, observation and expectation results. | PENDING | DATA-01 owns implementation; see design result contract. RUN-AXPRESS is only the installed ambiguous-press guard; it does not implement this contract. |
| RUN-15 | P1 | Tool/skill/README behavior claims match the installed implementation and known limits. | RECHECK | Tool and skill updated for unified pointer. README still has older focus/private-API claims; reconcile with window-location SPI and actual keyboard behavior. |

## Cross-app and Simulator coverage

A pass in Gameday does not certify these environments. Compare outcomes using the same visible starting state, not necessarily identical backend calls.

| ID | Pri | Required environment / acceptance scenario | Status | Evidence and remaining scope |
|---|---|---|---|---|
| ENV-01 | P0 | Native Gameday SwiftUI: zoom/pan/reset with foreground/background equivalence. | TESTED | FIELD latest pass. |
| ENV-02 | P1 | Standard AppKit app: text, menus, sheets, tables, scrolling, and two windows. | RECHECK | Historical observations; current installed comparison needed. |
| ENV-03 | P1 | Electron/Chromium or WKWebView native surfaces: focus, text, clicks, and scrolling. | RESEARCH | Determine native-AX limits and supported fallbacks; browser DOM automation is a separate integration. |
| ENV-04 | P1 | Custom canvas app (e.g. Blender): pointer modifiers, drag, and keyboard controls. | RESEARCH | No current comparative certification. |
| ENV-05 | P1 | iPhone Simulator: AX state/press/text plus canvas tap, double-tap, drag, and scroll. | RECHECK | Earlier Simulator runners exist; new window-coordinate transport needs device-specific validation. |
| ENV-06 | P1 | iPad Simulator: same scenarios across orientation, resizing, and device switching. | RECHECK | SKY historical baseline; current Leap trial needed. |
| ENV-07 | P1 | tvOS Simulator: screenshot-driven navigation via keys, accurate no-AX-tree limitation. | RESEARCH | Capability is documented; complete visual workflow and focus delivery need testing. |
| ENV-08 | P1 | Multiple Simulator windows: explicit target persists across reads, screenshots, edits, and keys. | IMPLEMENTED | Window pinning exists; verify without silently following the key device. |
| ENV-09 | P1 | Supported macOS releases/display configurations retain routing, permissions, and capture behavior. | RESEARCH | Record OS/build/display configuration per run; private window-location API needs compatibility coverage. |

## Coach workflow acceptance

| ID | Pri | Scenario | Status | Evidence and remaining scope |
|---|---|---|---|---|
| FLOW-01 | P0 | From unfamiliar open app, discover controls, filter/search, select and inspect a play. | TESTED | COACH ordered Sky/Leap comparison. |
| FLOW-02 | P0 | Sideline use: next/previous, down filters, empty-result recovery, field/information switching. | TESTED | NAV closes both empty-search and third-down recovery without user assistance. COACH/FIELD retain other navigation evidence. |
| FLOW-03 | P0 | Halftime: create play, assign library routes, edit player/coaching notes, mirror and restore, save. | TESTED | COACH saved TRIAL LEAP - Halftime Slant Flat. |
| FLOW-04 | P0 | Find and reopen the saved play; verify exact routes/notes and no unintended existing-play edits. | TESTED | COACH search/reopen and notes. |
| FLOW-05 | P1 | Saved play survives Gameday relaunch and can be edited and resaved. | PENDING | Session reopen was tested; app relaunch persistence was not. Plan a disposable trial record. |
| FLOW-06 | P1 | Create/reuse/edit a route-library entry and edit a route waypoint, not just assign an existing route. | PENDING | Assignment passed; route-authoring workflow not covered by current comparative trial. |
| FLOW-07 | P0 | Repeat the full coach scenario on the current build with no manual recovery substitution. | RECHECK | Complete original trial predates unified pointer changes. Use as a final integration gate after focused gaps. |

## Blender and Unity creation workflows

Workflow: [Leap 3D/game skill](../skills/leap-3d-game-workflows/SKILL.md), with [Blender](../skills/leap-3d-game-workflows/references/blender.md) and [Unity](../skills/leap-3d-game-workflows/references/unity.md) guides. These are newly documented acceptance requirements, **not newly tested capabilities**. They extend native app coverage without requiring every modeling operation to be performed by mouse. Priorities apply when delivering these creation workflows; they do not invalidate the scoped Gameday pass.

The skill assumes a capable Leap interface but checks actual schemas at use time. A successful scripting workaround completes an artifact; it does not certify an absent UI primitive. Task-specific model/game scripts belong with the user's project rather than requiring a generic Leap script-execution endpoint.

| ID | Pri | Feature / acceptance requirement | Status | Evidence and remaining scope |
|---|---|---|---|---|
| ART-01 | P0 | Identify and target an editor region independently of the app window: Blender viewport/Outliner/properties; Unity Scene/Game/Inspector/Console. | RESEARCH | App-level targeting exists; region-specific keyboard focus and shortcut routing have no recorded Blender/Unity pass. Extends OBS-13/KEY-03. |
| ART-02 | P0 | Orbit/pan/zoom using middle/right-button drags, modifiers, and wheel input. | PENDING | Input internals accept drag buttons, but the current MCP drag schema does not expose a button selector. Add the tool-to-engine plumbing and verify releases/directions. Wheel is SCR-04. |
| ART-03 | P1 | Hover/move to a region without clicking or stealing the user's physical cursor; observe tooltips and hover-dependent controls. | PENDING | Internal movement code exists; no public hover/move tool in the current surface. Validate actual target-app hover response. |
| ART-04 | P0 | Hold/release keys and buttons for bounded durations and simultaneous combinations; always release on cancellation or error. | PENDING | press_key provides discrete chords, not general sustained input. Needed for direct game controls and some editor interactions; extends RUN-11. |
| ART-05 | P1 | Relative/captured pointer movement supports mouse-look or constrained viewport interaction without corrupting the user's cursor. | RESEARCH | Absolute drag parity does not prove relative-input support. Determine feasible behavior and explicit foreground constraints. |
| ART-06 | P1 | Continuous pointer paths and repeated strokes support sculpt/paint tools and curves, not only straight endpoint drags. | RESEARCH | Define sampling and button-state semantics; pressure/tablet input only if the requested task requires it. |
| ART-07 | P0 | Expose or reliably infer active mode, region, object selection, transform state, and Play/Edit mode before context-sensitive commands. | RESEARCH | Combine AX, screenshots, and optional application data. Extra visibility must distinguish actual active state from hidden controls. |
| ART-08 | P1 | Manipulate node graphs, UV editors, animation timelines/keyframes, transform gizmos, and draggable Inspector values. | RECHECK | Reuses pointer/keyboard features, but these surfaces are untested. Test each surface and undo/recovery separately. |
| ART-09 | P0 | Operate Open/Save As/export/import dialogs and distinguish selected files, overwrite state, and completed saves. | RECHECK | Gameday Save is not coverage of native file dialogs or Blender/Unity custom file browsers. |
| ART-10 | P0 | Detect compile/import/render/build completion and errors without equating a settled tree with a finished job. | IMPLEMENTED | wait_for and observation primitives exist; combine with logs/artifacts when appropriate. Live long-job, failure, and cancellation trials needed. |
| ART-11 | P0 | Capture the intended viewport/render/Game view at useful detail and inspect multiple views or animation frames. | RECHECK | Window screenshots passed in Gameday; Blender render windows and Unity views/crops require validation. |
| ART-12 | P0 | Inspect actual playback and gameplay over time, including transient states and animation defects. | RESEARCH | Single screenshots can miss timing/deformation errors. Define timestamped frame sampling or a suitable capture workflow; video tooling is not automatically required. |
| ART-13 | P0 | Verify undo/redo, canceled transforms, failed scripts, interrupted gestures, and recovery without duplicate edits. | RECHECK | Existing key/menu/error primitives; meaningful editor recovery cases not tested. |
| ART-14 | P1 | Read long Console/traceback messages and identify actionable errors without losing essential details to truncation. | RESEARCH | Extends OBS-14/RUN-04; app logs may supplement UI text. |
| ART-15 | P0 | Coordinate scripted construction with UI state: one authoritative project/file, no stale UI overwrite or duplicate generated assets. | PENDING | Workflow acceptance, not necessarily a new MCP tool. Implement task-scoped generation/checkpoint conventions and demonstrate reopen safety. |
| ART-16 | P0 | Blender end-to-end: construct an editable stylized character, inspect multiple views, refine, save and reopen with required materials. | PENDING | The skill includes Mickey Mouse as an example; no character was created or tested in this task. |
| ART-17 | P1 | Animation-ready asset: validate topology, rig/weights, representative poses and motion, and saved dependencies. | PENDING | Required only for animation/game-ready deliverables, not every static model. |
| ART-18 | P0 | Unity end-to-end: implement a playable loop, compile/import, enter Play mode, operate controls, exit cleanly, save and repeat. | PENDING | Requires direct Leap play-testing in addition to any scripted tests. |
| ART-19 | P1 | Blender-to-Unity export/import preserves intended scale, orientation, materials, rig and animation. | PENDING | Verify the destination scene; a successful file export is insufficient. |
| ART-20 | P1 | Requested standalone game build launches and its core loop works through Leap. | PENDING | Separate target/window discovery and gameplay check; editor Play mode is not build verification. |

The immediate creation benchmark is the paired Mickey Mouse head trial below. It deliberately uses basic-shape editor operations to reveal UI failures. The scripting-assisted production workflow remains useful later; it must not bypass the interaction capabilities this benchmark is intended to test. Unity gameplay, rigging, and advanced sculpting are later extensions, not prerequisites for this benchmark.

## Certification and execution order

For each promotion, record the installed binary/build identity, OS, app version, window/display configuration, starting state, ordered actions, observed results, foreground/background status, and evidence link. Measure screenshots for pan/zoom and state/value changes for semantic controls. Record manual intervention and remaining exceptions explicitly.

Certification requires two successful runs in fresh MCP sessions for the declared scope, comparison against Sky where available, relevant error/recovery checks, and no unresolved P0 defect in that scope. Cross-app certification additionally requires the appropriate ENV rows. A new implementation does not need a long pre-install test cycle: follow the user's workflow of fix → build/install → restart → focused native verification.

Immediate execution order is **REC-00–03 in PLAN.md, followed by remaining CAM-03–12 below**. CAM-00–02 have scoped historical passes; do not restart them wholesale. Durable recording begins before new diagnostic actions, not after failures. Finish the bounded Gameday checks, exercise both iPhone and iPad versions, then prioritize the Blender head benchmark. Do not postpone Blender until every general feature row is certified. tvOS, Unity gameplay, advanced character work, and the broader compatibility matrix follow this campaign.

Measure comparative task success, wrong-target events (must be zero), manual interventions, tool calls, wall time, and screenshot/output cost. No speed or token-efficiency advantage is currently certified. More AX visibility is beneficial only when it improves discovery without misleading actions.

## Active campaign: Gameday → iPhone/iPad → Blender

User-directed priority: make Leap at least as effective as Sky in practical interactions, with a **simple Mickey Mouse head built from basic shapes in Blender** as the main revealing test. Preserve useful extra AX visibility; do not force Leap to imitate Sky's limitations. This campaign is an execution checklist layered over the feature inventory above.

### Paired test and repair protocol

For each feature-sized checkpoint:

1. Discover the app/window and record its current state. Establish a recoverable starting state and the observable success condition. Use task-owned artifacts and preserve the user's open work.
2. **Sky first:** perform the operation, observe its real effect, and record the ordered actions, coordinates/scale where relevant, outcome, and any manual intervention. If Sky itself fails, investigate the app/target before attributing a defect to Leap; its failure does not waive the required outcome.
3. Restore an equivalent starting state. **Leap second:** perform the same user-level operation sequence with the same inputs and verify its effect. Re-resolve target identities/indices and coordinates for Leap; never copy Sky's element IDs. Better semantic access is allowed and should be recorded.
4. If Leap fails or only works through an inferior workaround, record the precise gap and affected feature IDs. Do not mark a dispatch or unrelated successful fallback as a pass. Diagnose, fix Leap, build/sign, and reinstall under the unchanged `leap` registration. Update tool/skill descriptions when semantics change.
5. Tell the user exactly when to restart the session. Until restart, do not test the old loaded MCP as though it were the new build. After restart, verify the installed candidate on the failed case and a small directly affected regression. Build/install is not a pass.
6. Once that case passes, update its evidence/status and advance. Reuse a still-valid Sky baseline instead of repeating the entire trial after every restart. Rebaseline when the app/version/start state materially changes. Save checkpoints so work can resume without recreating completed objects or replaying edits.

Use the existing status vocabulary independently for **Sky** and **Leap** below. PENDING in this table means the trial has not run. RECHECK preserves historical evidence but requires this campaign's focused validation. Feature certification remains subject to the gate above; a campaign TESTED row is not universal certification.

| Checkpoint | Scope and observable success | Sky status | Leap status | Feature IDs / evidence / next action |
|---|---|---|---|---|
| CAM-00 | Native Gameday field: zoom, pan right120/up80, reset; no window displacement; compare foreground/background. | TESTED | TESTED | FIELD, PTR-06–11, ENV-01. Retain completed evidence; only rerun if a relevant fix changes this path. |
| CAM-01 | Native Gameday filters: indexed and coordinate/fractional scroll, top/bottom recovery, background preservation. Test horizontal only on a surface that actually scrolls horizontally. | TESTED | TESTED | SCROLL: window-field-51 build passed native restart; half-page foreground/background equal, pixel movement/reversal and indexed boundaries passed. Horizontal surface not present in this panel. |
| CAM-02 | Native Gameday: select/search, information/field, next/previous, Sideline/Playbook, empty-result recovery without user substitution. | TESTED | TESTED | COACH/FIELD and trial-navigation-details.md: native search/select/info/next/previous/Sideline passed; both empty-search and third-down recovery restored 88 plays without user input. |
| CAM-03 | Native Gameday editor: disposable play or existing trial copy; replace notes, choose a route, save/search/reopen exact values. | TESTED | RECHECK | COACH, TXT-01, FLOW-03–04; trial-editor-details.md. Notes persisted, but Save returned misleading no-action error. Ambiguous -25204 recovery and mirrored-route Save/reopen now passed. New route replacement and visual geometry remain; see recording-save-native-trial.md. |
| CAM-04 | Simulator discovery: explicitly identify the open iPhone and iPad device windows and their Gameday instances; target one without silently switching the other. | TESTED | TESTED | [Native discovery](iterations/2026-09-20-postrestart.md): correct distinct playbooks and sticky Leap iPhone reads. Read-only scope; screenshot/keyboard routing remain unverified. iPad capture reported two read failures. |
| CAM-05 | iPhone Gameday: read controls, filter/search, scroll a real list, select a play, view information, zoom/pan/reset the field where supported. | PENDING | PENDING | ENV-05, PTR/SCR/VIS. Record which actions are AX versus coordinate/gesture paths and verify actual content changes. |
| CAM-06 | iPhone Gameday: edit task-owned notes/route assignment, save/reopen; verify text focus and no input into the other device. | PENDING | PENDING | TXT-01–04, KEY-03, FLOW-03–04. Include soft-keyboard visibility/dismissal where needed. |
| CAM-07 | iPad Gameday: repeat CAM-05/06 with its actual layout, then exercise rotation/device switching and re-observe before the next action. | PENDING | PENDING | ENV-06/08, OBS-08–11, PTR-16. iPhone success cannot stand in for iPad. |
| CAM-08 | Blender setup/navigation: preserve existing work, establish a disposable baseline, inspect active region/mode, orbit/pan/zoom and select objects. | PENDING | PENDING | ART-01–03/07/11, ENV-04. Record supported Sky operations before deciding which Leap primitive must be added. |
| CAM-09 | Blender construction: create the same simple Mickey head through the paired basic-shape sequence below. | PENDING | PENDING | ART-16, PTR-13–14, TXT/KEY, ART-07/13. **Primary diagnostic benchmark.** Compare shape, transforms, selection, and actual action effects. |
| CAM-10 | Blender verification: inspect front/side/three-quarter views, correct a transform, undo/redo, verify materials and intended symmetry. | PENDING | PENDING | ART-02/07/08/11/13. Do not accept a favorable camera angle hiding incorrect geometry. |
| CAM-11 | Blender persistence: save separate Sky/Leap `.blend` files and previews; reopen and verify objects, materials, transforms, and appearance. | PENDING | PENDING | ART-09/16, VIS-04. No completed artifact exists yet. A screenshot alone does not satisfy this checkpoint. |
| CAM-12 | Repeat the core Blender interaction sequence in fresh sessions; compare practical success and remaining exceptions, and assign scoped certification where earned. | PENDING | PENDING | Certification gate. Report manual interventions, workarounds, calls/time, and unresolved feature gaps; do not claim all-app parity. |

### Simulator comparison rules

Use the already-open iPhone and iPad apps as the discovery starting point. Record device title, OS, orientation, app screen, and window dimensions. Use each platform's own Sky baseline because layouts and available gestures can differ. Before text input, verify the selected device and field; after rotation, sheet transitions, or keyboard appearance, re-read state and screenshot when coordinate mapping matters.

Do not reset simulator data, reinstall Gameday, delete user plays, or change device configuration just to create a convenient baseline. Use reversible navigation and clearly named trial records. If an app capability is absent on a platform, record that explicitly and choose an equivalent supported user task; do not fabricate a pass or silently skip it.

### Main Blender benchmark: simple Mickey Mouse head

**Deliverable:** two separately saved, editable `.blend` files—one from Sky and one from Leap—with a recognizable simple Mickey head made from basic primitives, plus comparable previews. No full body, rig, animation, game integration, detailed sculpting, or production topology is required. This is an interaction benchmark, not a polished-character commission.

Use separate copies of one baseline scene. Establish the exact primitive choices and numeric transforms during the Sky trial, then record and replay them with Leap. Choose a modest recognizable design: head sphere, two symmetric round ears, a simple muzzle and nose, and two simple eyes. Use scaled primitives and simple materials. Extra detail is optional only if it serves a specific interaction test and is applied equally to both copies.

| Step | Shared user-level operation | Evidence required |
|---|---|---|
| B01 | Open the baseline copy and identify viewport, mode, and active object. | Window/region state; baseline screenshot. |
| B02 | Add and name the head primitive; enter its numeric dimensions/transform. | Named object plus visible geometry; record chosen values. |
| B03 | Add an ear, scale/place it, duplicate for the second ear, and set the mirrored position. | Two separately identifiable ears, matching sizes and symmetric placement. |
| B04 | Add/place basic muzzle, nose, and eyes; use the same primitive sequence and values in both runs. | Recognizable head and correct object membership; no duplicate artifacts from retries. |
| B05 | Assign simple dark/light materials and smooth shading as appropriate. | Visible appearance and saved material references. |
| B06 | Orbit, pan, zoom, select a part, make a small deliberate transform, undo it, then redo/restore as recorded. | Correct region routing, gesture direction, selection and undo semantics. |
| B07 | Inspect front, side, and three-quarter views; correct any recorded construction error in both runs. | Comparable previews exposing silhouette and depth, not only the best angle. |
| B08 | Save each artifact under a distinct trial name, reopen, and inspect. | Real editable files; persisted geometry, transforms and materials. |

For this diagnostic run, use **Sky UI operations for the Sky artifact and Leap UI operations for the Leap artifact**. Do not generate one finished head through `bpy` and import/duplicate it as both results. Filesystem work may prepare directories and preserve copies; read-only scene inspection may independently verify outcomes. If UI scripting becomes necessary to complete the user's deliverable, label the departure and leave the bypassed UI feature unresolved. Different element indices or a more reliable Leap AX action are acceptable; changing the substantive modeling operation to evade a failure is not an equivalent replay.

First prove normal background operation and foreground equivalence for the relevant interactions. Where explicit foreground is required, announce it and record why. Pointer/keyboard conflicts and user intervention are evidence, not noise to discard. Lack of a middle-button/hover/held-input parameter should become a concrete checklist issue, not an invented tool argument.

### Repository-local evidence storage

Keep all campaign scripts, tests, logs, screenshots, checkpoints, and deliverables under this repository (`~/src/claude-leap`). Do not use `/tmp`, temporary directories outside the repository, or another project as the evidence store.

- Reusable runners/probes: `scripts/`; repeatable scenarios: `Tests/` (existing directory spelling).
- Human-readable comparisons and restart checkpoints: `docs/research/`.
- Opt-in recording implemented: `.leap/leap.db` and `.leap/sessions/<session-id>/`, locally excluded via Git; native verification pending. Automatic attachment remains pending.
- Curated/exported per-run raw evidence: `artifacts/test-runs/<run-id>/` with `sky/`, `leap/`, and build logs as useful.
- Blender baseline and paired editable models/previews: `artifacts/blender/mickey-head/`.
- Build output: existing `dist/`; downloaded tooling: `artifacts/downloads/`; future rollback copies: `artifacts/backups/`.
- Recovered prior diagnostics: [archive and provenance](../artifacts/reference/2026-09-20-recovered/README.md).

Installation still places the runnable app in `~/Applications`; OS/tool-managed caches are not campaign evidence. Preserve the repository build and logs. Historical reports retain their original paths; the recovery manifest maps surviving scratch files to repository copies. Some screenshots existed only in tool responses and have not been recreated. Keep relevant evidence eligible for version control; large binaries may stay locally ignored with their identity/provenance recorded. Do not commit credentials or unrelated account configuration.

### Recording and resuming the campaign

Continue existing native reports. Create Simulator and Blender paired reports under `docs/research/` when those trials actually start, and link them here. Do not prefill success evidence. Keep the intended artifact paths, last completed step, current app state, installed build identity, failed operation, fix description, and exact next restart test in each report.

For each operation record: checkpoint/step ID, initial state, Sky action/outcome, Leap action/outcome, before/after evidence, app/device/build context, focus behavior, required manual assistance, and related feature IDs. The latest verified result supersedes failed candidates without removing the investigation history. At every restart checkpoint tell the user what to leave open and what will be tested next.

## Scope boundaries

This checklist targets native macOS apps and Simulator operation. Dedicated browser DOM/CDP automation, remote desktop/VM management, screen auto-unlock, audio recording, and reproducing every Sky service endpoint are not requirements merely because the extracted reference contains them. Add such extensions only when they serve a user workflow. Leap does not need a virtual HID device or an identical Sky implementation to meet the objective.

### CAM-03 action-result safety follow-up

| ID | Priority | Requirement | Status | Evidence |
|---|---|---|---|---|
| RUN-AXPRESS | P0 | An ambiguous AXPress reply must not trigger a second click or claim nothing happened. | TESTED | Native Edit, player selection, mirror and Save returned -25204 with completed effects; no fallback reported, one journal intent/result per action and fresh evidence. Mirrored state survived reopening. Scoped native trial: recording-save-native-trial.md; explicit actionUnsupported fallback still needs its own case. |

### Durable observations, verified actions and operator console

Design: [Runner-inspired observation/session evaluation](research/observation-session-design.md). The first recording slice is installed but awaits native verification; PARTIAL rows distinguish remaining design requirements from deployed behavior.

| ID | Priority | Requirement | Status | Evidence / acceptance |
|---|---|---|---|---|
| DATA-01 | P0 | Separate dispatch, API acknowledgement, observation and expectation outcomes; return fresh evidence after ambiguous actions. | PARTIAL | Action intent/result journal and fresh error state implemented; full typed dispatch/acknowledgement/expectation contract remains. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-02 | P0 | Durable session/action/snapshot IDs, immutable captured trees, completeness/freshness metadata and bounded retention. | PARTIAL | UUIDs and retained trees implemented, with capture cap and storage budget. Durable window identity, capture intervals and retention rotation remain. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-03 | P1 | Read-only scoped queries, selected fields, pagination, explicit diff baselines and compact relevant responses. | PARTIAL | Historical event/node filtering and pagination implemented; projections and independent diff baselines remain. Internal wait_for preserved the diff in the native Gameday toggle trial. Node query and exclusive pagination now pass native retrieval of snapshot 9; see recording-save-native-trial.md. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-04 | P0 | Declarative preconditions/postconditions attached to actions and bounded workflows. | PARTIAL | verified_action performs one input with before/after current-state checks. Persisted verdicts passed native checks; gating preconditions and compound predicates remain. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-05 | P1 | Save-only screenshot evidence linked to window/snapshot/time/scale; fetch or crop on demand. | PENDING | Existing screenshot save-only support is a foundation. Preserve real visual verification for canvases. |
| DATA-06 | P0 | Capture supported AX notifications between tool calls in a durable session/interaction/action journal; retrieve history without replaying input. | PARTIAL | Dedicated AXObserver thread and durable notification envelopes implemented. Native blocked-action/transient-event proof and richer scoped observations remain. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-07 | P0 | Arm temporal expectations before dispatch and distinguish current state from events observed during an interaction. | PENDING | A transient event may disappear before the next tree read. Event absence with incomplete coverage is unknown; association is not causal proof. |
| DATA-08 | P0 | Pin project storage; local Git exclusion works idempotently in normal repos/worktrees; missing-store historical reads create nothing. | IMPLEMENTED | Explicit root, local Git exclusion and read-only missing-store queries implemented; Normal repository attachment and effective exclusion passed native Gameday trial; worktree/non-Git/idempotence cases remain. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-09 | P0 | Writer concurrency, schema handling, crash/restart and storage failures preserve evidence and truthful dispatch state. | PARTIAL | Single writer, schema guard, interrupted-session markers and storage failure latch implemented; fault injection and fully typed outcomes remain. [Checkpoint](research/recording-v1-checkpoint.md). |
| DATA-10 | P0 | Distinguish acquisition limits/unsupported data, recording loss/retention and response omissions. | PARTIAL | Acquisition cap, notification overflow and response omissions distinguished in first slice. Controlled loss/cursor fixtures remain. [Checkpoint](research/recording-v1-checkpoint.md). |

Priority clarification: TUI-01–03 are deferred until end-to-end parity. Durable observation/event capture is part of the first implementation increment, not a later optimization.

Storage decision: adopt Tracer-style project-local `.leap/leap.db` plus per-session artifact folders. Pin the caller's project root; create on recording, idempotently exclude via Git's resolved `info/exclude`, preserve `.gitignore`, and support historical read-only access. Current campaign exports stay under `artifacts/test-runs/`. See the design's Tracer evaluation for worktree/concurrency/provenance requirements.


### Deferred operator console

Not a current campaign dependency. Priorities apply only if this phase is reactivated after end-to-end parity.

| ID | Priority | Requirement | Status | Evidence / acceptance |
|---|---|---|---|---|
| TUI-01 | P1 | `leap-cli` observes sessions, action timeline, checks, tree changes and evidence without taking focus. | DEFERRED | User requested Runner-like operator companion; consume shared journal, not a second automation engine. |
| TUI-02 | P0 | Cooperative pause, operator correction and fresh-state hand-back without competing input. | DEFERRED | Explicit IPC/control ownership; cannot cancel already-delivered actions; invalidate stale targets and recheck pending steps. |
| TUI-03 | P1 | Operator annotations and selected-node references reach the agent with session/snapshot/action provenance. | DEFERRED | Deliver on next tool response unless client supports notifications; never treat a highlighted node as an implicit click. |

Latest scoped evidence: [Recording native trial](research/recording-v1-native-trial.md). Event retrieval, action checks and stop/start passed; node pagination fix passed after restart; expectation-result journaling is the next installed increment.

Latest Save evidence: [Native Save and retained history](research/recording-save-native-trial.md). Ambiguous -25204 produced fresh evidence and no fallback; mirrored-route state persisted across Save/reopen. Synchronous AX reads can exceed wait budgets; strict deadline handling remains open.

### Outcome-oriented insights

| ID | Pri | Requirement | Status | Evidence / remaining scope |
|---|---|---|---|---|
| DATA-11 | P0 | Shape-aware summaries highlight uncertain actions, unmet postconditions and missing capture without dumping raw evidence. | IMPLEMENTED | recording_review overview/actions/issues; native validation pending. See [insights layer](research/insights-layer.md). Joined action narratives remain. |
| DATA-12 | P1 | Group repetitive events without merging independent inputs; stable bounded pages retain evidence references. | IMPLEMENTED | recording_review events, through boundary and byte/page budgets; SQL support check passed, native acceptance pending. |
| DATA-13 | P1 | Discover tree structure without values, then request specific evidence. | PARTIAL | recording_nodes outline implemented; richer selectors, field projections and chunked values remain. |
| DATA-14 | P0 | Useful outcome workflows and automatic relevance-based live response budgets keep orchestration inside MCP. | PARTIAL | verified_action and historical review are foundations; compound workflows, compact live state and temporal verification remain. |

Retained before/after expectation results passed native Gameday transitions on build 08a19416; see [insights checkpoint](research/insights-layer.md). These narrow passes do not complete DATA-04.

Timing follow-up: [readiness review](research/timing-and-readiness-review.md). RUN-07 remains FAILED for strict deadline behavior. DATA-10 also needs failed-read/child-read completeness, not only node-cap metadata; otherwise sparse observations can falsely establish absence. Unify action checks and ordinary state capture under one readiness policy.

### Integrated observation candidate

[Implementation and acceptance plan](research/integrated-observation-layer.md) supersedes earlier “not implemented” notes for the following portions only. No new native pass is claimed.

| ID | Pri | Feature | Status | Remaining scope |
|---|---|---|---|---|
| DATA-15 | P0 | Structured fresh/historical UI queries with role, IDs, state, root/depth, fields and byte/count limits. | TESTED | Scoped Gameday role/fields, subtree depths 0–2 and 139-button pagination passed; broader apps and budget edge cases remain. See postrestart iteration. |
| DATA-16 | P1 | Stable retained-content references, raw chunks and on-demand materialization. | IMPLEMENTED | leap_asset for captured text/node fields; binary/image ingestion remains pending. |
| DATA-17 | P1 | Independent snapshot comparisons with completeness metadata and evidence references. | TESTED | Native 370/380 comparison: 34 unique changes across four pages, zero false geometry changes. Durable window identity/partial-observation coverage remain. |
| DATA-18 | P0 | Automatic recording after one project binding and compact ordinary responses. | IMPLEMENTED | bind_project; live validation pending, binding does not survive restart. |
| DATA-19 | P0 | Joined interaction outcomes preserve acknowledgement uncertainty separately from checks. | IMPLEMENTED | interaction_result and recorded verified_action responses; full dispatch taxonomy/compound workflows remain. |

DATA-02/03/10/13/14 have additional implemented portions in this candidate: rendered parent links, capture intervals/errors, raw-value limit markers, structured filters/projections and compact response references. Broad statuses remain PARTIAL until missing scope and native acceptance are complete. RUN-07 does not promise hard cancellation of synchronous OS work.

Integrated native trial: [observed passes and two fixes](research/integrated-native-trial.md). Filtered UI, joined verified outcomes, immutable historical lookup, raw-text/file assets and review overview passed scoped native cases. DATA-17 comparison and DATA-18 first-attachment fixes passed native acceptance in the [postrestart iteration](iterations/2026-09-20-postrestart.md). General statuses remain unverified beyond the named cases.

Postrestart evidence: first attachment, subtree depth, complete button pagination, grouped notification pagination and reversible background verified actions passed scoped native cases. DATA-12 now has native eight-page/101-notification evidence; full concurrency/byte-edge coverage remains. iPad discovery repeatedly reports two acquisition errors. Bounded attribute/error samples are added for the next installed candidate; native diagnosis remains pending.

### Action-scoped deltas

| ID | Pri | Feature | Status | Evidence / remaining scope |
|---|---|---|---|---|
| DATA-20 | P0 | Action responses return bounded deduplicated added/removed/changed controls relative to that interaction's pre-state, with before/after snapshot IDs and continuation. | PARTIAL | Ordinary rendered text diffs and independent ui_diff exist and have native evidence. Automatic structured action-scoped wiring remains; last displayed state must not silently stand in for the pre-action observation. Mark partial/unknown comparisons and retain full snapshots for ui_to_text. Never infer causality or absence from incomplete captures. |
| DATA-21 | P1 | Discover a timestamped interaction timeline with action/outcome summaries and before/after snapshot references for comparisons. | PARTIAL | Timestamped underlying records, recording_review and interaction_result exist. Dedicated joined timeline/continuation interface is pending; ui_diff already compares compatible snapshot IDs. |

Diagnostic acceptance: [AX batch recovery iteration](iterations/2026-09-20-ax-batch-recovery.md). Native metadata identified two AXSubrole -25200 errors on iPad. Single-field batch recovery is the next installed candidate; do not mark the Simulator capture failure resolved before native verification.

Skill delivery: compact usage entrypoint and optional UI reference now synchronized to Claude/Codex via `scripts/install.py --skills-only`; byte equality verified in [skill iteration](iterations/2026-09-20-skill-sync.md). Guidance does not establish feature acceptance.

Batch recovery native result: iPad still has two AXSubrole -25200 failures after two individual retries (zero recoveries); iPhone capture remains clean. Diagnostics passed, recovery hypothesis failed. See [delivery/native iteration](iterations/2026-09-20-delivery-native-check.md). Do not promote Simulator acquisition to complete.

Latest paired iPad result: Sky and Leap both toggled information/field successfully; Sky independently verified Leap restored the field. Leap global read-failure gating and sparse final-deadline observations remain the gap, not demonstrated input failure. Next correction should use attribute/predicate-specific coverage and preserve usable timed observations. [Evidence and rationale](iterations/2026-09-20-sky-subrole.md).

Current candidate: [field-specific quality](iterations/2026-09-20-field-quality.md) adds conservative advisory subrole errors on known non-text controls, blocking coverage checks and explicitly retained earlier observations. IMPLEMENTED, native verification pending; broader predicate-specific dependencies remain incomplete. Next restart test is the same paired iPad transition, then DATA-20/21.
