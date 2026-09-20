# Native testing stack versus Leap

Research checkpoint: 2026-09-20; source baseline c68cb3d. Evaluation of all seven user-provided proposals (Apple stack, architecture, result schema, device results, tool surface, ui.perform, assertion semantics). These are design suggestions, not evidence of installed capabilities. No native actions or backend installations occurred in this review.

## Conclusion

Adopt the architecture selectively. Leap already implements much of the proposed observation, history, compact-query and action-evidence layer. The most consequential missed alternative is a device-native XCTest backend for Simulator apps, instead of depending entirely on the macOS accessibility representation of the Simulator window. Pilot an existing bridge before building a custom runner. Keep the native Mac backend for Gameday desktop, Blender and general desktop operation.

This is a hypothesis to test, not a demonstrated fix. The last paired experiment showed both Sky and Leap can click the correct iPad control using screenshot coordinates. Explicit foregrounding did not repair the control's invalid AX rectangle. Neither that experiment nor the extracted Sky reference establishes Sky's internal coordinate conversion algorithm. See [activation evidence](../iterations/2026-09-20-activation.md).

## What the external mechanisms actually supply

Apple's [XCUIAutomation](https://developer.apple.com/documentation/xcuiautomation) provides application proxies, element queries, element snapshots, screenshots, gestures and device simulation. XCTest supplies the test framework. This is the native UI testing family corresponding to the user's Playwright comparison; Leap's Swift unit tests are not themselves XCUITest app tests.

There is an existing remote-control implementation: [Appium WebDriverAgent](https://github.com/appium/WebDriverAgent) runs an XCTest runner and exposes commands for app lifecycle, element inspection and input on devices/simulators. Appium's XCUITest driver supplies surrounding integration. Evaluate that maintained bridge first; do not assume importing XCUIAutomation into the existing ordinary MCP executable creates a working test runner. The added runner, startup, dependencies and compatibility are real costs. [Driver requirements](https://appium.github.io/appium-xcuitest-driver/latest/getting-started/system-requirements/) must be checked against local Xcode/runtime versions before a pilot. Physical-device provisioning is additional scope, not required to resolve the current iPad case.

Apple's [XCUICoordinate](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate) is relative to an element and dynamically resolves its screen position. This is useful but does not make coordinates universally interchangeable. Host screen points, Simulator window points, device points and screenshot pixels need explicit provenance. Apple's [isHittable](https://developer.apple.com/documentation/xcuiautomation/xcuielement/ishittable) also distinguishes existence from current hit availability; an offscreen element may become hittable through a scrolling interaction. A blanket precondition of current hittability would prevent some valid reveal-and-act operations.

[Playwright actionability](https://playwright.dev/docs/actionability) checks the conditions appropriate to each action and retries observations/assertions. Its lesson is unique resolution plus readiness plus bounded verification, not a fixed sleep after every click. Mac semantic AXPress can work without a pointer hit, so Leap must use action-specific requirements rather than blindly import browser pointer rules.

simctl/devicectl belong in device discovery/lifecycle adapters, not as substitutes for a semantic UI query engine. App-specific scripting/Apple Events can be a high-level backend when supported; that does not establish UI acceptance for a bypassed operation. For Blender custom canvases, screenshots and pointer/keyboard interaction remain essential to the agreed benchmark.

The proposal's [2026-07-28 MCP announcement](https://blog.modelcontextprotocol.io/posts/2026-07-28/) is real and describes a stateless protocol core. This does not prohibit durable application-level Leap sessions. The pasted MCPResult schema is a proposed tool payload, not a mandatory MCP result schema. Host/SDK compatibility must be checked separately before protocol migration; this review makes no transport change.

## Implementation comparison

| Proposed capability | Leap today | Remaining gap |
|---|---|---|
| Semantic tree, attributes, available actions | AXTree/AppSession capture Mac AX nodes; get_app_state and ui_to_text expose them | Device-native representation; reliable source-space geometry; canvas internals remain unavailable |
| Structured filtering and bounded responses | ui_to_text supports types, IDs, fields, text, state, subtree/depth and pagination | Unified reusable action/query selector; relationship predicates; full-envelope budget auditing |
| Sessions and historical evidence | Project-bound SQLite, app capture epochs, named cross-app groups, interaction IDs, retained snapshots and notification envelopes | Sessions are not OS isolation; notification coverage is partial; durable device/window identity |
| Deltas and drill-down | ui_diff, interaction_delta, timeline, interaction_result, recording_review | Noisy identity churn; consistent results for batches/errors; absence under partial capture stays uncertain |
| Large-content artifacts | leap_asset retrieves/chunks/materializes retained text | General image/video/log artifact registry and automatic linked failure bundles |
| Semantic actions and coordinate fallback | AX actions, targeted pointer/keyboard routes, window/staleness guards, reveal attempts, explicit diagnostics | Backend capability policy; validated Simulator transforms; gesture coverage beyond current actions |
| Waits and verification | Bounded current-state wait_for; verified_action sends one input, records pre/post checks | Gating preconditions; richer exact/count/compound assertions; temporal checks armed before dispatch |
| Compound operations | batch runs up to 50 same-app actions/waits and stops on first error | Typed mixed workflows, per-step IDs/verdicts, variables, explicit skipped steps and overall verification result |
| Typed results/errors | Journal distinguishes inputs, checks and capture; ambiguity retained without replay | Uniform agent-facing execution/acknowledgement/verification contract; generic read-only error wording is misleading |
| Device/app lifecycle | Mac app discovery/activation and current Simulator-window control | Stable device target, backend readiness, guest-app lifecycle, deterministic fixtures |
| Test export and CI | Repo tests, curated native trial reports and install metadata | Portable replay scenarios, environment manifest, fixture setup/cleanup, assertions and machine-readable run reports |
| Capability discovery | Tool schemas and node AX actions | Runtime target/backend/operation capabilities, unavailable reasons, tested versus merely supported distinction |

Source anchors: [Tools.swift](../../Sources/claude-leap/Tools.swift), [Engine.swift](../../Sources/LeapCore/Engine.swift), [AXTree.swift](../../Sources/LeapCore/AXTree.swift), [AppSession.swift](../../Sources/LeapCore/AppSession.swift), [Evidence.swift](../../Sources/LeapCore/Evidence.swift), [Recording.swift](../../Sources/LeapCore/Recording.swift), [Diagnostics.swift](../../Sources/LeapCore/Diagnostics.swift), [Package.swift](../../Package.swift). Existing native coverage remains scoped in FEATURES; this table is not certification.

## Changes needed in the proposed design

1. Separate dispatch (`not_sent/sent/uncertain`), API acknowledgement and verification (`passed/failed/unknown/not_evaluated`). A completed assertion can be false; inaccessible evidence makes it unknown. A false assertion alone does not identify an app bug rather than a bad expectation or fixture.
2. Replace blanket retryable with specific recovery guidance: refresh observation, retry a read, or explicitly establish safe action replay. A post-action timeout never automatically authorizes replay of the click or whole workflow. Failed read-only tools should not imply input occurred.
3. Name deltas as observed changes, not changes caused by the operation. User input, timers and background activity can also change the UI.
4. Treat state versions as observation versions. expected_state_version detects a known stale baseline; it is not an atomic lock against app animation or human input between validation and dispatch. Revalidate target identity, geometry and readiness immediately before input.
5. Keep completeness, capture intervals, coverage gaps and retrieval truncation separate. A snapshot is not necessarily an atomic app-wide state; AX event envelopes are not a complete event-sourced history.
6. Preserve raw backend role/action names alongside normalized values. Unknown attributes and unsupported capabilities must not become false. Current frame intersection is not occlusion-aware visibility.
7. Server-enforced workflow limits override caller-supplied limits. Default stop on failure/unknown; diagnostic continuation must not allow dependent writes after an unmet prerequisite. Do not build a general scripting language.
8. Session names do not isolate input. Serialize operations on a shared target, report ownership/conflicts, and invalidate/recheck after operator intervention. A new backend does not automatically guarantee background parity or independence from the user's pointer.

## Recommended order and acceptance

**First: target and outcome contract.** Add an internal target descriptor (backend, device UDID when relevant, guest app identity, process/window epoch) and coordinate descriptor (source snapshot, units, space, orientation, scale/crop/offset, validity). Preserve existing tools through adapters. Standardize outcomes and recovery without losing existing no-replay protections. Verify stale/ambiguous selection, invalid geometry, completed effects after API errors, and observation failure.

**Second: a narrow Simulator backend experiment.** Use Appium XCUITest/WebDriverAgent on the existing iPad/iPhone app. Compare query contents, element rectangles, semantic toggle, screenshot-relative tap, rotation and drag with the existing Sky baseline and Mac AX route. Measure startup/steady-state latency, focus/cursor effects, tree quality and failure evidence. Use a non-destructive app attachment policy and preserve user data. Keep installation/downloads/logs in repo-local ignored artifacts with a tracked summary. Only select it as the preferred device route if it demonstrates a benefit. No silent switch after possibly dispatched input. A custom XCTest runner is an alternative only if measured bridge constraints justify maintaining one.

**Third: shared selectors, actionability and assertions.** One selector model for querying, actions and checks: identifier, role, label, scope and uniqueness. Re-resolve at execution time; old handles remain snapshot-scoped. Reveal when supported, then reassess. Add exact values, counts and composite conditions; implement temporal predicates against actual covered evidence. Preserve unknown for incomplete acquisition.

**Fourth: bounded workflow and failure evidence.** Evolve batch/verified_action into one internal executor with action/wait/assert/observe/capture steps. Retain each step and its input/check result; return compact deltas and evidence references. Automatically capture the best available tree, screenshot and diagnostic slice on failure, recording capture failures separately. Keep existing convenience tools as wrappers, avoiding a disruptive rename or a huge redundant tool surface.

**Fifth: reusable regression scenarios.** Export reviewed selectors and expectations, not brittle recorded indices or blind coordinate replay. Parameterize environment/fixtures and sensitive inputs; record app/device/backend versions. Add setup, independent checks, teardown, artifact manifests and CI-readable results. Prove Save/reopen and the agreed paired Blender artifact campaign; do not postpone Blender until all device-management possibilities are implemented.

Physical devices, Android/Windows/browser expansion, full environment control and leap-cli remain deferred. Reuse this contract when justified, but do not let the broad proposal replace the current acceptance objective.

## Immediate next checkpoint

No binary changed during this review. The prior activation candidate is still awaiting explicit restart/native acceptance. First verify public activate from a background Simulator and re-observe geometry; do not expect foreground to fix the known bad rectangle. Then perform the narrow device-backend feasibility investigation before choosing between a validated coordinate correction and an alternate Simulator route. The database/insight work remains valuable under either backend.
