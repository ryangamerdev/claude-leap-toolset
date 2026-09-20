> **PAUSED by user, 2026-09-20.** Leap MCP removed from Codex configuration. Do not resume or reinstall without user direction. Desktop recheck results and unresolved gaps: [pause checkpoint](iterations/2026-09-20-paused.md).

# Leap release checklist

Updated 2026-09-20. Scope and requirements: [SPECIFICATION.md](SPECIFICATION.md). This table replaces the accumulating checklist for current delivery decisions. The [historical inventory](research/archive/features-before-intent-rebuild.md) preserves feature IDs, earlier passes and evidence; those passes do not certify the rebuilt orchestration.

Status: PENDING = absent; RESEARCH = unresolved approach; PARTIAL = missing required scope; IMPLEMENTED = candidate exists without native acceptance; TESTED = named native case passed; CERTIFIED = repeated declared-scope native/regression acceptance; FAILED = observed unresolved failure; RECHECK = changed path needs replay; DEFERRED = outside release gate. No blanket certification.

| Requirement | Status | Candidate and exact remaining acceptance |
|---|---|---|
| R01 Target discovery/capabilities | IMPLEMENTED | target_list lists Mac apps and simctl devices. WDA uses explicit endpoint and stable backend device identity; actual UDID mapping belongs to runner manifest. Verify both devices and unavailable runner. |
| R02 Session ownership/history | IMPLEMENTED | New session IDs and append-only evidence; close leaves app running. Live handles expire at restart. Protocol fixture retained results/historical snapshots; native restart acceptance pending. |
| R03 Normalized observations | IMPLEMENTED | Mac AX + WDA JSON normalization, partial-read metadata and raw backend roles. Verify guest controls/geometry; selected can be unavailable on WDA. |
| R04 Shared selectors | PARTIAL | Exact id/identifier/role/label, contains/root; complete unique observation required. WDA re-resolution conservatively requires a globally unique named control; scoped repeated-label actions remain a gap. |
| R05 Bounded queries/content | IMPLEMENTED | Fields/depth/filter/frozen pagination; full envelope budget; retained raw field/chunk evidence_read. Verify large native tree and long value. |
| R06 Actions/backends | FAILED | Mac click/double-click/type/set/key/scroll/drag/activate; WDA click/double-tap/type/key subset/scroll/drag/activate/rotate. Guest replace-text and broader gestures unavailable; add only if gate needs them. Native role-qualified Route library and Playbook clicks passed; field information toggle remains failed. Gameday portrait rotation is excluded by app design. |
| R07 Coordinate provenance | IMPLEMENTED | Snapshot + space required, same session/tree/bounds/window/orientation; valid point bounds. No inferred host↔device conversion. Visual changes invisible to AX still require fresh screenshot judgment. Exact interface/physical orientation identity now brackets WDA captures, rejects unstable reads and distinguishes180° rotations; native acceptance pending. |
| R08 Truthful outcomes/no replay | IMPLEMENTED | Step execution/dispatch/acknowledgement/check separated; ambiguous input halts workflow. Protocol fault fixture: one click after lost acknowledgement, completed effect retained, second action skipped. Not a native pass. |
| R09 Assertions/readiness | PARTIAL | Exact values, contains/count, enabled/disabled/selected/existence; preconditions and bounded polling. Partial observations produce unknown. Broader compound predicates and action-specific readiness need acceptance-driven completion. |
| R10 Intent workflows | IMPLEMENTED | Up to50 steps, prevalidated actions, pre/post checks, per-step evidence, skipped dependents, scheduling deadline metadata. Native multi-step case pending. |
| R11 Compact deltas | IMPLEMENTED | Bounded observed changes plus before/after references; identity churn remains possible. Validate relevance on real workflow. |
| R12 Durable failure evidence | IMPLEMENTED | Persist intent before dispatch, per-step/result records, failure screenshots when available, separate capture errors and diagnostics. Protocol fixture passed; native/storage-fault scope remains. File copies add storage beyond DB budget; no pruning. |
| R13 Temporal evidence | PARTIAL | Polling waits retain intermediate snapshots and observed occurrences. Pre-armed notification predicates/transient event coverage remain unproven; no complete-history claim. |
| R14 Regression scenarios | IMPLEMENTED | scripts/run-scenario.py runs reviewed declarative workflows through MCP, writes machine-readable results and exits nonzero unless checks pass. Native reusable scenarios must be authored from accepted workflows. |
| R15 User coexistence | RECHECK | Existing Mac targeted input reused; new WDA focus/cursor behavior requires native comparison. System keyboard fallback restrictions remain. |
| R16 End-to-end acceptance | PENDING | Historical Gameday/Sky evidence retained. New Mac/iPad/iPhone workflows and paired Blender artifacts must complete before release. |

## Installed candidate

[Intent rebuild iteration](iterations/2026-09-20-intent-rebuild.md), [install identity](../artifacts/test-runs/20260920-rebuild/install.json). WDA runner built and health-ready on iPad; this is infrastructure readiness, not UI acceptance. Seven focused contract tests and a protocol fault fixture passed. Restart required to expose new tools in the current host.

## Deferred scope

leap-cli, physical-device provisioning, Android/Windows/browser backends, arbitrary code execution inside workflows, complete event sourcing and virtual HID are not prerequisites. Existing history is preserved; no data reset performed.

## First native WDA checkpoint

[Native WDA trial](iterations/2026-09-20-wda-native.md): guest attachment,619-node observation, correct in-bounds information-control geometry, history and nested retrieval passed scoped native calls. Selector taps returned without expected effect both before and after verified host foreground activation. R06 remains failed for that case. A coordinate test exposed false stale rejection of equal numeric bounds; corrected and installed; after restart the coordinate tap dispatched but still had no observed toggle effect. Neither this correction nor observation success establishes device input parity.

## Landscape checkpoint

[Native checkpoint](iterations/2026-09-20-wda-landscape.md): numeric-bounds guard passed native dispatch; role-qualified Route library and Playbook clicks passed their postconditions. Label-only ambiguous targeting safely refused input. Gameday is intentionally landscape-only, so portrait refusal is not a Leap acceptance failure. Information-control effect remains unresolved. Navigation deltas showed substantial identity churn; compact output alone is not yet proof of useful change summaries.

## Backend comparison and orientation correction

[Iteration](iterations/2026-09-20-wda-orientation.md): Sky semantic and coordinate information toggles passed; Leap mac_ax information toggle and Previous play passed with postconditions. WDA Next play passed; information toggle failed even after landscape orientation and alternate direct-backend touch diagnostic. Corrected WDA protocol aliases and exact orientation provenance; candidate requires restart. Primary next acceptance follows Sky-equivalent mac_ax behavior; WDA remains an explicit additional backend. No scroll pass claimed from the interrupted upside-down trial.

## Sky native pointer correction

[Reference audit](research/sky-native-input-audit.md), [iteration](iterations/2026-09-20-sky-pointer.md). Window-specific synthetic activation, explicit event-construction failures, prebuilt click/drag sequences and provenance-checked Mac coordinate scroll are implemented. Native acceptance awaits restart; existing MCP transport was closed. Sky field zoom/reset passed; sidebar scrolling had no confirmed effect in this trial. Hosted-process target routing and full synthetic focus-state tracking remain gaps, not presumed solved.

## Mac bounds acceptance blocker

[Iteration](iterations/2026-09-20-mac-bounds.md): native session/capture passed, double-click was not sent because the guard cast live CGFloat bounds to [Double]. Unified numeric normalization is installed for restart. Eleven model tests passed; pointer behavior remains unverified by this trial.

## Restarted iPad pointer acceptance

[Native checkpoint](iterations/2026-09-20-ipad-pointer-native.md): installed Mac bounds correction passed. mac_ax double-click zoom, reset click, field pan and foreground sidebar drag scroll are **TESTED** by screenshot inspection; all retained window bounds stayed [130,99,1006,780]. User also observed sidebar movement. Wheel scroll is **FAILED** for visible effect in both tested focus modes. R06 remains scoped/unfinished, R07 now has this Mac native pass but WDA orientation acceptance remains open, and R15 is not certified: early actions omitted foreground:true but actual OS focus was not independently recorded. Workflow verification was not_evaluated; visual checks are separate evidence. Compact sidebar deltas retained57/50 changes while returning12; canvas changes still needed images. iPhone, desktop save/reopen and paired Blender release cases remain open.

## Scroll-effect evidence candidate

**IMPLEMENTED, native RECHECK:** scroll_effect separates scoped coherent AX displacement, bounded visual differences, and unverified effects from dispatch/expectation results. Automatic retained before/after captures, optional observation_region, bounded delayed observations, explicit capture diagnostics, no boundary inference and no automatic retry. offscreen changes are now included in generic deltas. This does not fix wheel delivery or certify scrolling. See [iteration](iterations/2026-09-20-scroll-evidence.md).

## Native scroll-evidence checkpoint

[Iteration](iterations/2026-09-20-scroll-evidence-native.md): **TESTED** scoped negative-case reporting, automatic retained captures, additional observation and nested evidence retrieval on restarted bc78636. Both wheel trials: unverified, boundary unknown, image changedFraction0; explicit foreground did not alter result. Drag visibly scrolled and restored sidebar, with50 observed changes including offscreen. Positive automatic movement detection remains **RECHECK**, not proved by the separate drag action. No wheel delivery fix claimed.

## iPhone comparison and desktop full-page evidence fix

Native on bc78636: iPhone Playbook→Next→Filters passed Leap assertions and Sky semantic actions; Leap foreground drag visibly scrolled filters. Sky coordinate scroll/drag and element scroll raised windowNotFoundAtPosition. Leap wheel/semantic scroll showed no visible effect. Ambiguous Home selector safely rejected (guest and host toolbar share label); first play restored, phone left on Playbook. Desktop sidebar scroll worked with both Sky and Leap. Leap detector falsely returned unverified despite460-point motion and visible change: requiring the same nodes visible before AND after excluded full-page movement. Candidate now accepts target intersection before OR after and scoped directional scrollbar value changes. **RECHECK after restart**, not native pass. [Iteration](iterations/2026-09-20-scroll-page.md).

## Desktop creation repeat and editor metadata correction

Native full-page scroll detection **TESTED** down/up via scoped scrollbar values on0c63b3e. Sky created and reopened SKY ACCEPTANCE 0920 - Slant Flat using2X2 SLOTS,2 Step Slant and Flat route assignments plus player/coaching notes. Leap opened New Play1 but metadata failures in coaching-notes AXTextArea blocked global completeness, even foregrounded. Candidate retains unavailableFields and selectorComplete, permits unrelated role-qualified/ID targeting and preserves unknown for metadata-dependent assertions. **RECHECK after restart**. Desktop Leap creation and paired iPad creation now take priority before Blender; user authorizes leaving all test changes in place.

## Native creation and text capability checkpoint

Desktop create/save/reopen **TESTED**, including named routes and notes on1b7be96. Editor metadata correction **TESTED**. iPad title/routes/player1 note persisted; coaching direct-value write failed persistence despite immediate readback. Raw unsupported value guard **IMPLEMENTED / RECHECK**. Sky normal typing retained notes in duplicate; Sky receiver-coordinate targeting failed even foregrounded. Both Save paths unexpectedly reached Team libraries; **RESEARCH**, not expected behavior. R16 remains PARTIAL, not certified. See [iteration](iterations/2026-09-20-text-capability.md).

## Input delivery evidence

R08/R12: action, resolved target and backend input_result now retained in intent results (**IMPLEMENTED**, restart acceptance pending). Previously backend descriptions were discarded while snapshots/deltas remained stored. Saved SKY IPAD KEYBOARD comparison coaching/title **TESTED**. Screenshot Save eventually returned to playbook;20-second check unknown and user window movement qualifies result. Team libraries cause remains **RESEARCH**. Blank-field set_value refusal still awaits native acceptance. [Iteration](iterations/2026-09-20-input-result.md).

## Live center candidate

Native input_result **TESTED**: Save semantic AXPress confirmed, unexpected Team libraries persists. Pointer full-control midpoint/live frame **IMPLEMENTED**,3 focused tests passed, native restart pending. Simulator multiline raw-value refusal expanded after saved value failed despite settable. Foreground super+a produced accent popup: keyboard **FAILED** for that scoped case, no select-all pass. See [iteration](iterations/2026-09-20-click-center.md).

## Keyboard sequence candidate

Simulator multiline raw-value refusal **TESTED** with unchanged before/after value. Keyboard modifier/down/up/restoration sequence, dispatch timestamps and foreground session tap **IMPLEMENTED**,2 focused tests passed; native restart pending. Sky select-all did not visibly select all either. Center/reveal native case still pending. [Iteration](iterations/2026-09-20-keyboard-sequence.md).

### Consolidated Sky review — 2026-09-20

See [cross-cutting comparison](research/sky-leap-consolidated-review.md). **IMPLEMENTED / native pending:** post-activation key-window and field-focus verification; keyboard modifier/timestamp/tap sequence; multiline append guard; uncertain-write/semantic-action replay prevention; verified UTF16 selection; unknown-key rejection. **RESEARCH:** hosted-process target routing and full background focus state machine. **PENDING:** compact per-step summary when a large workflow response is externalized. **UNRESOLVED:** Save → Team libraries in both tools, iPad persistence acceptance and paired Blender. No parity certification from unit tests.

### Literal-text physical key translation

**FAILED native on cc5e90a:** foreground typing unchanged; background Unicode chunks became aa. Sky text insertion observed working despite observation error. **IMPLEMENTED / RECHECK:** current-layout physical key translation with Unicode payload, whole-plan Simulator unsupported-character rejection, CRLF normalization;11 focused tests passed. Single-key follow-up inconclusive due user Escape input. See [iteration](iterations/2026-09-20-text-key-plan.md). No Save attempt this iteration.

### Foreground acceptance — 2026-09-20

Foreground physical typing/Select All **TESTED scoped** (Foreground42. and visual selection). Longer Read flat defender. became Red flat defender.: **FAILED** exact typing. Save/reopen retained actual Red flat defender.: **TESTED scoped persistence**. Sky comparison also unchanged/unknown. CPU sample does not establish app stall. Whole-text event preparation with frozen restoration state **IMPLEMENTED / RECHECK**. See [iteration](iterations/2026-09-20-foreground-acceptance.md). Foreground accepted as campaign baseline; background parity deferred.

User steering supersedes pending whole-text candidate: **insights-off experiment** installed next. Keyboard patch retained/deferred; no keyboard changes in this build. insights.enabled=false disables automatic subscriptions, post-action observations/deltas, scroll analysis and failure capture. Explicit reads/checks and pre-action validation remain. Test foreground input without expect, then explicitly observe; compare load/outcome before deciding whether insights cause trouble. Existing history preserved.

### Insights-off native result

**TESTED:** session advertises insights disabled; action-only results omit post scans/deltas. Exact Test 79. replacement passed. Appended Read flat. became Red flat.: **FAILED** even with insights off. No CPU causation established. Whole-text preconstruction/frozen modifier restoration now applied as **IMPLEMENTED / RECHECK**,12 focused tests. [Iteration](iterations/2026-09-20-insights-off-native.md).

### App keyboard target correction

Full [controller trace](research/sky-keyboard-controller-trace.md) confirms Sky app text/chords resolve a PID and post to it. Prior inference from global sender was incomplete. Leap foreground app keyboard now process-directed, never .system: **IMPLEMENTED / native RECHECK**. User observed a in ChatGPT on prior build; full-text preparation did not resolve Read→Red. Hosted target/focus state-machine parity remains **RESEARCH**.9 routing/text tests passed.

## Current user direction — 2026-09-20, supersedes prior typing gates

User explicitly stopped Simulator typing tests. Focus on desktop Gameday workflows and Simulator clicks/navigation, then paired Blender. Simulator typing remains unresolved/deferred, not a required next acceptance gate or a certified capability. Insights configuration is restored to true; restart required because the loaded MCP reads configuration at startup. No rebuild needed. See [iteration](iterations/2026-09-20-restore-insights.md). Only iPad booted after relaunch. Latest native session2BC880F8-550E-4ABC-9438-C8E7980152C5: rotation, exact search and opening saved play passed scoped checks; interrupted coaching edit outcome unknown. Fresh observation before any action; no typing replay.
