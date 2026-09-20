# 2026-09-20 — Insights-off comparison and whole-text candidate

## Outcome and evidence

Native5e43e8d session4ECBF6E9-0210-4925-A519-9A168D0C8AEE reports insights_enabled=false. Action results omit automatic after_snapshot/delta, label insights disabled, and preserve not_evaluated. No automatic expectations used.

5DA11D8F-8DD9-4A9E-B844-0B748CEFE6D9: foreground click/Select All/type Read flat defender.; explicit snapshot3562 still Red flat defender. This alone cannot prove a new mutation since prior text was identical. Distinct replacement Test79 case7CC689B9-9DD3-4DD3-A91B-AD2855D9A060 produced exact Test 79. in snapshot3570. Append47C302F2-AB35-4319-A107-27795AE24583 requested “ Read flat.”; snapshot3575 contained “Test 79. Red flat.”. Thus missing-character failure persists without automatic insights. Insights are not the sole cause. No quantitative CPU improvement claim; no matched load study performed.

## Rationale and alternatives

Keep insights disabled and keyboard timing unchanged. Apply previously reviewed deferred whole-text patch from foreground-acceptance. Sky0x10072a660 constructs all text events before posting; Leap sampled global modifier restoration flags between posted characters. Freeze restoration once and prebuild/rout all events before first dispatch. This removes self-observation of in-flight modifiers and partial allocation/routing dispatch. Whether it resolves the repeated missing a is native-unverified. Do not claim every failure was caused by recording, timing or modifiers.

## Changes

Input.textEvents constructs complete array with one restoration snapshot. Input.type routes all events before sending. One regression verifies the same restoration state across shifted/unshifted characters. Existing physical translation, focus logic and8ms event pacing unchanged. No replay, clipboard use, registration changes or historical deletion. Config insights.enabled remains false.

## Validation and delivery

TOOLCHAINS=org.swift.640202609131a swift test --filter 'TextKeyPlanTests|KeyboardSequenceTests|KeysTests':12 tests passed. Build/sign/install metadata under artifacts/test-runs/20260920-whole-text/install.json; logs and rollback local-only. Native results above apply to5e43e8d, not candidate. Source skill updated and synchronized at installation.

## Remaining work

Restart, confirm insights off, explicitly foreground and replace existing notes with Read flat defender., then observe once. Current unsaved text Test 79. Red flat. in LEAP IPAD INPUT0920 - Slant Flat. Do not assume selection/focus survived restart. If exact typing passes, save/reopen and complete clean iPad creation/routes/notes then desktop smoke/Blender. Previous scoped actual-text persistence passed but intended edit still failed. Background parity deferred.

Delivered2026-09-20T17:16:28Z, SHA256 `6dac1f070ce6f29193e6882ae591c7f84053007febff2f3922e8e468eb64963e`. Signed app verified, skills-only sync and source/installed comparison passed. Name leap unchanged. Restart/native candidate verification pending.
