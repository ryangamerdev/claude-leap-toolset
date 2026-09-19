#!/usr/bin/env python3
"""Build dist/claude-leap.app: a signed bundle with its own TCC identity.

Why a bundle: macOS shows permission entries by bundle name and keys grants to the code
signature's designated requirement. Signed with a Developer ID, "claude-leap" appears in
System Settings under its own name and the grant survives rebuilds. The binary re-execs
itself with responsibility_spawnattrs_setdisclaim (Disclaim.swift) so TCC attributes
requests to this bundle instead of to Claude Code.

Usage:
  bundle.py                       # release build, sign with the first "Developer ID Application"
  bundle.py --identity "Developer ID Application: BRIDGETONE, LLC (XD249KVG74)"
  bundle.py --identity -          # ad-hoc (grant will NOT survive rebuilds)
  bundle.py --debug               # use the debug build instead of release

Prints every command, exit code and full output; stops at the first failure.
"""
import argparse
import os
import plistlib
import re
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLCHAIN_ID = "org.swift.640202609131a"
DIST = os.path.join(ROOT, "dist")
APP = os.path.join(DIST, "claude-leap.app")

ap = argparse.ArgumentParser()
ap.add_argument("--identity", help='codesign identity; "-" for ad-hoc')
ap.add_argument("--debug", action="store_true")
args = ap.parse_args()


def run(step, cmd, env=None, check=True):
    print("\n" + "=" * 78 + f"\nSTEP: {step}\n" + "=" * 78)
    print("$ " + " ".join(cmd), flush=True)
    t0 = time.time()
    p = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True)
    out = re.sub(r"\x1b\[[0-9;]*m", "", p.stdout + p.stderr).rstrip()
    print(f"exit={p.returncode}  ({time.time() - t0:.1f}s)")
    if out:
        print(out)
    if check and p.returncode != 0:
        print(f"\nFAILED at step: {step}")
        sys.exit(p.returncode)
    return p


env = dict(os.environ, TOOLCHAINS=TOOLCHAIN_ID)
config = "debug" if args.debug else "release"
run(f"swift build -c {config}", ["swift", "build", "-c", config], env=env)
bin_dir = run("locate build products", ["swift", "build", "-c", config, "--show-bin-path"], env=env).stdout.strip().splitlines()[-1]
binary = os.path.join(bin_dir, "claude-leap")
if not os.path.exists(binary):
    print(f"binary missing: {binary}")
    sys.exit(1)

print("\n" + "=" * 78 + "\nSTEP: assemble bundle\n" + "=" * 78)
if os.path.isdir(APP):
    shutil.rmtree(APP)
os.makedirs(os.path.join(APP, "Contents", "MacOS"))
os.makedirs(os.path.join(APP, "Contents", "Resources"))
shutil.copy2(binary, os.path.join(APP, "Contents", "MacOS", "claude-leap"))
shutil.copy2(os.path.join(ROOT, "bundle", "Info.plist"), os.path.join(APP, "Contents", "Info.plist"))
with open(os.path.join(APP, "Contents", "PkgInfo"), "w") as f:
    f.write("APPL????")
with open(os.path.join(APP, "Contents", "Info.plist"), "rb") as f:
    info = plistlib.load(f)
print(f"bundle id: {info['CFBundleIdentifier']}  name: {info['CFBundleName']}  exe: {info['CFBundleExecutable']}")
print(f"binary: {os.path.getsize(binary) / 1e6:.1f} MB from {binary}")

identity = args.identity
if not identity:
    ids = run("list code-signing identities", ["security", "find-identity", "-v", "-p", "codesigning"]).stdout
    m = re.search(r'"(Developer ID Application: [^"]+)"', ids) or re.search(r'"(Apple Development: [^"]+)"', ids)
    if not m:
        print("no signing identity found; pass --identity or --identity - for ad-hoc")
        sys.exit(1)
    identity = m.group(1)
print(f"signing identity: {identity}")

run("codesign", ["codesign", "--force", "--deep", "--options", "runtime", "--timestamp=none",
                 "--identifier", info["CFBundleIdentifier"], "--sign", identity, APP])
run("verify signature", ["codesign", "--verify", "--deep", "--strict", "--verbose=2", APP])
run("show signature", ["codesign", "-dv", "--verbose=2", APP])

print("\n" + "=" * 78 + "\nDONE\n" + "=" * 78)
print(f"app:    {APP}")
print(f"server: {APP}/Contents/MacOS/claude-leap")
print("Point Claude Code's MCP config at the server path above. On first use, macOS will list")
print(f"\"{info['CFBundleName']}\" in Privacy & Security › Accessibility (and › Screen Recording).")
