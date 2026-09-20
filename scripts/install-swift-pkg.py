#!/usr/bin/env python3
"""Install an official swift.org Xcode toolchain package into the user's home.

Bypasses swiftly (which aborts on this machine). Installs to
~/Library/Developer/Toolchains/swift-<ver>-RELEASE.xctoolchain, then verifies the
compiler runs. Prints every command, exit code, and full output; stops on failure.

Usage: install-swift-pkg.py [VERSION]   (default 6.4.0)
"""
import os
import plistlib
import subprocess
import sys
import time
import urllib.request

VERSION = sys.argv[1] if len(sys.argv) > 1 else "6.4.0"
TAG = f"swift-{VERSION}-RELEASE"
URL = f"https://download.swift.org/swift-{VERSION}-release/xcode/{TAG}/{TAG}-osx.pkg"
DOWNLOADS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "artifacts", "downloads")
os.makedirs(DOWNLOADS, exist_ok=True)
PKG = os.path.join(DOWNLOADS, f"{TAG}-osx.pkg")
TOOLCHAIN = os.path.expanduser(f"~/Library/Developer/Toolchains/{TAG}.xctoolchain")
SWIFT = os.path.join(TOOLCHAIN, "usr/bin/swift")


def banner(t):
    print("\n" + "=" * 78 + "\n" + t + "\n" + "=" * 78, flush=True)


def run(step, cmd, env=None, timeout=1800):
    banner(f"STEP: {step}")
    print("$ " + " ".join(cmd), flush=True)
    t0 = time.time()
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=env)
    print(f"exit={p.returncode}  ({time.time() - t0:.1f}s)")
    if p.stdout.strip():
        print("--- stdout ---\n" + p.stdout.rstrip())
    if p.stderr.strip():
        print("--- stderr ---\n" + p.stderr.rstrip())
    if p.returncode != 0:
        print(f"\nFAILED at step: {step}")
        sys.exit(p.returncode)
    return p


def download():
    banner(f"STEP: download {URL}")
    if os.path.exists(PKG):
        print(f"already downloaded: {PKG} ({os.path.getsize(PKG) / 1e6:.0f} MB)")
        return
    req = urllib.request.Request(URL, headers={"User-Agent": "claude-leap-installer"})
    with urllib.request.urlopen(req, timeout=120) as resp, open(PKG + ".part", "wb") as out:
        total = int(resp.headers.get("Content-Length") or 0)
        print(f"HTTP {resp.status}  content-length={total / 1e6:.0f} MB")
        done, last = 0, time.time()
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            out.write(chunk)
            done += len(chunk)
            if time.time() - last > 5:
                print(f"  {done / 1e6:.0f} / {total / 1e6:.0f} MB", flush=True)
                last = time.time()
    os.rename(PKG + ".part", PKG)
    size = os.path.getsize(PKG)
    print(f"saved {PKG} ({size / 1e6:.0f} MB)")
    if total and size != total:
        print("FAILED: size mismatch")
        sys.exit(1)


def main():
    banner(f"Preflight: {TAG}")
    print("toolchain already installed:", os.path.isdir(TOOLCHAIN))
    if not os.path.isdir(TOOLCHAIN):
        download()
        run("install toolchain package into the user home (no sudo)",
            ["installer", "-pkg", PKG, "-target", "CurrentUserHomeDirectory"])
    print("toolchain dir present:", os.path.isdir(TOOLCHAIN))
    print("swift binary present:", os.path.exists(SWIFT))
    if not os.path.exists(SWIFT):
        parent = os.path.dirname(TOOLCHAIN)
        print("contents of", parent, ":", os.listdir(parent) if os.path.isdir(parent) else "(missing)")
        sys.exit(1)

    with open(os.path.join(TOOLCHAIN, "Info.plist"), "rb") as f:
        info = plistlib.load(f)
    ident = info.get("CFBundleIdentifier")
    print("toolchain bundle identifier:", ident)

    run("swift --version (direct path)", [SWIFT, "--version"])
    env = dict(os.environ, TOOLCHAINS=str(ident))
    run("xcrun swift --version with TOOLCHAINS set", ["xcrun", "swift", "--version"], env=env)
    banner("DONE")
    print(f"Select it per-command with:  TOOLCHAINS={ident}")
    print(f"Or call it directly:         {SWIFT}")


if __name__ == "__main__":
    main()
