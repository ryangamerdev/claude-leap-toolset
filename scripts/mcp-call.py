#!/usr/bin/env python3
"""Call claude-leap tools over stdio MCP, exactly as an agent would.

Usage:
  mcp-call.py tools                         # list tools
  mcp-call.py call NAME '{"json":"args"}'   # one call
  mcp-call.py script FILE.json              # [{"name":..., "arguments":{...}}, ...] in ONE session

Script steps besides tool calls:
  {"name": "@capture", "arguments": {"pattern": "regex with one group", "var": "x"}}  from the last result
  {"name": "@expect", "arguments": {"var": "x", "value": "..."}}
  {"name": "@absent", "arguments": {"pattern": "regex"}}                                  must NOT match the last result
  {"name": "@shell", "arguments": {"cmd": "..."}}                                   run a shell command
  a tool call with "expect_error": "regex"  must fail (isError) with matching text

Prints every request/response in full. Image content is written to /tmp/leap-shots/
and the path is printed. Exits non-zero on transport errors or isError results.
"""
import base64
import json
import os
import queue
import re
import subprocess
import sys
import threading
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLCHAIN_ID = "org.swift.640202609131a"
SHOTS = "/tmp/leap-shots"
os.makedirs(SHOTS, exist_ok=True)


def binary_path():
    # LEAP_BIN overrides the build product, e.g. to exercise dist/claude-leap.app.
    if os.environ.get("LEAP_BIN"):
        path = os.path.expanduser(os.environ["LEAP_BIN"])
        if not os.path.exists(path):
            print(f"LEAP_BIN not found: {path}")
            sys.exit(1)
        return path
    env = dict(os.environ, TOOLCHAINS=TOOLCHAIN_ID)
    p = subprocess.run(["swift", "build", "--show-bin-path"], cwd=ROOT, env=env, capture_output=True, text=True)
    if p.returncode != 0:
        print("swift build --show-bin-path failed:\n" + p.stdout + p.stderr)
        sys.exit(1)
    path = os.path.join(p.stdout.strip().splitlines()[-1], "claude-leap")
    if not os.path.exists(path):
        print(f"binary not found at {path}; run scripts/build.py first")
        sys.exit(1)
    return path


class Client:
    def __init__(self, cmd):
        print(f"$ {' '.join(cmd)}")
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  text=True, bufsize=1)
        assert self.p.stdin and self.p.stdout and self.p.stderr
        self.stdin = self.p.stdin
        self.q = queue.Queue()
        self.err = []
        threading.Thread(target=self._pump, args=(self.p.stdout, self.q.put), daemon=True).start()
        threading.Thread(target=self._pump, args=(self.p.stderr, self.err.append), daemon=True).start()
        self.next_id = 1

    @staticmethod
    def _pump(stream, sink):
        for line in stream:
            sink(line)

    def request(self, method, params=None, timeout=120):
        rid = self.next_id
        self.next_id += 1
        msg = {"jsonrpc": "2.0", "id": rid, "method": method}
        if params is not None:
            msg["params"] = params
        self.stdin.write(json.dumps(msg) + "\n")
        self.stdin.flush()
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.p.poll() is not None:
                print(f"server exited with code {self.p.returncode}\nstderr:\n{''.join(self.err)}")
                sys.exit(1)
            try:
                line = self.q.get(timeout=0.2)
            except queue.Empty:
                continue
            try:
                m = json.loads(line)
            except json.JSONDecodeError:
                print("non-JSON line from server:", line.rstrip())
                continue
            if m.get("id") == rid:
                return m
        print(f"TIMEOUT waiting for {method} after {timeout}s\nstderr:\n{''.join(self.err)}")
        self.p.kill()
        sys.exit(1)

    def notify(self, method, params=None):
        msg = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        self.stdin.write(json.dumps(msg) + "\n")
        self.stdin.flush()

    def close(self):
        self.stdin.close()
        try:
            self.p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.p.kill()
        if self.err:
            print("--- server stderr ---\n" + "".join(self.err).rstrip())


def show_result(label, m):
    if "error" in m:
        print(f"{label} → JSON-RPC ERROR: {json.dumps(m['error'], indent=2)}")
        return False
    res = m["result"]
    ok = not res.get("isError")
    print(f"{label} → {'ok' if ok else 'TOOL ERROR'}")
    for i, part in enumerate(res.get("content", [])):
        if part.get("type") == "text":
            print(part["text"])
        elif part.get("type") == "image":
            ext = "jpg" if "jpeg" in part.get("mimeType", "") else "png"
            path = os.path.join(SHOTS, f"{int(time.time())}_{label.replace(' ', '_')}_{i}.{ext}")
            with open(path, "wb") as f:
                f.write(base64.b64decode(part["data"]))
            print(f"[image {part.get('mimeType')} → {path} ({os.path.getsize(path) // 1024} KB)]")
        else:
            print(json.dumps(part)[:2000])
    return ok


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    mode = sys.argv[1]
    client = Client([binary_path()])
    init = client.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                         "clientInfo": {"name": "mcp-call", "version": "0"}})
    print("initialize →", json.dumps(init.get("result", init), indent=2)[:1500])
    client.notify("notifications/initialized")
    ok = True
    if mode == "tools":
        m = client.request("tools/list", {})
        for t in m["result"]["tools"]:
            props = list(t.get("inputSchema", {}).get("properties", {}).keys())
            print(f"- {t['name']}({', '.join(props)})\n    {t.get('description', '')}")
    elif mode == "call":
        name = sys.argv[2]
        args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
        ok = show_result(name, client.request("tools/call", {"name": name, "arguments": args}))
    elif mode == "script":
        with open(sys.argv[2]) as f:
            calls = json.load(f)
        # All calls share ONE server session, which is how Claude Code runs it — element
        # indices are only meaningful (and only stable) within a single session.
        captured, last_text = {}, ""

        def substitute(value):
            if isinstance(value, str):
                # Longest names first so "$playbook" never eats the front of "$playbook2".
                for k in sorted(captured, key=len, reverse=True):
                    v = captured[k]
                    if value == "$" + k:
                        return int(v) if v.lstrip("-").isdigit() else v
                    value = re.sub(r"\$" + re.escape(k) + r"(?![A-Za-z0-9_])", v, value)
                return value
            if isinstance(value, dict):
                return {k: substitute(v) for k, v in value.items()}
            if isinstance(value, list):
                return [substitute(v) for v in value]
            return value

        for i, c in enumerate(calls, 1):
            args = substitute(c.get("arguments", {}))
            assert isinstance(args, dict), f"arguments for {c['name']} must be an object"
            # {"name": "@capture", "arguments": {"pattern": "...", "var": "field"}} pulls a
            # value out of the previous result so later calls can reference it as "$field".
            if c["name"] == "@capture":
                pattern, var = str(args["pattern"]), str(args["var"])
                m = re.search(pattern, last_text)
                if not m:
                    print(f"@capture FAILED: /{pattern}/ not found in previous result")
                    ok = False
                    break
                captured[var] = m.group(1)
                print(f"@capture {var} = {m.group(1)!r}")
                continue
            if c["name"] == "@absent":
                # {"name": "@absent", "arguments": {"pattern": "..."}} — the previous result must NOT match.
                pattern = str(args["pattern"])
                if re.search(pattern, last_text):
                    print(f"@absent FAILED: /{pattern}/ found in previous result")
                    ok = False
                    break
                print(f"@absent ok: /{pattern}/ not present")
                continue
            if c["name"] == "@expect":
                # Compare as text: substitution may have coerced "$var" to an int.
                var, want = str(args["var"]), str(args["value"])
                got = captured.get(var)
                if got != want:
                    print(f"@expect FAILED: {var} is {got!r}, expected {want!r}")
                    ok = False
                    break
                print(f"@expect ok: {var} == {want!r}")
                continue
            if c["name"] == "@shell":
                cmd = str(args["cmd"])
                print(f"\n===== [{i}] @shell {cmd}")
                r = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                print((r.stdout + r.stderr).rstrip())
                if r.returncode != 0:
                    print(f"@shell FAILED: exit {r.returncode}")
                    ok = False
                    break
                continue
            print(f"\n===== [{i}] {c['name']} {json.dumps(args)}")
            reply = client.request("tools/call", {"name": c["name"], "arguments": args})
            last_text = "\n".join(p.get("text", "") for p in reply.get("result", {}).get("content", []))
            succeeded = show_result(f"{i} {c['name']}", reply)
            if "expect_error" in c:
                pattern = str(c["expect_error"])
                if succeeded:
                    print(f"expect_error FAILED: call succeeded, wanted an error matching /{pattern}/")
                    ok = False
                    break
                if not re.search(pattern, last_text):
                    print(f"expect_error FAILED: error text does not match /{pattern}/")
                    ok = False
                    break
                print(f"expect_error ok: /{pattern}/")
                continue
            if not succeeded:
                ok = False
                break
    else:
        print(f"unknown mode {mode}")
        ok = False
    client.close()
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
