# Peer review by ChatGPT 6 Astra (2026-09-18) — findings and dispositions

Two reviews were received: a code review of `~/src/claude-leap`, then a comparison against the
exposed contract of its own computer-use client (compiled; no source). Each finding was checked
against the code first; all confirmed ones are fixed in commit the commit that adds this file and covered by
`tests/wait-for-and-batch.json` plus the existing scripts unless stated otherwise.

## Review 1 — code

| # | Finding | Verified? | Disposition |
|---|---|---|---|
| 1 | Content-keyed indices can silently alias a look-alike sibling; stale check compares only role and size | Yes | `AppSession.element` now also compares live title/description (and value for non-editable roles) with what the model was shown, and returns the element's **current** frame. Actions always target the `AXUIElement` captured with the state the model read, never a re-resolved path. Residual: two siblings with identical text at the same position are indistinguishable in text for the model too; documented. |
| 2 | A successful action followed by a failed state read is reported as an error; batch failures discard the completed-step log | Yes | Action result and observation result are now separate: `(action applied; state unavailable afterwards: …)` is a success. Batch errors read `Batch stopped at step N of M … Completed steps (already applied — do not repeat them)`. Keystroke/coordinate/paste results say "dispatched, not verified"; accessibility paths say "(verified)". |
| 3 | Pinned window ≠ key window for keyboard input; first substring match accepted silently | Yes | `ensureKeyWindow` makes the pinned window key via accessibility (no activation) and verifies, else refuses with a clear message; used by press_key/type_text/paste keystroke paths. Ambiguous window substrings are rejected with the candidate titles (exact title wins). |
| 4 | Actor re-entrancy: parallel tool calls interleave actions and clobber the batch focus hold | Yes | `Engine.serialized` chains every tool call (action + observation, or a whole batch) strictly one after another; `Tools.call` wraps dispatch in it. |
| 5 | Text verification: `contains(prefix40)` false positive; partial write then fallback duplicates text; append ignores caret | Yes | `AX.insertText` computes the expected result from the before-value and selection and returns verified / unchanged / uncertain / notText. Uncertain outcomes are surfaced as errors and **never** fall through. The value-append path (iOS) is labelled as appending at the end. |
| 6 | `Int(d)`, `Int32(...)`, `steps=0`, huge counts can trap or spin | Yes | `Args.int/double` require finite values and clamp to ±1e6; drag steps 1…200; click_count 1…3; scroll pages 0…50 and deltas ±100k; batch ≤ 50 actions. Tested with steps 0, pages 1e300, coordinates ±1e308, click_count 99. |
| 7 | Window moved between observation and action → old coordinates | Yes | `element()` returns the live frame; `screenPoint` re-reads the window frame before coordinate delivery. |
| 8 | Clipboard restore can erase the user's newer copy | Yes | Restore only if `NSPasteboard.changeCount` still equals our write's count. Paste result says "dispatched". |
| — | README "public APIs only" inaccurate | Yes | README names the one private call (`responsibility_spawnattrs_setdisclaim`, via `dlsym`) and its fallback. |
| — | Comments promise restoring the previous app | Yes | Comment corrected: macOS 14 ignores activation from a non-frontmost process; no restore is attempted or claimed. |
| — | Cropped screenshots use an extra display scale; `.png` save may contain JPEG | Yes | Crop uses the same 1 px/pt transform as full captures; `save_path` ending in `.png` requests PNG encoding. |
| — | `set_value` treats every value as a string | Yes | Numeric controls receive `NSNumber`, boolean ones `true/false`; mismatches are rejected with a message. |
| — | Access policy, stop mechanism, secure-field redaction | Partly | `AXSecureTextField` values render as `••••••`. `LEAP_ALLOWED_APPS` (names, bundle ids or paths) is enforced in the resolver. A stop mechanism beyond the idle reaper and Claude Code's own cancel is **open**. |
| — | Structured MCP outcomes / output schemas | Open | Text results carry explicit "verified / dispatched / applied; state unavailable" markers. Structured content is a follow-up. |

## Review 2 — comparison with the computer-use contract

| Recommendation | Disposition |
|---|---|
| Session handles instead of re-resolving names and app-wide pinned window | Open. `AppSession` already holds identity, pinned window, generation and relaunch status; exposing a handle id in tool arguments is the next step. |
| Explicit observation modes (AX / screenshot / both) | Existing: `get_app_state(include_screenshot)` and `screenshot`. Kept. |
| Browser adapter | Out of scope for now; Claude Code has dedicated browser tools. |
| Per-target capability reporting | Done: the first state of a session appends a `Capabilities of <App>` line (Simulator: background keystrokes not delivered, tvOS no tree; Chromium: prefer accessibility edits). |
| Conditional orchestration ("click, inspect, then choose") | Partly: `wait_for` (appears / disappears / enabled / disabled / value_contains, bounded, reports settled vs deadline, batchable). Branching stays with the model, one round trip per decision. |
| App-specific guidance profiles | Open; the skill carries Simulator notes. |
| "UI stopped changing" ≠ "finished" | Done: header reports `(settled)` or `(settle deadline reached …)`; `wait_for` for explicit conditions. |
| Recoverable diffs: snapshot ids | Done: `state #N` on every state; diffs say `Diff vs state #M … pass disable_diff=true if you did not see #M`. |
| Capture stream only for visual observation | Done: `ShareIndicator` starts only when a screenshot is produced (`get_app_state(include_screenshot: true)` or `screenshot`), released after 90 s idle. Accessibility-only reads start no capture. |
| Progressive documentation; skill statements too absolute | Done: the skill now says which paths are verified and which are dispatched; capability line per session. |
| Treat the reference as comparison, not proof | Agreed; every change above is justified and tested on its own (see tests/). |

## Still open, in the order suggested

1. Explicit session handles in tool arguments (evolve `AppSession`).
2. Structured MCP results (outcome, verification, snapshot id) alongside the text.
3. A small fixture app with repeated rows, two identical windows, numeric controls and
   self-closing dialogs, as the repeatable regression suite.
4. A stop mechanism independent of the client.
