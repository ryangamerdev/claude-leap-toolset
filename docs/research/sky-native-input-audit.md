# Sky native input audit — 2026-09-20

This corrects the overly broad conclusions in the externally supplied AUDIT-INDEX.md. Reference files are local-only under /Users/ryan/src/sky; this tracked report preserves findings and function addresses. Ghidra pseudocode is incomplete, particularly Swift async ABI and floating-point arguments; a symbol name is not behavioral proof.

## Findings checked in the recovered implementation

| Path | Reference | Finding and Leap consequence |
|---|---|---|
| Pointer factory | part-0026.c, 0x100729ca4 | Creates NSEvent mouse event, obtains CGEvent, assigns global location, button field3, subtype field7=3, window fields0x5b/0x5c, window-local location. Throws on construction failure. Leap already used these fields but silently retained the original raw event when AppKit construction failed; now rejects it. |
| Wheel factory | part-0026.c, 0x100729f30 | CG scroll event with window routing and local location. Leap already included wheel field51 and pointer window fields. The intent API, however, omitted coordinate scroll; now exposes it with provenance checks. |
| Target resolution | part-0025.c, 0x1006f10a0 vicinity, target(forMouseEventAt:axWindowAtPoint:axElementAtPoint:) | Distinguishes same-process AX target from out-of-process target window; records PID, window ID/bounds and flipped-coordinate flag. Default same-process AX branch sets false; out-of-process CGWindow branch sets true. Do not flip every event as a workaround. Leap does not yet implement equivalent hosted-process routing. |
| Background activation | part-0026.c, 0x10071a8fc | AppKit-defined activation subtype1 includes window ID and flags0xc0000 when window ID exists. Leap used window0/flags0; corrected. Sky additionally has an activation-point sequence and focus-enforcer state machine; those are not claimed implemented by this correction. |
| Focus state | part-0026.c, 0x10071e884; part-0025.c, 0x1006e98a8 | Tracks app-believes-active/focused versus actual activation and may wait for believed-frontmost state. Leap's scoped synthetic activation remains simpler; no universal parity claim. |
| Posting | names-demangled index; part-0008.c, 0x100248204; SynthesizedEvent.send in part-0026.c | Native CGEventAPI.postToPid wrapper and synthesized-event sending exist. Absence of direct CGEventPost imports does NOT establish AX-only operation. dlopen/dlsym imports also exist. |
| Cursor | sendClick signature includes virtualCursor; ComputerUseAppController.createVirtualCursorIfNeeded | Supports a virtual cursor abstraction, not proof of a virtual HID device. Input factory/posting evidence points to process-directed events; do not introduce a device merely because this symbol exists. |

## Native comparison before this install

Sky iPad Gameday field double-click at screenshot605,445 visibly zoomed, reset at288,629 restored it. Sidebar wheel175,450 down1 and drag175,585→175,340 produced no confirmed scrolling. This is an observed limitation of this trial, not proof scrolling can never work. Simulator remained landscape. No play edits or filter changes intentionally made.

Leap session_open returned Transport closed after prior installation; no native pass for this iteration. Do not substitute factory tests for app acceptance.

## Implementation boundaries

This increment restores missing metadata, rejects construction failures and exposes coordinate scrolling. It does not reproduce Sky's entire focus state machine, out-of-process AX routing or observer implementation. Existing same-process pointer transport stays process-directed in foreground/background. No coordinate-flip guessing or automatic backend retries were added. Test native background field zoom/drag/reset next, then foreground if the effect fails; inspect actual window movement and retained evidence.

## 2026-09-20 — Revisit after unexpected Save navigation

Directly inspected full shards, not the index conclusions:
- part-0001.c0x100071618 (ComputerUseAppController.click(elementID:...)): calls prepareToInteract(with:cursorNextInteractionTiming:positionElement:). Continuation0x10007172c reads computerUseAlwaysSimulateClick feature flag and passes it to UIElementProtocol.click with window/application/focusEnforcer/virtualCursor. The configured runtime flag value is unknown; do not assume every Sky button uses AXPress.
- part-0027.c0x100795c08 (focusFieldIfNeeded continuation) classifies focusable fields and invokes focus.0x100796058 writes focused, then explicitly calls uncachedValue for focused; if not true it enters the click path. Leap's AX.insertText and keyboard fallback write AXFocused and sleep without equivalent verified-focus handling. That is a concrete difference, not evidence it caused Save navigation.
- Existing target resolver0x1006f10dc and hosted-process/focus-state findings above remain incomplete in Leap. No evidence obtained that a virtual HID device is required.

The latest manifest's behavioral bullets A/B remain overbroad despite its useful complete file inventory. Source calls to synthesized click and the force-synthesis feature flag directly contradict a universal AX-only claim. Decompiled async wrappers contain indirect continuations and unknown flag values; reproduce verified behavior, not guessed pseudocode parameters.

Investigation priority: compare actual semantic versus pointer Save dispatch with the newly retained input_result and target; inspect current target identity/geometry and outcome. Then implement the relevant preparation/focus/host-routing difference supported by that trace. Avoid substituting another generic diagnostic increment or copying every reference branch without identifying the active path. Both tools previously reached unexpected Team libraries, while one qualified Leap coordinate Save returned to playbook. The incident is not yet a demonstrated Sky-only success/Leap-only failure.

## 2026-09-20 — Click midpoint comparison

part-0027.c0x1007833a4 clickablePoint(scrollToVisible:) and continuations0x1007833c4/0x100783668 call CGRectGetMidX/MidY then CGRectContainsPoint against a second rectangle; scrollToVisible runs before refreshed geometry. This supports midpoint containment, not midpoint of an arbitrarily clipped fragment. Leap visibleClickPoint instead used indexed frame and center of intersection; changed to live AX.frame and full control midpoint containment. Sky also has specialized Chess hit-test sampling in0x100783818; do not represent that app-specific64×64 search as universal behavior. Mouse target resolver0x1006f10dc separately checks actual PID/window and point lookup; equivalent hosted routing still not implemented.
Native Leap SaveCB54A752-0C9D-4727-AC0C-169F0F95EABF returned AXPress on Save index9 with suppressed marker, then Team libraries. Thus no coordinate pointer was sent for that reproduced incident. Reported Save frame y941 in780-point window is malformed but was unused. Geometry fix is independently supported, not a causal Save fix.

## 2026-09-20 — Keyboard event sequence

part-0026.c0x10071b150 creates a generic event, sets type, flags, then keyDown/keyUp and a final generic event restoring sourceFlagsState(0). Disassembly verifies type0xc (flagsChanged) at0x10071b2e4 and0x10071b424.0x10072a884 creates source state1 (HID system state).0x10072abe4/0x10072aee8 set timestamp immediately before posting at tap1 (session tap);0x10072aa7c refreshes timestamp before postToPid. Leap lacked modifier events, used HID tap for foreground keys and creation-time timestamps. Candidate now brackets keys and unicode chunks with flagsChanged, prebuilds the sequence, restores observed combined-session flags, timestamps each post, and uses session tap for foreground keyboard. Does not claim copying the complete Sky key/focus pipeline.
Native Sky Escape dismissed accent popup; super+a after semantic focus did not visually select the whole note (word athrow selected instead). Thus no Sky select-all pass claimed. Native Leap multiline guard26A14770-8F14-46AA-8668-94ED04618794 refused raw write, identical note values in snapshots2912/2916. Save root cause still separate.
