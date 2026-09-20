#!/usr/bin/env python3
"""Install claude-leap for Claude Code: the MCP server (user scope) and the skill.

Usage:
  install.py            # build+sign the bundle if missing, register `leap`, install the skill
  install.py --no-build # skip the bundle step
  install.py --uninstall

Each skill under skills/ is symlinked (not copied) into ~/.claude/skills/ so a `git pull` updates it.
Claude Code loads new MCP tools and skills at session start: restart the session afterwards.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, "dist", "claude-leap.app", "Contents", "MacOS", "claude-leap")
SKILLS_DIR = os.path.join(ROOT, "skills")
SKILLS_DST_ROOT = os.path.expanduser("~/.claude/skills")


def _unlink(dst):
    if os.path.islink(dst):
        os.unlink(dst)
    elif os.path.isdir(dst):
        shutil.rmtree(dst)
    elif os.path.exists(dst):
        os.remove(dst)


def each_skill():
    for name in sorted(os.listdir(SKILLS_DIR)):
        src = os.path.join(SKILLS_DIR, name)
        if os.path.isdir(src) and os.path.exists(os.path.join(src, "SKILL.md")):
            yield name, src, os.path.join(SKILLS_DST_ROOT, name)


def link_skills():
    os.makedirs(SKILLS_DST_ROOT, exist_ok=True)
    for name, src, dst in each_skill():
        _unlink(dst)
        os.symlink(src, dst)
        with open(os.path.join(src, "SKILL.md")) as f:
            assert f.read(64).startswith("---\nname: " + name), f"{name}/SKILL.md frontmatter name mismatch"
        print(f"skill: {dst} -> {src}")


def run(cmd, check=True):
    print("$ " + " ".join(cmd))
    p = subprocess.run(cmd, capture_output=True, text=True)
    out = (p.stdout + p.stderr).strip()
    if out:
        print(out)
    if check and p.returncode != 0:
        print(f"FAILED (exit {p.returncode})")
        sys.exit(1)
    return p


def main():
    args = set(sys.argv[1:])
    if "--uninstall" in args:
        run(["claude", "mcp", "remove", "leap", "-s", "user"], check=False)
        for name, _src, dst in each_skill():
            if os.path.islink(dst) or os.path.exists(dst):
                _unlink(dst)
                print(f"removed {dst}")
        print("Uninstalled. Restart the Claude Code session.")
        return
    if "--no-build" not in args and not os.path.exists(SERVER):
        run([sys.executable, os.path.join(ROOT, "scripts", "bundle.py")])
    if not os.path.exists(SERVER):
        print(f"server missing: {SERVER}")
        sys.exit(1)
    # MCP server, user scope (all projects). Re-adding is how you repoint it.
    run(["claude", "mcp", "remove", "leap", "-s", "user"], check=False)
    run(["claude", "mcp", "add", "--scope", "user", "leap", "--", SERVER])
    # Skills: symlink every skills/<name>/ so a git pull updates them.
    link_skills()
    print("\nInstalled. Restart the Claude Code session so it loads the `leap` tools and the skills.")
    print("Permissions: on first use macOS lists \"claude-leap\" under Privacy & Security › Accessibility and › Screen Recording.")


if __name__ == "__main__":
    main()
