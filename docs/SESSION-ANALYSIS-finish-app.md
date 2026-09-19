# What the Codex "finish app" session actually does, and what leap should copy

Source: the live Codex/Sky session `01a0ab80-…-43fd946840f1` ("finish app", cwd
`/Users/ryan/src/gameday`, model gpt-6-astra). Two rollout files under `~/.codex/sessions`
(134 MB + 1.03 GB). Analysed by streaming, never loading image bytes into context.

## Where the bytes are (so you can ignore them when inspecting a session)

Profiling the 1.03 GB active file by record `type`:

| type | size | count | what it is |
|---|---|---|---|
| `compacted` | 664 MB | 33 | context-window snapshots saved to disk at each compaction |
| `event_msg` | 246 MB | 10,315 | UI event wrappers (`item_completed` duplicates each item) |
| `response_item` | 120 MB | 8,966 | the actual model conversation stream |
| `token_usage_record` | 3 MB | 3,439 | per-turn token accounting |
| others | <1 MB | — | `world_state`, `turn_context`, `session_meta` |

To inspect a session cheaply: read `response_item` records and skip `compacted` and
`event_msg`. The giant lines (20–25 MB each) are all `compacted` records whose
`replacement_history[].content[].image_url` holds base64 PNGs.

## The image/context architecture (answers the "sub-agent that digests images" hypothesis)

There is **no OCR/RAG sub-agent that converts screenshots to HTML**. GPT-6 is multimodal and
reads the raw PNG directly from the tool output. What keeps images from blowing up the running
context is two mechanisms:

1. **Text-first observation.** Screenshots are the exception, not the rule. Of 1,585 `js`
   (sky) calls in the session, only **435 (27.4%) returned an image**; the other ~73% were pure
   accessibility text (`getAXState`). Images average **119 KB base64** (median 106 KB, max
   256 KB). The model drives and verifies from the AX tree and asks for a screenshot only when
   the answer is visual — a zoom level, a drag/pan offset, a play-diagram canvas, a rendering
   glitch — exactly the cases in the last turn.

2. **Compaction distils each window and drops its images.** A `compacted` record holds the
   full window history (`replacement_history`, ~20–26 images) plus a parallel `guardian_history`
   (the auto-approval/guardian model's stream, ~7–12 images) — both saved to disk — and a
   `retained_context` carried into the next window. `retained_context` (with
   `verified_answers` and `user_messages`) contains **zero images**. So screenshots live only
   inside the current context window and are discarded at the next compaction; only distilled
   text survives. That is the "digest that survives" the user intuited, implemented as
   compaction, not a per-image service.

`guardian_history` mirrors the main conversation (user/assistant/tool_call/reasoning) — it is
the safety reviewer that also sees the screenshots, not an image-abstraction helper.

## The last full turn, step by step (zoom-icon task, 22:02:27 → 22:16:53 ≈ 14.5 min)

165 stream steps. The shape:

- **Mostly code + shell, not UI.** Read source with `rg`/`sed`, apply patches with
  `apply_patch`, build/test with `run-logged.sh`, poll long builds with `write_stdin`, then
  `git add/commit/push`. The `exec` custom tool carries this; UI driving is the verification
  layer on top.
- **Action + observation in one call.** Every sky call is `await X.click(n); await
  X.getAXState()` (or `…AndScreenshot()`), so the model always gets the fresh tree back in the
  same round trip and reads the diff. It never fires an action blind.
- **Text by default, screenshot on demand.** Navigation and structural checks use
  `getAXState()` (no image). It switched to `getAXStateAndScreenshot()`/`getScreenshot()` only
  to see the zoom factor and drag-pan rendering — things the tree cannot express. Same 1-in-4
  ratio as the whole session.
- **Interleaves shell and UI freely** in one turn, re-acquires app handles after relaunches
  (`cua.getApp(path)`), and calls `cua.rewriteDocumentation()` to refresh guidance.
- **Steering mid-turn.** The user interjected several times ("you can cancel open edits", "I was
  messing with the interface"); the model folded each into the running task without restarting.
- Wall-clock is dominated by builds/tests (one ~2-min gap at 22:12→22:14 polling a build), not
  by UI latency; each sky call is ~1–5 s.

## What this means for leap (applied)

The divergence that made leap feel slow and heavy was **not** a missing sub-agent. It was that
leap's `get_app_state` attached a screenshot on **every** read by default, forcing a ~110 KB
image into context each time, while Sky's default read is text-only. Changes:

- **`get_app_state` now defaults to `include_screenshot=false`** (text-only), matching Sky's
  `getAXState`. Pass `include_screenshot=true` only for a genuinely visual question. Action
  results already never attach an image. The skill and server instructions now state the
  text-first rule with the 1-in-4 calibration.
- The activity **badge still lights on any read** (capture indicator held whenever leap reads or
  drives the window, released after idle), so the "this window is being watched" feedback the
  user valued is unchanged even though most reads no longer produce an image.

Already present in leap and confirmed by the session as correct: action+state in one call
(`then_state`), reading the diff, stable indices, verifying edits by read-back rather than
trusting the action, and holding one window per session. The remaining architectural gap versus
Sky is **compaction that distils a window and drops its images** — leap relies on Claude Code's
own context management for that, which is the right layer for it.
