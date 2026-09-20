# CAM-03 saved-play persistence and ambiguous AXPress

2026-09-20. Native Leap MCP, Gameday background. Reused the established Sky halftime baseline (`trial-sky-details.md`, steps 12–21) for notes/route/save/reopen. Only the task-owned TRIAL LEAP play was edited.

1. Searched TRIAL LEAP; exactly one result; selected and opened Edit play.
2. Existing coaching notes and receiver notes matched the previous saved trial.
3. Replaced coaching notes with the original text plus a newline and `CAM-03 persistence check: 2026-09-20.`. Accessibility read-back verified the replacement.
4. Selected receiver 1; clicked Assign 2 Step Slant, the existing assignment. Route controls remained enabled; no AX diff for reassigning the same route. This does not establish persistence of a newly changed route.
5. Clicked Save. Leap returned `The UI changed since the last state: element [369] it no longer exists. Nothing was done.`
6. Fresh observation showed the editor had closed. Show play information displayed the exact new coaching notes, including the marker, and the two existing player notes. Thus notes persisted despite the action's misleading failure report. We did not replay Save.

Evidence: `artifacts/test-runs/20260920-cam03-editor/native-before-fix.json`.

## Finding and fix

`Engine.click` tried AXPress first, then fell through to coordinate fallback for every non-success status. `visibleClickPoint` revalidated the now-destroyed Save element and emitted the stale-element message claiming nothing was done. The original AX error was discarded, so its exact code is not known from this run; the trace and code are consistent with an AX request completing while its response failed or timed out. No external user action was established as the cause.

After a dispatched AXPress, only explicit `actionUnsupported` now permits coordinate fallback. Other failures return `Outcome uncertain`, include the AX error/code, and instruct the caller to inspect the UI before retrying. No second pointer click is sent on an ambiguous reply. Pre-dispatch stale-element checks remain unchanged. This guards more than Save: any button that changes/removes itself can have an ambiguous response.

Build/install completed; native restart verification required. CAM-03 remains RECHECK: notes persistence observed, accurate ambiguous-action handling awaiting verification, changed-route persistence still to test. Simulator work follows this checkpoint.


## Sky reference: AX action error tolerance

Inspected the reference disassembly and matching installed binary (SHA-256 `e45685d52bf9da816c2e2eb27a84e85f4c76b5dd781ecb70f3833731c1c62eeb`). At 0x1006e6cd4 and 0x1006e6e34, wrappers call AXUIElementPerformAction once. Each returns normally for zero or either of two stored error constants; other codes become Swift errors. Constants at virtual addresses 0x1013a11c8 and 0x1013a11f8 are both signed Int32 pairs (-25204, -25205), decoded through Mach-O LC_SEGMENT_64 mapping. Local Xcode AXError.h identifies these as cannotComplete and attributeUnsupported, respectively. actionUnsupported is -25206 and is not one of the tolerated pair.

No retry or coordinate click occurs in these wrapper paths. This does not prove the behavior of every higher caller. Sky's documented action/observation loop requires fresh AX state after actions; normal return from this wrapper is not semantic proof that Save persisted. Wrapper excerpt: `sky-ax-action-wrapper.asm`.

Comparison: Leap's installed guard is more explicit about uncertainty instead of swallowing the same errors; it prevents ambiguous AXPress replies from triggering coordinate fallback. A useful next improvement is to include refreshed state with uncertain action responses, keeping transport outcome separate from observed task success. That enhancement is not yet implemented or installed. Neither backend can guarantee the OS will never return an ambiguous AX reply.

## Current installation checkpoint (2026-09-20 peer review)

Installed AXPress-guard binary SHA-256: `d99b243d0d51812b6ee4d2877ed5e9b395a51ce5088c36212d57fbd054544ebc`; path `/Users/ryan/Applications/claude-leap.app`. Install/backup provenance is in `artifacts/test-runs/20260920-cam03-editor/install.json`. No native verification after this installation is recorded. See `docs/PLAN.md` REC-00–03 for the revised durable-capture-first sequence. Proposed structured results, automatic post-error observations and event history are not supplied by the guard alone.
