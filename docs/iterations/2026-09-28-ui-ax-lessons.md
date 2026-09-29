# 2026-09-28 — Combining methods: resolve-before-press, raw AX results, quick waits, ui_inspect

## Outcome and evidence

Input: docs/followup/2026-09-28-gameday-ui-ax-comparison.md. Rationale and method mapping:
docs/research/ui-ax-lessons.md.

Harness (dev build, background AX, separate project):
- Suggested experiment: Playbook selector → `{"role":"AXButton","label":"New playbook"}` opened the New
  playbook alert (`passed`, whole flow 3.2 s) with resolve-before-press; the alert's "Name" field is labelled
  from its placeholder.
- `ui_inspect` returned raw attributes (positions showed Cancel left of Save in that alert: not swapped).
- Background Escape did not dismiss the SwiftUI alert within 6 s (`failed`, honest); the alert was gone
  on the next read. Gameday had been relaunched and its play count moved 179 → 180 without any save by this
  session, so the other agent was likely active; further Gameday driving was stopped. Playbooks stayed 2.

## Sky reference

Sky validates element ids before acting ("The element ID is no longer valid") and runs prepareToInteract
right before pressing; its timeouts "had already applied" (SKY-BEHAVIOR §5); it has no raw-attribute view.

## Changes

- automationQuickRead: plain window walk (no settle/render/record) shared by waits and pre-press resolution.
- Selector actions re-resolve the target from a quick read immediately before input and use that fresh
  element; if the target is absent, no input is sent.
- AXPress `cannotComplete` returns an uncertain acknowledgement (not an error): `ax_result`,
  `dispatch: uncertain`, `side_effect_note`; the expectation decides; no re-press.
- Waits/expectations poll quick reads every 250 ms and take one full observation at the end.
- New read-only tool `ui_inspect(session_id, selector, limit)`: raw attributes, actions, parents.

## Validation and delivery

`swift test`: 64 tests, 0 failures. Install identity below; native verification by the other agent pending.

Installed 2026-09-29T00:00:59Z via `make install` from 4cc6be4. SHA256 `c372c60523285339882242e79abbebbd3e720556be49dea3798ffd0d791b5663`. Signature verified; skills match; registration unchanged. Restart pending.
