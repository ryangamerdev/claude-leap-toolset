# 2026-09-20 — Restore insights and narrow Simulator acceptance

## Outcome and evidence

User explicitly stopped Simulator typing tests and requested desktop Gameday workflows plus Simulator clicking, with insights restored. Earlier insights-off typing still lost characters; this does not prove insights have no performance cost, but disabling them did not eliminate the defect.

After user quit Simulator, reopening left only iPad Air booted. Session 2BC880F8-550E-4ABC-9438-C8E7980152C5 on installed keyboard-target candidate reported insights_enabled=false. Native rotation via super+Left produced upright landscape (snapshot3617). Search typed LEAP IPAD INPUT exactly (3629), selected the matching play, and Edit play opened the saved editor (3644/3648). The subsequent coaching-note replacement returned dispatch acknowledgement, but observation3659 contained no text area; capture3660 was retained but not inspected before user stopped typing tests. Outcome unknown; do not replay. Raw snapshots/images are local-only in .leap/sessions/<session>/.

A pre-relaunch resource snapshot showed busy Simulator services and 80% system-wide memory free. No controlled CPU comparison establishes that two devices caused the failures. Reopening is a confounding variable alongside the new process-directed keyboard build.

## Rationale and alternatives

Stop spending acceptance effort on Simulator typing that also had inconclusive Sky outcomes. Honor the revised scope: desktop Gameday editing and Simulator navigation/clicks, then paired Blender. Preserve the unresolved typing limitation rather than certify it. Restore useful retained insights instead of extending an unsuccessful disablement experiment.

## Changes

Set ~/.config/leap/leap.json insights.enabled=true, preserving logging settings. This is startup configuration; the currently loaded MCP still has insights disabled until session restart. No binary changes or rebuild required. Updated campaign documents and source skill guidance for revised scope.

## Validation and delivery

Parsed and rewrote configuration as JSON. Installed binary remains keyboard-target commit7faa53f, SHA256 f3e621d9231c10ed167e0650313b4be50acd03a1d934e077b90870f0ef2aece2. This host had restarted onto it; native scoped results above do not certify complete keyboard parity. Skills-only sync and content comparisons run before commit. No app reinstall or history cleanup.

## Remaining work

Restart host to load insights=true. Freshly inspect Simulator state without replaying interrupted input. Run paired Sky/Leap Simulator clicks/navigation and desktop Gameday coach/create/save/reopen workflows, followed by Blender. Simulator typing acceptance is explicitly deferred by user; full parity remains scoped and uncertified.
