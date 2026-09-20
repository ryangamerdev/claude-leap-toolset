# 2026-09-20 — Phone comparison and full-page scroll evidence

## Outcome and evidence

User requested continuous progress until completion or required restart. Sky selected iPhone16 via Simulator Window menu, opened Phone parity Playbook, advanced1of8→2of8, opened filters, then restored home. Coordinate wheel435,350 and drag430,425→430,280 failed with windowNotFoundAtPosition; element RUN scroll also failed. No successful Sky phone gesture claim.

Leap native session5845A8D4-E737-414C-98E7-B99B8110AE5D passed the same three semantic navigation postconditions in interaction59551695-0914-490C-AAF0-7365A91D7A36. Selector scroll RUN showed no effect; explicit foreground drag0F298C91-290E-4645-B6FB-2DF9E1E022EA visibly scrolled to defense alignments. Closed filters, restored49ERS1of8, then Home selector correctly refused ambiguity (host and guest buttons). No input sent for Home; phone remains Playbook. Session closed.

Sky desktop sidebar scroll passed: scrollbar0→0.4911180773249739→0. Leap desktop sessionF1F7C36C-6042-4EB7-A6AC-202C7C6DF52C also visibly scrolled down/up, interactions07C4E7D7-3519-4F8D-B24E-284088AE4B74 andE4AF17E5-157C-4F61-95CD-BBC02E7EF831. Returned55 deltas,460-point displacement and visual changedFraction0.16632, yet movement status unverified. Sidebar restored, session closed. Existing trial play/notes/search untouched.

## Rationale and alternatives

Native retained frames prove the detector's visibility condition was too strict: both centers had to stay inside a470-point viewport despite460-point displacement. Full-page scrolling naturally replaces visible content. Accept intersection before OR after while requiring two coherent directional movements in target scope. Also use numeric AXScrollBar value changes within that scope and axis as direct position evidence. Do not weaken evidence to any image change or silently substitute gestures. No speculative Simulator geometry transform added.

## Changes

ScrollEvidence checks viewport intersection at either endpoint, plus scoped finite untruncated scrollbar value movement in requested direction. Wrong-axis/direction/unrelated/no-change cases remain unverified. Boundary still unknown. Updated source skill, checklist, plan, handoff and standing continuous-work instruction. No transport changes; wheel limitations remain.

## Validation and delivery

Five focused ScrollEvidenceTests passed, including new full-page/no-shared-visible-centers and scoped scrollbar cases. This is harness validation, not native acceptance of corrected detector. Signed release build and codesign verification passed. Installed SHA2560f480bff42638e2a18fe6090e47beacf1884a899c9524893110236c9849aca21; [metadata](../../artifacts/test-runs/20260920-scroll-page/install.json). Skill installer ran; source and Claude/Codex copies matched. Registration leap/history preserved. Logs/rollback bundles are local-only ignored artifacts/test-runs/20260920-scroll-page and artifacts/backups/20260920-scroll-page.

Tracked native evidence on previous bc78636 build: [phone results](../../artifacts/test-runs/20260920-scroll-page/iphone-native.json), [phone drag screenshot](../../artifacts/test-runs/20260920-scroll-page/phone-drag.png), [desktop results](../../artifacts/test-runs/20260920-scroll-page/desktop-native.json), [desktop scroll screenshot](../../artifacts/test-runs/20260920-scroll-page/desktop-scroll.png). Original .leap references inside results are local-only. Sky observations are recorded above from live Cua calls; no exported Sky native trace claimed. Commit/push before restart handoff.

## Remaining work

Restart and verify desktop full-page down/up reports movement_observed with retained references. Continue desktop coach/create/save/reopen then paired Blender UI modeling/save/reopen without stopping at intermediate checkpoints. iPhone foreground drag passed visually; background parity and Sky failed-gesture comparison remain limited. WDA information touch, exact orientation acceptance, full focus and hosted-process targeting remain open. Objective not complete.
