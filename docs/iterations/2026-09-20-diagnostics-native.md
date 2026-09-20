# 2026-09-20 — Native diagnostic audit and rotation evidence

## Outcome and evidence

User restarted the installed b3c359b5c8d86319897ef0b1b5cc285d3b18947a0e1df592629cb45910be779f candidate. diagnostic_query worked before project binding, reported loggingLevel info and ~/.leap/logs/diagnostics.db, and recorded process6ED234BB-DA5E-48AE-B39D-4127F5EF43B0. A deliberately invalid historical read returned an error with diagnostic references, then querying interaction8940E070-109B-4A79-9FF9-2DCF5BAD59B2 retrieved that error. It sent no UI input. Its generic completion text says input may have been sent; this is overbroad for read-only calls and remains a wording gap.

Cross-process group resume passed: E02D3027-C127-4760-A280-7E2FC74244C4 retained all three previous captures and added081006C4-A5E8-4823-855A-DC70B668B454 with new interactions. Inventory showed15 total recording sessions and718 records during the test. No history was reset.

Two background iPad view toggles each used one acknowledged AXPress and met their postconditions. Interactions73F9C5CA-CE52-4683-9D8F-D2182AC6252C andE93484AD-7C09-4374-AA14-4DDF6B39AFB1 returned explicit indicator suppression. diagnostic_query(kind:indicator_suppressed) retained exact element/window rectangles and stated no pointer event was sent. The short precheck hit a deadline; final checks succeeded. Checkbox AXSubrole errors remain advisory2/blocking0. Captured diagnostics distinguish these conditions; they do not establish a causal connection between metadata failures and geometry.

## Rationale and alternatives

Sky screenshot showed the iPad in landscape with its information button at the lower-right of the field. Leap's directly-read AXPosition/AXSize put the button around(795,1031,16,16) outside window(377,61,1006,780). Source AXTree.swift combines those attributes without an orientation conversion. Static Sky reference strings mention coordinate/view conversion but do not establish a Simulator-specific correction algorithm; no such fix is claimed from strings alone.

Using Sky, selecting the iPad explicitly through Window menu mattered: an intervening default Sky read selected iPhone. Device→Rotate Left changed the window to727x1059 at(377,58); Leap reported the button at window-relative(917,625), outside the right edge. Screenshot showed the app content sideways. Device→Rotate Right restored the landscape field; final Leap snapshot744 returned1006x780 at(377,58) and original erroneous relative(418,969). This supports an orientation/coordinate-space mismatch, not a proven conversion formula. Window origin moved3 pixels vertically during rotation; not manually corrected. During navigation a stale menu index opened I/O; it was cancelled without changing settings, then Device was reopened using fresh indices. No play content edited.

## Changes

Acceptance docs and skill status only. No binary change. Independent diagnostics now have a scoped native pass, as does cross-process group continuity. Indicator suppression is confirmed in action output and diagnostic evidence; no claim that Sky/Leap screenshot captured the transient absence of a ripple. Geometry remains unresolved. Do not introduce an inferred rotation transform without explicit orientation/source-space evidence.

## Validation and delivery

[Retained native responses](../../artifacts/test-runs/20260920-diagnostics-native/results.json) include initial/rotated/restored frames, both action results and the audit trail. Sky screenshots inspected in this conversation are not tracked artifacts; native responses and this report preserve the measurements. Live diagnostic database is user-local by requested design. Simulator recording stopped cleanly at handoff; group remains resumable. Source skill updated and skills-only copies synchronized. Commit/push the checkpoint, no rebuild/restart needed for documentation.

## Remaining work

Investigate actual Simulator coordinate spaces/orientation metadata and compare direct single-attribute versus batched reads before a correction. Do not equate screenshot coordinates with device/AX coordinates. Verify valid marker behavior separately. Narrow read-only completion diagnostics; reduce warning repetition without hiding errors. Then continue Simulator/paired Blender campaign. No new restart is required at this checkpoint.
