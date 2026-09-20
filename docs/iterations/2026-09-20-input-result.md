# 2026-09-20 — Preserve backend input results

## Outcome and evidence

Restarted1eb189f. Live session CD713DA2-D28E-4015-83ED-B3F232EE6196. SKY IPAD KEYBOARD 0920 - Slant Flat found by exact title and reopened with coaching notes present (interaction7E74AC9D-A1B8-4BFD-BA3D-8FFF5C6FDE80, snapshot2593). Curated screenshot confirms saved title, route geometry and coaching notes. Previous Team libraries view dismissed deliberately with Done once; immediate Search step refused incomplete observation, then fresh state recovered without repeat Done.

Screenshot-targeted Save at window_points920,146 snapshot2593, foreground true: interaction803ECB94-F156-4538-83C7-04A3BE1374C1 acknowledged but verification unknown after20-second wait; screenshot still showed editor. Later observation2619 showed playbook, not Team libraries. User moved window slightly during this period; bounds changed130,99 to69,80. This is a qualified comparison, not proof of fixed routing. No repeat Save sent. Gameday source Save closes editor, TeamMenuButton separately sets its presentation state on press; no explicit Save→Team libraries transition found. Runtime cause remains unresolved.

Duplicated into unsaved LEAP IPAD INPUT 0920 - Slant Flat (C3C45E30-55CF-4D74-BBE4-A0A1CA29BC35), set coaching text Leap normal typing acceptance. returned successfully; field had existing saved notes, so this does not exercise previously nonsettable blank-field refusal. Do not claim native guard acceptance or save persistence for this draft.

## Rationale and alternatives

The user expected before/after data and correctly challenged unexplained navigation. Database evidence remains active, but automationInput discarded every backend return string. Thus the result only said acknowledgement returned, losing whether click used AXPress or pointer and what text route was used. Preserve this existing evidence instead of guessing route from visible cursor markers, adding arbitrary delays, or treating successful dispatch as effect. This is an observability correction, not a claimed Save fix. Sky reference/live comparison from preceding iteration remains relevant; no new reference inference is required to prove the discarded return value.

## Changes

automationInput returns its backend description. ui_perform stores input_result, action and resolved target ID/index/role/label/frame with the per-step record and response. WDA describes acknowledgement without claiming a Mac route. Existing verification, snapshots, deltas, no-replay behavior and database remain unchanged. Errors preserve target/action when dispatch was reached but may have no returned description. Frames are provider geometry, not certified click coordinates.

## Validation and delivery

TOOLCHAINS=org.swift.640202609131a python3 scripts/bundle.py; build/install result in artifacts/test-runs/20260920-input-result/install.json. Build log and raw .leap session local-only. Curated sky-comparison-reopened.png tracked. Source/installed skills synchronized. New result fields require restarted native acceptance; compilation is not acceptance. No data cleared or registration renamed.

## Remaining work

Restart, preserve current unsaved duplicate and verify new result fields using native calls. Check multiline typing/persistence on distinctly titled trial, independently verify player2 Flat/note. Investigate Save versus Team libraries by actual delivery evidence; no causal conclusion yet. Keep fresh coordinate provenance after user window moves. Then paired Blender and remaining release gates. No overall parity claim.
