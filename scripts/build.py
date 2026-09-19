#!/usr/bin/env python3
"""Build / test claude-leap with the pinned swift.org toolchain.

Usage:
  build.py            # swift build
  build.py test       # swift test
  build.py run ARGS   # swift run claude-leap ARGS
  build.py clean      # swift package clean

Prints the full compiler output, then a compact list of errors (file:line: message)
so nothing is hidden and the failure is easy to locate.
"""
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLCHAIN_ID = "org.swift.640202609131a"  # swift-6.4.0-RELEASE
TOOLCHAIN_DIR = os.path.expanduser("~/Library/Developer/Toolchains/swift-6.4.0-RELEASE.xctoolchain")


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "build"
    extra = sys.argv[2:]
    if not os.path.isdir(TOOLCHAIN_DIR):
        print(f"toolchain missing: {TOOLCHAIN_DIR}\nrun scripts/install-swift-pkg.py first")
        sys.exit(1)
    env = dict(os.environ, TOOLCHAINS=TOOLCHAIN_ID)
    if mode == "build":
        cmd = ["swift", "build", *extra]
    elif mode == "test":
        cmd = ["swift", "test", *extra]
    elif mode == "run":
        cmd = ["swift", "run", "claude-leap", *extra]
    elif mode == "clean":
        cmd = ["swift", "package", "clean"]
    else:
        print(f"unknown mode {mode}")
        sys.exit(2)

    print(f"$ cd {ROOT} && TOOLCHAINS={TOOLCHAIN_ID} " + " ".join(cmd), flush=True)
    t0 = time.time()
    p = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True)
    out = re.sub(r"\x1b\[[0-9;]*m", "", p.stdout + p.stderr)  # strip ANSI colors
    print(out.rstrip())
    print(f"\nexit={p.returncode}  ({time.time() - t0:.1f}s)")

    errors = re.findall(r"^(.*?:\d+:\d+: error: .*)$", out, re.M)
    warnings = re.findall(r"^(.*?:\d+:\d+: warning: .*)$", out, re.M)
    if errors:
        print(f"\n{len(errors)} error(s):")
        for e in dict.fromkeys(errors):
            print("  " + e.replace(ROOT + "/", ""))
    print(f"{len(set(warnings))} unique warning(s)")
    sys.exit(p.returncode)


if __name__ == "__main__":
    main()
