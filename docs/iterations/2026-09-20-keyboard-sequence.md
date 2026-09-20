# 2026-09-20 — Reference keyboard sequence

## Outcome and evidence

Restarted ea0b244. SessionD561950C-B41D-452B-BBA2-D7D4D8105CFF. Sky Escape dismissed prior accent popup. Sky super+a alone and after click on coaching field did not visually select all; final screenshot showed athrow selected with suggestions. No Sky keyboard success inferred. Native Leap set_value26A14770-8F14-46AA-8668-94ED04618794 refused Simulator multiline raw write. Before2912/after2916 values identical: Halftime: read the flat defender; athrow the slant if he widens. Guard scoped pass; dispatch conservatively uncertain due wrapper entry/possible selection path. No value mutation in retained snapshots. Current note includes earlier unintended a; do not count as intended text.

## Rationale and alternatives

Exact Sky factory0x10071b150 plus disassembly0x10071b2e4/0x10071b424 proves flagsChanged events around keyDown/up. Sender refreshes event timestamps and posts foreground events to session tap1. Leap used only down/up flags and HID tap0. Implement those supported differences rather than vary arbitrary delays or guess virtual devices. Native Sky select-all remains imperfect, so candidate is not proof of Simulator fix. Source references local-only under /Users/ryan/src/sky; audit retains addresses.

## Changes

Input.keyboardSequence prebuilds flagsChanged/down/up/restoration using HID-state source and prior combined-session flags. Both chords and Unicode chunks use it. Complete per-sequence allocation/routing precedes send. Input.post/sendPrepared refresh timestamps at dispatch. Foreground keyboard uses session tap, pointers retain existing tap/targeting. Background stays PID-directed. Two focused tests check event order, keycode/modifier restoration, and UTF16 surrogate pairs on down/up. Skills updated. No database reset, new backend, focus guessing or automatic retry.

## Validation and delivery

TOOLCHAINS=org.swift.640202609131a swift test --filter KeyboardSequenceTests:2 tests passed,0 failures. Toolchain duplicate Objective-C warnings remain, exit0. TOOLCHAINS=org.swift.640202609131a python3 scripts/bundle.py; identity in artifacts/test-runs/20260920-keyboard-sequence/install.json. Logs/backups/runtime store local-only. Installed skills synchronized. New sequence requires native restart testing; harness is not app acceptance.

## Remaining work

Current iPad LEAP IPAD INPUT0920 - Slant Flat editor, coaching notes contain athrow; suggestion/selection may remain. Fresh observation first. Verify chord/normal typing and save/reopen with distinct trial text through restarted Leap, compare with Sky. Do not repeat failing inputs blindly. Full-control center/reveal native acceptance still pending; guard passed scoped refusal. Save→Team libraries remains unexplained semantic behavior. iPad player2 persistence/clean creation, Blender and remaining gates unfinished.

## Dated addendum — consolidated review at user request

Before installation the user requested a broader Sky comparison instead of another isolated patch. Expanded the increment and wrote research/sky-leap-consolidated-review.md with twelve interaction/evidence areas. Confirmed code defects beyond the keyboard factory: focus checked before activation or ignored; Simulator multiline append bypassed the replacement guard; ambiguous direct-write/semantic failures could synthesize a second action; menu opening retried on a single negative observation; unknown key names became literal text. These are code findings, not causal proof for Save → Team libraries.

Implemented shared key-window preparation inside withInput after activation; held batches revalidate foreground. Element-directed keystrokes require live focused attribute or focusedUIElement identity within a bounded 200ms check. No speculative coordinate focus fallback. Multiline append bypass removed, uncertain writes stop, numeric controls cannot fall through to text replacement. Semantic menu/confirm/cancel errors stop except explicit unsupported; menu re-press removed. Select All checks actual UTF16 range; cut/paste reuse checked selected-text insertion. Unknown multi-character keys reject. Unicode batching avoids splitting high/low surrogate pairs.

Seven focused keyboard/parser tests pass; git diff --check clean. Engine/AX focus and mutation changes compiled but remain native-unverified. Earlier delivery paragraph described the intended handoff prematurely: at addendum time no candidate had been installed. Final install metadata is authoritative. No session data deletion. Supported improvements grouped in one install; full Sky hosted routing/focus state machine still research, not claimed solved. Next acceptance is existing iPad editor focus/chord/type/save/reopen, followed by desktop smoke and remaining iPad/Blender gates.

Final delivery: build/sign/install completed 2026-09-20T16:48:36Z. Binary SHA256 `609129f3a0774ead7f85774e6851a647ee378e8967c5c9f90d2ad63bbdc9b2c4`. Registration leap unchanged. Skills-only installer succeeded and source/Claude/Codex claude-leap trees match. Rollback local-only artifacts/backups/20260920-keyboard-sequence/previous.app. Install script and small identity JSON retained. Loaded MCP has not restarted onto this candidate; native claims remain pending.
