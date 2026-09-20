# 2026-09-20 — Native creation and unsupported text values

## Outcome and evidence

Restarted 1b7be96, binary SHA256 6a80e2b3b12dd20098e8678931ba874445fc42f2a15a41982c120fbe26cd4aa9. Desktop LEAP ACCEPTANCE 0920 - Slant Flat created, saved, searched and reopened. Both named routes visually selected in reopened editor; both player notes and coaching notes persisted. Metadata correction passed native role-qualified targeting with advisory unavailable fields. Save acknowledgement was uncertain (-25204) but postcondition passed; no Save replay. Later reopen established persistence.

On iPad, Sky created a draft/title but receiver coordinate click failed windowNotFoundAtPosition, also after Raise and explicit Leap foreground activation. Leap own screenshot/window_points click selected receiver and assigned routes. Draft renamed LEAP IPAD ACCEPTANCE 0920 - Slant Flat. Set_value coaching notes immediately matched AX and screenshot, but reopened editor had blank coaching notes. Title, route geometry and player1 note persisted; player1 selected 2 Step Slant verified visually. Player2 persistence still needs independent reopened check.

Sky setValue refused the unfocused coaching field as not settable. Sky semantic click + typeText produced notes despite a later noWindowsAvailable observation error. After Save, duplicate of that saved play contained coaching notes. This supports an unsupported AX write/binding issue, not a proven general app data-model defect. User observed notes typing and suggested model issue; hypothesis remains documented. Comparison duplicate title changed through Sky to SKY IPAD KEYBOARD 0920 - Slant Flat and Save dispatched; subsequent team count1049, but exact renamed saved record still needs search/reopen verification.

Both Sky and Leap Save led after AX outages to Team libraries, which the agent did not intentionally open. Done was clicked to return. User observed this. Cause unresolved (app behavior/input routing/provider semantics); do not label expected navigation. Stop repeating this cycle without investigating.

## Rationale and alternatives

Engine.setValue tried selection replacement then raw AXValue without checking advertised settable capability. Readback cannot distinguish a display-only value from a changed SwiftUI binding. Sky live refused this unsupported write. Gameday source Editors.swift uses TextEditor(text:$play.notes), whereas player notes use TextField. Source alone does not prove runtime cause. Fix the supported capability violation, not Gameday speculatively. Reject direct unsupported writes explicitly; retain existing normal type_text path rather than silently synthesizing replacement keystrokes with guessed focus. Changing waits cannot fix lost binding persistence. Normal typing evidence is stronger than simply increasing an 80ms readback delay.

## Changes

Engine.setValue checks live AXValue settable capability after selection replacement cannot complete; refused direct writes log set_value_not_settable and return actionable unsupported result. No raw value or keyboard fallback on that branch. Existing supported direct values unchanged. Skills explain immediate value versus persistence and focused normal input. This guards one concrete path, not all text-provider errors or app saves.

## Validation and delivery

Native sessions (raw .leap evidence local-only): desktop06DC8C06-59A5-4A14-A6C2-55DA067138FE; iPadA03ED771-26C8-4AB0-945E-267640153C83. Curated images in artifacts/test-runs/20260920-text-capability.
Desktop interactions: title71FD88C0-6A08-4B8B-A155-B585A89A40D6; assignments B5C66FB4-E45D-481B-B994-3C59074109F2; Save7037B804-F2C1-4720-A8D1-3EA0DEC5775A; reopen4ADE9DC9-3470-4201-B8AB-43CA4E8B4E6A; route images8C0451C0-B808-4965-9011-F3602526BA6E and1CB2A2BC-6BB4-438F-9A9D-CDE97C16209A.
iPad: receiver8F2E4626-9F3A-4FEF-A4B4-4ECC560D8B21; slant538FAAE5-22B3-4BAE-BFF9-DF2F54508B3A; flat5E7CCF34-87A8-4CDB-B0CC-98194F6D154B; coaching854B00ED-C1FB-40B5-9115-9CD8B4A17611; SaveED7C6674-98E1-44EF-A605-5D9105527622; search54AFA09F-6F88-4D2E-BE46-6F8D6BC9E894; reopenF217B43F-3D85-4A4A-8598-3DB177C1503C; slant8437F58F-5DF3-4D7B-A01D-403A46884792; duplicateB666B534-5F6B-418A-BDA4-760C24954D5B.
Build command TOOLCHAINS=org.swift.640202609131a python3 scripts/bundle.py passed. Build log local-only. Install identity in artifacts/test-runs/20260920-text-capability/install.json. Native guard acceptance requires restart. No harness pass substituted for native testing.

## Remaining work

Restart; verify unsupported multiline direct write is refused without changing content, and normal focused Leap typing persists in a distinctly named play. Investigate unintended Team libraries after Save with Sky and Leap before further repeated saves. Verify SKY IPAD KEYBOARD title and coaching saved; original Leap record was also modified during Sky diagnostic before the distinct duplicate was created, so earlier retained snapshots establish initial failure. Check player2 reopened route/note. Then Blender paired UI modeling/save/reopen and remaining specification gates. No full parity claim.
