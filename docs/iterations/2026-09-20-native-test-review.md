# 2026-09-20 — Native testing architecture review

## Outcome and evidence

User requested research and comparison of seven externally supplied proposals with Leap. Reviewed their architecture, result/device schemas, tool surface, workflow and assertion semantics against current code and Apple, Appium, Playwright and MCP primary documentation. [Report](../research/native-test-stack-review.md) retains the comparison and references. No native app actions occurred.

## Rationale and alternatives

Simulator host AX geometry remains invalid even after verified foregrounding; screenshot-coordinate actions worked in both controllers. Device-native XCTest through WebDriverAgent is a missed alternative worth a bounded experiment, not a demonstrated fix. Prefer evaluating an existing bridge over immediately maintaining a custom test runner; preserve Mac AX for desktop/canvas operation. Reject wholesale schema copying because retryable workflows, binary assertions and causal delta wording would weaken existing uncertainty protections.

## Changes

Added research report, explicit backend/selector/capability/regression checklist gaps, current plan and handoff. No runtime/tool or skill behavior changed. No source/installed skill synchronization needed for this documentation-only review.

## Validation and delivery

Read source at baseline c68cb3d, inspected proposed TypeScript schemas, verified primary documentation including Apple markdown representations. Documentation links and git diff checked. No code tests, build, install, new binary identity or native pass claimed. Prior activation install metadata remains artifacts/test-runs/20260920-activation/install.json; no restart since that install has been confirmed in this research turn. Commit/push documentation checkpoint.

## Remaining work

Verify public activate from background after restart. Evaluate the same iPad/iPhone toggle, query geometry, rotation and drag via a device-native backend, preserving fixtures and recording startup/latency/focus behavior. Then choose based on evidence; continue existing Gameday/Blender objective without expanding into unrelated platform support.
