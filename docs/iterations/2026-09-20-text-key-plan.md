# 2026-09-20 — Translate literal text into physical keys

## Outcome and evidence

Native restarted cc5e90a, session E7603DF9-B63B-4332-9FA5-86F71CCAA8BE. Foreground targeted type_text “ LEAP focus trial.” returned dispatched, assertion failed with unchanged notes (A07693F8-B599-4D9A-8854-7D7036EB0E1E, snapshots2946/2959). Sky click39/typeText “ SKY focus trial.” followed by observation raised noWindowsAvailable, but fresh Sky state/screenshot proved text became “ SKY focus trial.”. Leap background targeted type_text “ LEAP background trial.” produced “ SKY focus trial.aa” (1F58D36B-08B1-4965-9745-6DE96B41B3C7, snapshots2987/2996). Both failures were correctly retained with deltas and failed assertions. No save attempted.

User screenshot confirmed aa and reported repeatedly pressing Escape while collecting it. Later Leap single-key b produced no change (37EC6D0F-8B95-4F35-9651-AD2182C40234); concurrent Escape makes that comparison inconclusive. User reported another edit screen appearing; no deliberate open-editor action was issued this turn, and the supplied screenshot shows the existing play editor. Cause of that reported transient remains unknown.

## Rationale and alternatives

Reference part-0026.c0x10072a4a4/0x10072a5a0 calls SAIVirtualKeyPress.keyPressesForString, then0x10072a660 passes each to factory0x10071b150. Factory reads keyCode, modifiers and optional string. Leap used keycode0 for each20-unit Unicode chunk. Two physical A characters for two chunks strongly supports Simulator ignoring Unicode payload and forwarding physical codes. This is distinct from click coordinate geometry. Prior modifier-event fix alone was insufficient.

Use public Carbon current-layout translation to produce matching physical keys and Unicode payloads, rather than introduce an unverified private SAIVirtualKeyPress dependency or hardcode US keycodes for literal text. Preflight all characters; Simulator rejects unsupported single-stroke characters before any text events. Other apps keep explicit Unicode representation for characters without physical mapping. This is a supported subset, not full IME/dead-key parity. Current layout may still differ from guest layout; native outcome checks remain necessary. Foreground delivery/focus and Save behavior remain separate uncertainties.

## Changes

TextKeyPlan reads current Unicode keyboard layout and enumerates unmodified/Shift/Option/Shift+Option translations; Input.type uses per-character physical code/modifiers and complete keyboard sequences. CRLF maps to one Return. Simulator engine typing requires physical mapping. No retry, clipboard mutation or automatic raw-value write. Source skill documents limitation.

## Validation and delivery

TOOLCHAINS=org.swift.640202609131a swift test --filter 'TextKeyPlanTests|KeyboardSequenceTests|KeysTests':11 tests passed. Four new tests cover physical codes/case/control characters, whole-plan unsupported rejection, intact Unicode fallback and read-only current layout discovery. No events injected by tests. Build/install identity recorded in artifacts/test-runs/20260920-text-key-plan/install.json; tests/build logs and rollback app are local-only. The aa failure screenshot is curated at artifacts/test-runs/20260920-text-key-plan/incorrect-aa.png. Remaining raw screenshots stay local-only in .leap; tracked evidence IDs and user observation above preserve the finding.

## Remaining work

Restart then observe fresh. Existing iPad editor LEAP IPAD INPUT0920 - Slant Flat has SKY focus trial.aa, not intended final notes. User Escape changed state, so do not reuse old focus/geometry. Test normal Leap input, inspect actual effect, correct note deliberately, save/reopen. Compare Sky if failing. Desktop shared-transport smoke, clean iPad/player2 persistence and paired Blender remain open. No native pass claimed for new mapping. Keep broad grouped review direction; do not infer this solves every keyboard/focus issue.

Final delivery: installed at2026-09-20T16:54:54Z, SHA256 `54d19e957f4716cafbe2444464c19685fe10a5574f373aff2e82496e7ff79785`. Signed bundle verified. Skills-only sync and source/installed comparisons passed. Registration unchanged. Native candidate not yet loaded/tested; requires session restart.
