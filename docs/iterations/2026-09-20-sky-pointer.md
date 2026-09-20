# 2026-09-20 — Sky-derived pointer delivery correction

## Outcome and evidence

User asked to use the newly indexed native reference and make Leap work. [Tracked audit](../research/sky-native-input-audit.md) corrects the external audit's AX-only/no-event-synthesis conclusion. Decompiled mouse/wheel factories create events, assign target-window routing, and expose process-directed posting. Actual native implementation, not absence of static imports, is the evidence.

Sky native iPad Gameday double-click zoom and reset visibly passed. Sidebar wheel and drag produced no confirmed scroll movement. Leap native session_open returned Transport closed after the preceding install; this iteration has no new Leap native pass. Gameday remained upright/landscape,5 of11, field reset. No app source or stored play edits made.

## Rationale and alternatives

Leap already used AppKit event factories, CGEvent postToPid and window-local routing; replacing these wholesale would discard matching behavior. Three evidenced gaps were corrected: background activation omitted the window ID and flags found in Sky's factory; pointer construction could silently retain a generic event or return without input; the preferred intent API rejected coordinate scrolling supported by Sky and Leap's lower-level primitive.

Do not flip every event: Sky associates flipped coordinates with particular hosted-process target branches. Do not infer a virtual HID device from VirtualCursor symbols. This correction keeps the same process-directed pointer delivery in foreground/background and adds no automatic retry or backend substitution. Sky's complete focus state machine, activation-point click sequence and hosted-process routing remain unimplemented differences, not proven causes of this trial's failures.

## Changes

Input now creates window-specific activation notifications (AppKit-defined subtype1, target window, flags0xc0000). Deactivation preserves a user-activated foreground app; cleanup creation failure is independently logged. The pointer event factory rejects missing window routing and failed AppKit construction. Click/drag sequences are constructed/routed before the first pointer event, avoiding allocation failures midway through a gesture. Keyboard/text/wheel construction failures also propagate instead of silently returning; pasteboard restoration runs even when synthesized paste fails. Existing gesture timing and system-mode move behavior retained.

ui_perform Mac scroll now accepts x/y, snapshot and space as an alternative to selector, with the same bounds/tree/window/orientation provenance checks as coordinate click. WDA still requires selector. Existing tool names and defaults preserved; internal public Swift input methods now throw. Source skill explains the new operation and unverified scope. Removed an incorrect AX-only claim from Engine's keyboard comment.

## Validation and delivery

Ten AutomationModel tests and three PointerRouting tests passed. Pointer tests construct events without posting: verify screen location, selected window, PID, double-click metadata, activation window/flags, and rejection when a pointer target window is missing. These are factory tests, not native UI evidence. Initial compile caught one missing try in the Unicode-key path; corrected before passing tests/build. Signed release build and signature verification passed.

Installed SHA256 `a9f22dcf9c42bc229f4bc9218c2899ade30f0b04f9cb0fc7662aca9b46fabc8d`; [metadata](../../artifacts/test-runs/20260920-sky-pointer/install.json). Rollback and build/test logs are ignored/local-only under artifacts/backups/20260920-sky-pointer and artifacts/test-runs/20260920-sky-pointer. Skills-only installer synchronized both Claude and Codex copies; source/reference bytes compared equal. Registration leap unchanged. Current MCP connection is closed; restart needed. No native acceptance claimed from installation.

## Remaining work

After restart, open mac_ax Simulator/iPad, capture fresh screenshot/snapshot and repeat Sky field double-click zoom/reset, then field drag. Verify canvas change and window stability; test explicit foreground if background fails. Then exercise newly exposed coordinate scrolling with honest visual verification. Preserve failed results, do not replay uncertain input. Hosted-process coordinate routing, full focus-state parity, WDA information-button input, costly WDA observation, noisy deltas, desktop/iPhone/Blender end-to-end acceptance remain open. Scope is still the fixed release gate, not indefinite reverse engineering.
