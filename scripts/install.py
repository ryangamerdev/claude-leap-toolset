#!/usr/bin/env python3
"""Install claude-leap for Claude Code: the MCP server (user scope) and the skill.

Usage:
  install.py            # build+sign the bundle if missing, register `leap`, install the skill
  install.py --no-build # skip the bundle step
  install.py --uninstall

The skill is symlinked (not copied) into ~/.claude/skills/claude-leap so a `git pull` updates it.
Claude Code loads new MCP tools and skills at session start: restart the session afterwards.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, "dist", "claude-leap.app", "Contents", "MacOS", "claude-leap")
SKILL_SRC = os.path.join(ROOT, "skills", "claude-leap")
SKILL_DST = os.path.expanduser("~/.claude/skills/claude-leap")


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
        if os.path.islink(SKILL_DST) or os.path.isdir(SKILL_DST):
            if os.path.islink(SKILL_DST):
                os.unlink(SKILL_DST)
            else:
                shutil.rmtree(SKILL_DST)
            print(f"removed {SKILL_DST}")
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
    # Skill.
    os.makedirs(os.path.dirname(SKILL_DST), exist_ok=True)
    if os.path.islink(SKILL_DST) or os.path.exists(SKILL_DST):
        if os.path.islink(SKILL_DST):
            os.unlink(SKILL_DST)
        else:
            shutil.rmtree(SKILL_DST)
    os.symlink(SKILL_SRC, SKILL_DST)
    print(f"skill: {SKILL_DST} -> {SKILL_SRC}")
    with open(os.path.join(SKILL_SRC, "SKILL.md")) as f:
        head = f.read(400)
    assert head.startswith("---\nname: claude-leap"), "SKILL.md frontmatter missing"
    print("\nInstalled. Restart the Claude Code session so it loads the `leap` tools and the claude-leap skill.")
    print("Permissions: on first use macOS lists \"claude-leap\" under Privacy & Security › Accessibility and › Screen Recording.")


if __name__ == "__main__":
    main()
