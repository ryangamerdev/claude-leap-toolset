# 2026-09-20 — Reference review after user challenge

## Outcome and evidence

User challenged incremental diagnostics instead of tracing Sky. Inspected full native decompilation: click0x100071618/continuation0x10007172c in part-0001.c, focus0x100796058 in part-0027.c. Exact findings added to docs/research/sky-native-input-audit.md. No native interaction or binary changes in this review.

## Rationale and alternatives

Prior work corrected isolated symptoms but left previously known target preparation, verified focus and hosted-process routing unfinished. Reference is useful; its index AX-only conclusion is contradicted by native synthesized-click calls and runtime feature flag. Do not copy that conclusion or infer active flags. Actual Save cause remains unproven, with failures from both tools. Prioritize tracing active delivery rather than another generic patch.

## Changes

Audit records target preparation, uncached focus verification and force-synthesis flag with addresses; plan/handoff direct next restarted test to compare active route, not assume missing database. No source behavior or skills changed.

## Validation and delivery

Read-only source/decompilation comparison. References under /Users/ryan/src/sky are local-only. No build/install necessary. Previously installed93eefa2 still awaits session restart for native input_result acceptance; its install identity remains authoritative. Documentation committed/pushed.

## Remaining work

Restart pending candidate, inspect actual Save delivery/target and compare with relevant reference branch. Unsaved LEAP IPAD INPUT0920 draft remains. Investigate relevant focus/host routing before claiming cause. Complete iPad then paired Blender gates.
