# 2026-09-20 — Native scroll-effect evidence

## Outcome and evidence

After restart, native session A1EF4E5B-F445-46EC-8D41-3CBAB5D66AD8 targeted landscape iPad Simulator. Two wheel trials scoped to sidebar [58,304,196,395] returned unverified, boundary unknown, no_visual_change_observed and changedFraction0. First omitted foreground:true; second followed explicit activation and requested foreground:true. Actual initial OS focus was not independently captured. Interactions A3E3944F-A53E-4145-99AA-F1FBC2586C55 (6976ms) and728AEBC6-6CA5-43E9-B2E2-2D377F9276CF (4210ms) each retained before/after captures and one additional observation. No deadline overruns or capture errors reported. Two advisory AX failures persisted; zero blocking.

Explicit drag control5053BE4C-650C-48A9-9153-270C1D0DB179 visibly scrolled to defense alignments;50 deltas included positions/offscreen state. Reverse dragCD21724F-9177-446F-BB51-F62A9E5FB542 restored sidebar top range. Field and original play5of11 unchanged visually. Session closed, app left running. Native evidence_read of record1104 path steps/0/scroll_effect/visual returned the retained254-character comparison, without input replay.

## Rationale and alternatives

No input-delivery change justified by this observation-only candidate. Reporting correctly avoids equating no tree change with failed input or a reached boundary. Drag is an explicit positive visual control, but it does not execute the scroll_effect classifier; positive automatic movement detection remains unverified. Continue the fixed campaign rather than repeating identical wheel calls or inventing a transform. Slow AX acquisition allowed one extra poll within the bounded scheduling window; do not describe this as four polls guaranteed or full UI settling.

## Changes

No source/binary changes. Curated native results/screenshots, updated checklist/plan/handoff and skill acceptance scope. Runtime history retained untouched. Prior FAILED wording describes no confirmed visible effect, not proven failed transport.

## Validation and delivery

Loaded installed bc78636 SHA2561667ba6a99632d29412b635f83d45f072011bd10c794f658fac899f8fa10af9a after restart. [Native results](../../artifacts/test-runs/20260920-scroll-evidence-native/native-results.json), [baseline](../../artifacts/test-runs/20260920-scroll-evidence-native/baseline.png), [wheel after](../../artifacts/test-runs/20260920-scroll-evidence-native/wheel-after.png), [drag control](../../artifacts/test-runs/20260920-scroll-evidence-native/drag-control.png), [restored](../../artifacts/test-runs/20260920-scroll-evidence-native/restored.png). Original .leap paths inside results are ignored/local-only. Skill synchronized via skills-only installer and source/installed copies compared. No binary rebuild/restart necessary for this checkpoint; commit/push documentation and evidence.

## Remaining work

Next paired Sky/Leap iPhone landscape navigation/scroll; exercise positive automatic scroll evidence on a supported area, then desktop coach/create/save/reopen and Blender UI modeling/save/reopen. Background parity, wheel delivery, hosted-process routing and WDA orientation/information-touch limitations remain open. Automatic assertions were not supplied in these trials; visual judgments are separate from not_evaluated verification fields.
