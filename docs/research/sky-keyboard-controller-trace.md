# Sky app keyboard controller: complete route trace

2026-09-20. This corrects earlier inferences from isolated event factories/senders. The user supplied the90-shard list plus manifest/name index. scripts/index-sky-keyboard-reference.py searches the entire aligned symbol manifest and records selected pointers in artifacts/test-runs/20260920-keyboard-target/reference-index.json. Index coverage is not body-review coverage. Bodies below were inspected; no claim all134,750 bodies were read.

## Route traced

1. Readable ipc/mac-client.js typeText → performAction(app,{type:{_0:text}}).
2. App controller performKeyboardAction0x1000764d4 → continuation0x1000765b8 in part-0001.c. It creates/reuses SyntheticAppFocusEnforcer, inspects its state, obtains/refetches window context, and invokes focus enforcement before target resolution. Some Swift virtual-call state bits remain decompiler-ambiguous; do not assign names to every bit.
3. ApplicationUIElement.targetForKeyboardEvent0x1006f1d48, part-0025.c: default app PID, focused element, outOfProcessTarget lookup.0x1006f1f54 uses ProcessType.containingElement to select an effective hosted-process target when appropriate; otherwise app PID. This is a real omitted stage, not simply CGEvent creation.
4. Type branch0x10007711c →0x100077180 builds text via SynthesizedEvent.type, then invokes send(to:pid,delay:). Key chord branch0x1000772ac also invokes send(to:pid,...). Held keys0x100077578 likewise preserve target PID. Therefore a globally available send(delay:) method is NOT evidence these app actions use global input.
5. Text builder0x10072a5a0 → SAIVirtualKeyPress.keyPressesForString;0x10072a660 constructs all events through0x10071b150. Modifier/key/text fields feed flagsChanged/down/up/restoration. Text branch supplies a nonnil delay; chord branch passes nil. Exact Swift Duration interpretation is not needed for the routing fix and no new timing constant was copied.
6. PID sender0x1007290b8 timestamps and posts each event to target PID, optionally waits between events. Separate global sender0x10072abe4 exists, but is not the route called by the traced app type/chord branches.
7. Completion0x1000773d4 conditionally waits for UI settlement and updates Skyshot. Request parameters control whether observation occurs. A returned action is not proof of persisted application data.

## Focus enforcement inspected

0x10071e884 part-0026.c reads locked focus state and either needs no intervention, calls activation helper0x10071ee6c, or sends a process notification kCPSNotifyKeyFocusReturned to the app PID and updates state. The type has distinct applicationIsActive/applicationBelievesItIsActive/applicationBelievesItHasFocus fields. Leap's activation check is not equivalent. Full event filtering/tracker lifecycle is still incomplete in this audit; foreground-first scope avoids claiming that background machinery.

## Consequence for Leap

Engine.withInput previously selected .system for foreground:true. That is unsupported by this app-controller trace and allowed input into the user's foreground app when focus moved. Now activation remains optional policy, but all app keyboard callbacks receive process-directed delivery with a resolved same-owner window. Invalid/missing window ownership rejects before input. Chords, text and paste share this boundary. No global fallback.

This candidate deliberately does not invent hosted PID mappings from private decompiler layouts. It uses selected app PID, which is narrower than Sky's effective-process resolver. Same-process window focus remains a separate concern: postToPid alone cannot bind a particular responder or prevent user changes inside that app. Native Simulator acceptance remains pending. No virtual HID device is established by these findings; virtual key objects and cursor abstraction do not prove one.

## Evidence and correction

On f1ccb2a, Read still became Red (sessionC9B689B7-9F71-40D3-AC5C-CD9DC63F1A42 snapshot3588). User then observed a literal a in ChatGPT. That supports wrong-app delivery for at least one event, but is not proof every prior missing character shared that cause. The subsequent read was interrupted; fresh state required. No more UI input was sent during this reference investigation.

Earlier statement “Sky contains both delivery paths” was true but incomplete. The meaningful conclusion is that the inspected app keyboard controller uses a resolved PID. Future reference work must trace caller → resolver → factory → sender → observation and record unresolved branches before copying behavior.
