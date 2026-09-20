# 2026-09-20 — Foreground acceptance and whole-text preparation

## Outcome and evidence

On restarted0c95fdf, session AAF160DD-3D92-48D8-A093-D248FA69C1D6: foreground Foreground42. eventually arrived exactly (snapshot3269), while initial assertion was unknown. Cmd+A visually selected the entire note (6B880228-BE13-4246-8AA2-C8A40B1592D2). Subsequent longer replacement was interrupted by user switching focus; current text became Hlft. No clean native claim for interrupted input.

Resumed trial79B43824-AE39-4190-80A9-CC68FF3DF437 requested Read flat defender. with foreground input and20s assertion. Actual Red flat defender. persisted through the deadline: typing FAIL, not mere timing. Sky Cmd+A/typeText and explicit click39/Cmd+A/typeText comparisons returned unknown; fresh state showed unchanged Red flat defender. This comparison is not a Sky-pass/Leap-fail case.

Coordinate foreground Save at919,145 from screenshot3487 (5D2EE303-3C58-4F18-9841-189EF81A3E53) returned unknown after20s AX timeouts, then later snapshot3523 showed playbook. No Team libraries observed in this trial. Edit play AXPress D2BCAA4A-30ED-4F2C-BABF-E30E6D77334F reopened editor; snapshot3542 retained Red flat defender. exactly. Scoped persistence PASS for actual entered text, not full intended-edit acceptance. Title LEAP IPAD INPUT0920 - Slant Flat.

CPU snapshot showed GamedayiOS at100%, but subsequent3-second sample showed main/event threads waiting in runloops. This does NOT prove an app main-thread stall or explain the timeouts. Sample and raw evidence are local-only under artifacts/test-runs/20260920-foreground-acceptance and .leap. Both tools have intermittent Simulator problems; do not attribute all failures to Leap or all failures to app load.

## Rationale and alternatives

User accepts foreground operation and requests rapid end-to-end parity. Defer background parity and optional feature expansion. Continue existing installed workflow before patches, as done above. Reference0x10072a660 constructs the entire text array using0x10071b150 before sender0x10072abe4 dispatches it. Leap instead constructed each character after posting prior events, and sampled combined-session flags each time. That can sample its own in-flight modifiers. Fix this supported construction difference rather than invent an event delay or claim CPU load caused missing letters. Whether this caused this particular dropped character remains a hypothesis.

## Changes

Input.textEvents prebuilds the entire event array with one captured restoration state before routing/sending any event. Allocation/routing failure cannot send a partial prefix. Adds whole-sequence restoration regression. No timing changes, automatic replay, clipboard substitution, registration changes or history deletion.

## Validation and delivery

Focused keyboard/parser/text-plan tests compile and run; final count and install identity recorded below/in install.json. Native data above belongs to0c95fdf, not this candidate. Build logs/sample/rollback remain local-only. Source skill updated and installed copies synced during delivery.

## Remaining work

Restart then observe fresh existing iPad editor. Correct note using foreground selection/type and exact assertion; save/reopen. Persistence alone already passed for actual text, typing remains failed. Then clean iPad create/routes/player notes and desktop transport smoke, paired Blender. Do not repeatedly compare the same failing Sky action without new evidence. Full foreground parity not yet certified.

## User-directed controlled experiment — insights off (supersedes candidate above)

Before installation user asked whether automatic insights cause CPU/read problems and requested config off plus build/install. To isolate this variable, removed uninstalled Input/text-test changes, retaining exact deferred-text-events.patch in tracked artifacts. The installed keyboard remains0c95fdf behavior. Earlier whole-text paragraph describes a researched candidate, NOT this delivered binary.

Added strict boolean insights.enabled (default true) to existing startup config parsing. False disables automatic AXRecording subscription setup and explicit recording start, thus legacy duplicate snapshots; disables implicit post-action observations/deltas, automatic scroll captures/analysis/additional sampling and failure observations/captures. Explicit observe/capture/expect still work. Fresh pre-action scans remain necessary for selector/provenance safety. Intent snapshots/history and diagnostic logging remain. No claim all tree reads or all database writes are disabled. Results label missing post-action insights explicitly, never report an unchanged delta or stale after_snapshot as fresh.

Set user config insights.enabled=false, preserved logging and a repo-local backup config-before.json. Startup restart required. Added configuration default/false/invalid-number test. Four DiagnosticsTests passed; no native off-mode result yet. Build/install and skills identity in install.json. Next native trial uses foreground action without expect, explicit later observation, no automatic polling. Compare against observed baseline; CPU observation alone does not prove causation.

Final delivered build:2026-09-20T17:12:51Z, SHA256 `b315975890dfc5cd0b704c7179c6aa5abacdf86d31b1907d3b6ee4214c63c49f`. App signature verified, skills-only sync and installed/source comparisons passed. Config off; loaded MCP still old until restart. No history deleted. Keyboard unchanged in delivered source. Four DiagnosticsTests passed. Native insights-off trial pending.
