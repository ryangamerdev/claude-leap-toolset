# 2026-09-20 — Landscape-only Gameday native checkpoint

## Outcome and evidence

After user restart, installed build `6df9b4060129ea9fb5f49758bc2114ef24f454e4582570436298514366f1d7a9` passed coordinate provenance dispatch and two guest navigation workflows through native MCP. User clarified Gameday intentionally does not support portrait. Treat portrait refusal as expected app scope, not a Leap regression.

Session `3ADD85CE-E190-4536-BA94-D9E99F4865AA`, iPad guest local.gameday.ios, WDA endpoint localhost:8100:

| Interaction | Case | Result |
|---|---|---|
| 5A2A9BC3-63A3-4A46-9E8A-C778B4B97483 | Information control coordinate tap1130,689 from snapshot774 | Dispatched; expected Show field absent, verification failed. Numeric-bounds fix accepted for this case. |
| E3FCD658-CA5B-46EB-832D-B2EDF1A046C3 | Portrait request before user clarification | WDA Unable To Rotate Device; later steps skipped. Excluded from Gameday gate. |
| F9D81ACF-A86E-4FBF-B107-633B6C8B2059 | Route library, label only | Refused before input; selector not uniquely resolvable. |
| 794E0780-B769-4C19-B0FD-3B2A0DE3E834 | Route library, role button | Passed New route enabled; snapshots792→794. |
| 76E961CC-D846-4FC5-9032-48830505A88A | Playbook, role button | Passed Show play information enabled; snapshots797→799. |

Raw snapshots/results/screenshots are retained locally under ignored `.leap/sessions/3ADD85CE-E190-4536-BA94-D9E99F4865AA/` and SQLite. This tracked table preserves conclusions without requiring that local store.

## Rationale and alternatives

Successful navigation narrows the unresolved failure to the information-control case; broad claims that WDA input fails are unsupported. Portrait experimentation is inappropriate for an intentionally landscape-only app. Read-only source inspection finds the information Button in a bottom-trailing ZStack, with minimum44-point label frame; WDA reports a20-point glyph frame. Neither observation establishes the cause. Do not compensate by guessing an orientation transform or silently switching backends.

## Changes

Updated PLAN, FEATURES and continuation with native results and user-defined landscape scope. No implementation or Gameday source changes. Historical reports preserved.

## Validation and delivery

Native MCP calls above are the evidence; no new harness run, build or install. Current binary is unchanged from the prior numeric-bounds correction, restarted and tested. Source inspection used rg and sed on TabletPlayBrowser.swift. Skill behavior is unchanged; no skill sync needed for this documentation checkpoint.

## Remaining work

Information-control hit handling is unresolved. Navigation yielded977/986 reported changes, mostly omitted in compact responses; structural identity churn needs improvement. Reads/workflows take tens of seconds. Next diagnose this control using the successful navigation baseline, then finish landscape Simulator scroll/drag and remaining Mac/iPhone/Blender release cases. No blanket parity or certification.
