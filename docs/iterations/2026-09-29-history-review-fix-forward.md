# 2026-09-29 — History review: what the keyboard chase cost, and fix-forward

## Outcome and evidence

User request: review the git history for capabilities regressed or abandoned while chasing the
missing/extra `a` (09-20), and fix forward whatever should have been kept. The user recalled that
Sky shows the same typing glitch and that the `a` was resolved in the 09-28 commits.

What the history shows (evidence from `git show`, iteration entries):

1. **The `a` had two Leap-side causes, both now fixed.**
   - Before 0c95fdf, `Input.type` sent literal text as Unicode-payload keyboard events with
     keycode 0, which is `kVK_ANSI_A`. Cocoa apps read the payload; the Simulator reads the keycode,
     so text became `a`s ("background Unicode chunks became aa", text-key-plan entry). 0c95fdf
     replaced this with current-layout physical keys (TextKeyPlan). Kept.
   - The 09-20 modifier-sequence work built `flagsChanged` events with keycode 0 too: phantom `A`
     events around every modifier. Fixed in be4609c (09-28), with a unit test that modifier events
     never carry keycode 0.
   - The 09-20 foreground/background switching, insights-off experiment, whole-text preparation
     and repeated Simulator typing trials did not address either cause (insights-off native entry:
     "insights off did not eliminate failure").
2. **Keep (evidence-based, not white-rabbit):** hidden-layer pruning removal (09-19 zoom defect
   L1: it hid live controls; trial-leap.details.md), Simulator multiline value-write refusal
   (readback matched while the saved binding stayed unchanged), process-directed keyboard
   delivery, TextKeyPlan, resolve-before-press, the v2 intent API and evidence store.
3. **Regressions found by replaying the 09-18/19 scenarios (`Tests/*.json`)**, which had not been
   run since 09-19. Installed b00a8f4, background, Gameday desktop:
   - Behavior intact: index-stability, background-keys (`TEMPO`, then `TEMPO X` with Gameday in the
     background), label-targeting, select-text, relaunch-guard, batch partial failure.
   - Agent guidance regressed: fc00639 (09-20 intent rebuild) replaced the Sky-style SKILL.md
     playbook (loop, tree grammar, text entry, errors, habits, confirmation policy) with a v2-only
     page, calling the interactive tools "legacy"; the server instructions lost the loop and the
     confirmation policy. `intent-workflows.md` accumulated about 45 lines of dated 09-20 campaign
     notes that agents load at task time. Several references still said keyboard fallback may use
     system events, which the code never does (Delivery.system is never constructed).
   - Response noise: every error carried a diagnostics trailer restating the error three times
     (`input_error`, `tool_error`, `tool_completed`), and `input_error` claimed "Dispatch may have
     occurred" even for an ambiguous label or a read-only `wait_for`, where nothing is sent.
     Synthesized key/text/wheel actions carried a route trailer duplicating the result line. Every
     state carried "Optional metadata unavailable: N reads…" although advisory failures do not
     affect actions.
   - Tree bloat: after visiting Gameday's Formations tab, SwiftUI keeps that page alive as about
     220 disabled nodes. 49a3213 collapses such runs, but only for recorded (project-bound)
     sessions, so plain `get_app_state` rendered all of them.
   - Scenario drift only: wait_for wording changed; relaunch flag now appears in the error's fresh
     evidence; `click(label:"Formations")` is correctly refused as ambiguous (Button vs RadioButton
     in the current Gameday build).
   - Simulator scenarios (ios-type-text, menu-bar, simulator-offscreen-press, share-indicator)
     could not run: after the macOS 27 / Xcode upgrade, `Xcode.app/Contents/Developer/Applications/
     Simulator.app` is absent and LaunchServices cannot resolve `com.apple.iphonesimulator`
     (runtimes installed, iPhone 16 booted headless). Environment, not a Leap result.

## Sky reference and rationale

- Guidance: Sky's plugin SKILL.md teaches the primitive loop, re-derive indices, prefer diffs, and
  a full confirmation policy (SKY-BEHAVIOR §10). Follow Sky: the interactive loop is the primary
  path again; v2 `ui_perform` is presented as the verified-workflow layer, which Sky lacks.
- Errors: Sky returns one message per failure (§7), no trailer. Leap keeps its durable diagnostics
  store (better audit than Sky) but stops repeating the returned error/route in the response.
  Novel warnings (capture failures, fallbacks) still appear.
- Inactive views: Sky renders them (and prunes empty disabled elements); occlusion inference is
  unreliable (SwiftUI hit-tests hidden layers). Leap's collapse of runs of 5+ disabled lines keeps
  lone disabled controls visible and is lossless on request; applying it to every reader is better
  than Sky's full dump without the 09-18 pruning's false negatives.

## Changes

- Diagnostics: `echoKinds` (tool_error, tool_completed, input_error, check_unmet, keyboard_route,
  text_keyboard_route, scroll_pointer_route) persist but are excluded from the response trailer.
  `input_error` no longer asserts dispatch; `wait_for` failures record `check_unmet` ("read-only
  check; no input sent").
- Rendered state drops the advisory-metadata line (retained in snapshot and v2 metadata).
- `Engine.collapseDisabledRuns` applies to every rendered state; the 10 KB cap stays
  recording-only. New `get_app_state include_disabled=true` lists runs in full.
- Server instructions: interactive loop, verified workflows, background rule, uncertain-input rule,
  safety policy. `foreground` description corrected (keys never system-wide).
- Skill: SKILL.md restored as the Sky-style playbook plus a v2 section and confirmation policy;
  intent-workflows.md rewritten to current behavior (campaign history removed; it lives here and
  in earlier entries); ui-details.md and legacy-workflows.md stale keyboard/wording fixed.
- Scenarios: expectations updated (wait_for wording, relaunch flag, ambiguous label, live-line
  `@absent` patterns, relaunch-guard returns to Playbook so runs are order-independent).
  `scripts/run-legacy-scenarios.sh` + `make scenarios [SET=simulator]`.

## Validation and delivery

- `make test`: 67 tests, 0 failures (new: echo suppression, unrecorded collapse idempotence).
- `make scenarios` on the signed dist bundle: 7/7 desktop scenarios pass (harness, background,
  Gameday). Before the fix on b00a8f4: 4/6 plus drift failures; 17 trailers and 23 metadata lines
  across the run, after: 0 metadata lines, route/error echoes gone.
- Same Gameday window, full read: 23,692 bytes / 296 element lines with `include_disabled=true`
  versus 5,449 bytes / 77 lines by default.
- Logs: `artifacts/test-runs/20260929-legacy-replay/` (local-only, ignored `*.log`).
- Harness evidence only. Native MCP acceptance needs the restarted session.

## Remaining work

- After restart (native): `get_app_state` Gameday after visiting Formations shows one collapsed
  line; an ambiguous-label click error has no trailer; skill loads with the loop as primary.
- Restore Simulator.app (Xcode › Settings › Components or `xcodebuild -runFirstLaunch`), then
  `make scenarios SET=simulator`.
- Open from the parity review: user-interaction detection (Sky `userIntervened`), v2 steps for
  select_text/perform_action/paste, per-app deny list and user stop key.

Installed 2026-09-29T23:58:15Z via `make install` from the commit containing this entry. Binary SHA256
`af03489d38a2b7147d51d4f2b02f90589b648027931f88eb49ce94bdde5c771b`. Signature verified; source and
installed claude-leap skill trees match (Claude and Codex); registration `leap` unchanged. Loaded MCP
not yet restarted onto this build; native checks pending. Tracked replay summary:
`artifacts/test-runs/20260929-legacy-replay/summary.json`.
