#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Bridgetone, LLC and the Leap contributors
"""Export the public tree (allowlist) of this repository to DEST and scan it for private content.

Usage: export-public.py DEST
DEST must not exist. Only tracked or explicitly listed files are copied; the scan fails (exit 1)
on any denylisted term, so review hits before publishing.
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ".gitignore", "AGENTS.md", "CONTRIBUTING.md", "SECURITY.md", "LICENSE", "README.md", "Makefile",
    "Package.swift", "Package.resolved", "bundle/Info.plist",
    "Tests/menu-bar.json", "Tests/share-indicator.json",
    "docs/configuration.md", "docs/WINDOWS-PORT.md", "docs/iterations/TEMPLATE.md",
    "docs/iterations/2026-09-30-public-release.md",
]
TREES = ["Sources", "Tests/LeapCoreTests", "skills", ".github", "scripts"]
SKIP = {"scripts/mine-codex-cua.py", "scripts/index-sky-keyboard-reference.py",
        "scripts/test-gameday-zoom.py", "scripts/export-public.py"}
DENY = re.compile(r"\bsky\b|gameday|hudl|/Users/ryan|ghidra|decompil|disassembl|ryangamerdev|"
                  r"XD249|mickey|0x10[0-9a-f]{5}", re.I)
INDEX = """# Iteration history

Each non-trivial development iteration records its rationale, evidence, implementation and
validation boundary. Use [the template](TEMPLATE.md) and follow [repository instructions](../../AGENTS.md).

- [2026-09-30 — Public open-source release preparation](2026-09-30-public-release.md)
"""


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    dest = Path(sys.argv[1]).resolve()
    if dest.exists():
        sys.exit(f"{dest} exists")
    tracked = set(subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True).split("\n"))
    paths = list(FILES)
    for tree in TREES:
        for p in sorted((ROOT / tree).rglob("*")):
            rel = p.relative_to(ROOT).as_posix()
            if p.is_file() and rel not in SKIP and "__pycache__" not in rel and p.name != ".DS_Store":
                paths.append(rel)
    for rel in paths:
        src = ROOT / rel
        if not src.is_file():
            sys.exit(f"missing: {rel}")
        if rel not in tracked:
            print(f"note: untracked file exported: {rel}")
        (dest / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest / rel)
    (dest / "docs/iterations/README.md").write_text(INDEX)
    hits = []
    for p in dest.rglob("*"):
        if p.is_file():
            text = p.read_text(errors="ignore")
            for n, line in enumerate(text.splitlines(), 1):
                if DENY.search(line):
                    hits.append(f"{p.relative_to(dest)}:{n}: {line.strip()[:120]}")
            if DENY.search(p.name):
                hits.append(f"{p.relative_to(dest)}: file name")
    print(f"exported {len(paths) + 1} files to {dest}")
    if hits:
        print("DENYLIST HITS:\n" + "\n".join(hits))
        sys.exit(1)
    print("scan clean")


if __name__ == "__main__":
    main()
