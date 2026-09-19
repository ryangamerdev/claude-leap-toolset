#!/usr/bin/env python3
"""Read-only miner: how did Codex actually use computer-use / browser tools in a thread?

Scans ~/.codex/sessions and archived_sessions rollout files for a thread id, pairs
MCP tool calls with results, and reports:
  * call counts per (server, tool)
  * every cua_repl `js` call: the code Codex wrote and the (truncated-by-us, but
    length-reported) result text, so the real usage pattern is visible.

Usage: mine-codex-cua.py THREAD_ID [--samples N] [--result-chars N] [--server NAME]
"""
import argparse
import json
import os
from collections import Counter
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("thread_id")
ap.add_argument("--home", default=os.environ.get("CODEX_HOME", str(Path.home() / ".codex")))
ap.add_argument("--samples", type=int, default=25, help="how many js calls to print in full")
ap.add_argument("--result-chars", type=int, default=1200, help="result text shown per call")
ap.add_argument("--server", default="cua_repl", help="MCP server whose calls to print")
ap.add_argument("--stats", action="store_true",
                help="aggregate view instead of samples: API methods used, apps targeted, failure taxonomy")
args = ap.parse_args()

root = Path(args.home).expanduser()
paths = sorted(p for folder in ("sessions", "archived_sessions")
               for p in (root / folder).rglob("*.jsonl") if args.thread_id in p.name)
print(f"rollout files: {len(paths)}")
for p in paths:
    print(f"  {p}  ({p.stat().st_size / 1e6:.1f} MB)")
if not paths:
    raise SystemExit("no files matched")


def text_of(value):
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(text_of(v) for v in value)
    if isinstance(value, dict):
        return value.get("text") or value.get("Text") or json.dumps(value)[:400]
    return ""


counts = Counter()
statuses = Counter()
records = []  # (timestamp, server, tool, arguments, result_text, status, duration)
bad_lines = 0
total = 0
for path in paths:
    with path.open(encoding="utf-8") as fh:
        for line in fh:
            total += 1
            try:
                rec = json.loads(line)
            except ValueError:
                bad_lines += 1
                continue
            if rec.get("type") != "event_msg":
                continue
            p = rec.get("payload") or {}
            if p.get("type") != "item_completed":
                continue
            item = p.get("item") or {}
            if item.get("type") != "McpToolCall":
                continue
            server, tool = item.get("server"), item.get("tool")
            counts[(server, tool)] += 1
            statuses[(server, item.get("status"))] += 1
            result = item.get("result") or {}
            content = result.get("content") if isinstance(result, dict) else result
            images = sum(1 for c in (content or []) if isinstance(c, dict) and c.get("type") == "image")
            records.append((rec.get("timestamp"), server, tool, item.get("arguments"),
                            text_of(content), item.get("status"), item.get("duration"), images))

print(f"\nscanned {total} records ({bad_lines} unparseable lines)")
print("\n## MCP tool calls by (server, tool)")
for (server, tool), n in counts.most_common():
    print(f"  {n:5d}  {server}.{tool}")
print("\n## status by server")
for (server, status), n in sorted(statuses.items(), key=lambda kv: -kv[1]):
    print(f"  {n:5d}  {server}: {status}")

sel = [r for r in records if r[1] == args.server]
print(f"\n## {args.server} calls: {len(sel)} total, {sum(r[7] for r in sel)} image results")

if args.stats:
    import re
    methods = Counter()
    apps = Counter()
    per_call_actions = Counter()
    failures = Counter()
    failure_samples = {}
    for ts, server, tool, arguments, result_text, status, duration, images in sel:
        code = arguments.get("code", "") if isinstance(arguments, dict) else str(arguments)
        names = re.findall(r"\.(getAXState|getScreenshot|getAXStateAndScreenshot|click|typeText|setValue|pressKey|scroll|drag|paste|selectText|performSecondaryAction|getApp|listApps|getState|createBrowserTab|getTab|goto)\(", code)
        methods.update(names)
        per_call_actions[len([n for n in names if n not in ("getAXState", "getScreenshot", "getAXStateAndScreenshot", "getApp", "listApps", "getState")])] += 1
        apps.update(re.findall(r"getApp\(\s*[\"']([^\"']+)[\"']", code))
        if status != "completed":
            first = result_text.strip().splitlines()[0][:110] if result_text.strip() else "(empty)"
            key = re.sub(r"\d+", "N", first)
            key = re.sub(r"[\"'][^\"']*[\"']", "'…'", key)
            failures[key] += 1
            failure_samples.setdefault(key, (ts, code[:160]))
    print("\n## API methods called (occurrences in code)")
    for m, n in methods.most_common():
        print(f"  {n:5d}  {m}")
    print("\n## actions per call (0 = observe only) → how much it batches")
    for k in sorted(per_call_actions):
        print(f"  {per_call_actions[k]:5d} calls with {k} action(s)")
    print("\n## apps targeted via getApp")
    for a_, n in apps.most_common():
        print(f"  {n:5d}  {a_}")
    print(f"\n## failure taxonomy ({sum(failures.values())} failed calls)")
    for k, n in failures.most_common():
        ts, code = failure_samples[k]
        print(f"  {n:4d}  {k}\n        e.g. {ts}  {code}")
    raise SystemExit(0)
shown = 0
for ts, server, tool, arguments, result_text, status, duration, images in sel:
    if shown >= args.samples:
        break
    shown += 1
    code = arguments.get("code") if isinstance(arguments, dict) else arguments
    title = arguments.get("title") if isinstance(arguments, dict) else None
    print("\n" + "-" * 78)
    print(f"{ts}  {server}.{tool}  status={status}  duration={duration}  images={images}  title={title!r}")
    print("--- code ---")
    print(code if isinstance(code, str) else json.dumps(code, indent=1))
    print(f"--- result ({len(result_text)} chars) ---")
    print(result_text[: args.result_chars] + ("\n…[truncated by miner]" if len(result_text) > args.result_chars else ""))
print(f"\nshowed {shown} of {len(sel)} {args.server} calls (use --samples to see more)")
