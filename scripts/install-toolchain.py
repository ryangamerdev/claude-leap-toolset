#!/usr/bin/env python3
"""Install swiftly (official swift.org package) and a Swift toolchain, step by step.

Every step prints the exact command, its exit code, and its full stdout/stderr.
The script stops at the first failing step so the failure is never hidden.

Usage: install-toolchain.py [SWIFT_VERSION]   (default: 6.4.0)
"""
import os
import shutil
import subprocess
import sys
import time
import urllib.request

SWIFT_VERSION = sys.argv[1] if len(sys.argv) > 1 else "6.4.0"
HOME = os.path.expanduser("~")
SWIFTLY_HOME = os.path.join(HOME, ".swiftly")
SWIFTLY_BIN = os.path.join(SWIFTLY_HOME, "bin")
SWIFTLY = os.path.join(SWIFTLY_BIN, "swiftly")
PKG_URL = "https://download.swift.org/swiftly/darwin/swiftly.pkg"
DOWNLOADS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "artifacts", "downloads")
os.makedirs(DOWNLOADS, exist_ok=True)
PKG_PATH = os.path.join(DOWNLOADS, "swiftly.pkg")
STALE_LOCK = "/opt/homebrew/var/homebrew/locks/swiftly.formula.lock"

ENV = dict(os.environ)
ENV["SWIFTLY_HOME_DIR"] = SWIFTLY_HOME
ENV["SWIFTLY_BIN_DIR"] = SWIFTLY_BIN
ENV["PATH"] = SWIFTLY_BIN + ":" + ENV.get("PATH", "")


def banner(title):
    print("\n" + "=" * 78)
    print(title)
    print("=" * 78, flush=True)


def run(step, cmd, check=True, timeout=1800):
    banner(f"STEP: {step}")
    print("$ " + " ".join(cmd), flush=True)
    start = time.time()
    try:
        p = subprocess.run(cmd, env=ENV, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        print(f"TIMEOUT after {timeout}s")
        for label, chunk in (("stdout", e.stdout), ("stderr", e.stderr)):
            text = chunk.decode(errors="replace") if isinstance(chunk, bytes) else (chunk or "")
            print(f"{label}:\n{text}")
        sys.exit(1)
    elapsed = time.time() - start
    print(f"exit={p.returncode}  ({elapsed:.1f}s)")
    if p.stdout.strip():
        print("--- stdout ---\n" + p.stdout.rstrip())
    if p.stderr.strip():
        print("--- stderr ---\n" + p.stderr.rstrip())
    if check and p.returncode != 0:
        print(f"\nFAILED at step: {step}")
        sys.exit(p.returncode or 1)
    return p


def main():
    banner(f"Preflight (want Swift {SWIFT_VERSION})")
    print(f"swiftly already at {SWIFTLY}: {os.path.exists(SWIFTLY)}")
    if os.path.exists(STALE_LOCK):
        brew_running = subprocess.run(["pgrep", "-f", "brew.rb install"], capture_output=True, text=True)
        if brew_running.stdout.strip():
            print(f"A brew install is still running (pids {brew_running.stdout.split()}); not touching the lock.")
            sys.exit(1)
        os.remove(STALE_LOCK)
        print(f"removed stale Homebrew lock {STALE_LOCK}")

    if not os.path.exists(SWIFTLY):
        banner(f"STEP: download {PKG_URL}")
        req = urllib.request.Request(PKG_URL, headers={"User-Agent": "claude-leap-installer"})
        with urllib.request.urlopen(req, timeout=120) as resp, open(PKG_PATH, "wb") as out:
            print(f"HTTP {resp.status}  content-length={resp.headers.get('Content-Length')}")
            shutil.copyfileobj(resp, out)
        size = os.path.getsize(PKG_PATH)
        print(f"saved {PKG_PATH} ({size / 1e6:.1f} MB)")
        if size < 1_000_000:
            print("FAILED: package is suspiciously small")
            sys.exit(1)

        run("install swiftly.pkg into the user home (no sudo)",
            ["installer", "-pkg", PKG_PATH, "-target", "CurrentUserHomeDirectory"])
        print("swiftly binary present:", os.path.exists(SWIFTLY))
        if not os.path.exists(SWIFTLY):
            print("FAILED: installer succeeded but", SWIFTLY, "is missing")
            sys.exit(1)

    if not os.path.exists(os.path.join(SWIFTLY_HOME, "config.json")):
        run("swiftly init (no shell-profile edits, no toolchain yet)",
            [SWIFTLY, "init", "--assume-yes", "--no-modify-profile", "--skip-install"])
    run("swiftly version", [SWIFTLY, "--version"])
    run(f"swiftly install {SWIFT_VERSION} --use",
        [SWIFTLY, "install", SWIFT_VERSION, "--use", "--assume-yes"], timeout=3600)
    run("swiftly list", [SWIFTLY, "list"])
    run("swift --version via swiftly", [os.path.join(SWIFTLY_BIN, "swift"), "--version"])
    banner("DONE")
    print(f"Use it with: source {SWIFTLY_HOME}/env.sh   (or PATH={SWIFTLY_BIN}:$PATH)")


if __name__ == "__main__":
    main()
