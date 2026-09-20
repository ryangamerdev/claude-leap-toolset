#!/usr/bin/env python3
"""Install claude-leap for Claude Code the way a downloaded GitHub release would.

Usage:
  install.py            # build+sign the app if needed, then install a self-contained copy
  install.py --no-build # skip the build step (use the existing dist/ app)
  install.py --skills-only # refresh Claude and Codex skills without app/config changes
  install.py --uninstall

This does NOT symlink into the repo. It copies the signed app bundle to
  ~/Applications/claude-leap.app
and copies each skill to
  ~/.claude/skills/<name> and $CODEX_HOME/skills/<name> (default ~/.codex/skills)
then registers the MCP server at the installed path. After this the repo can be moved
or deleted and the install keeps working. Re-run to update to a newer build.

Claude Code loads MCP servers and skills at session start: restart the session afterwards.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST_APP = os.path.join(ROOT, "dist", "claude-leap.app")
DIST_SERVER = os.path.join(DIST_APP, "Contents", "MacOS", "claude-leap")

INSTALL_APP = os.path.expanduser("~/Applications/claude-leap.app")
INSTALLED_SERVER = os.path.join(INSTALL_APP, "Contents", "MacOS", "claude-leap")

SKILLS_DIR = os.path.join(ROOT, "skills")
SKILLS_DST_ROOTS = list(dict.fromkeys([os.path.expanduser("~/.claude/skills"),
    os.path.join(os.path.expanduser(os.environ.get("CODEX_HOME", "~/.codex")), "skills")]))


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


def _rm(path):
    if os.path.islink(path):
        os.unlink(path)
    elif os.path.isdir(path):
        shutil.rmtree(path)
    elif os.path.exists(path):
        os.remove(path)


def each_skill():
    """(name, repo_src, installed_dst) for every skills/<name>/ that has a SKILL.md."""
    if not os.path.isdir(SKILLS_DIR):
        return
    for name in sorted(os.listdir(SKILLS_DIR)):
        src = os.path.join(SKILLS_DIR, name)
        if os.path.isdir(src) and os.path.exists(os.path.join(src, "SKILL.md")):
            for destination in SKILLS_DST_ROOTS:
                yield name, src, os.path.join(destination, name)


def install_app():
    # `ditto` copies an app bundle preserving the code signature and extended attributes,
    # so the installed copy keeps its Developer ID identity (and therefore its TCC grants).
    os.makedirs(os.path.dirname(INSTALL_APP), exist_ok=True)
    _rm(INSTALL_APP)
    run(["ditto", DIST_APP, INSTALL_APP])
    if not os.path.exists(INSTALLED_SERVER):
        print(f"install failed: {INSTALLED_SERVER} missing after copy")
        sys.exit(1)
    print(f"app:   {INSTALL_APP}")


def install_skills():
    for destination in SKILLS_DST_ROOTS:
        os.makedirs(destination, exist_ok=True)
    for name, src, dst in each_skill():
        with open(os.path.join(src, "SKILL.md")) as f:
            assert f.read(64).startswith("---\nname: " + name), f"{name}/SKILL.md frontmatter name mismatch"
        _rm(dst)
        shutil.copytree(src, dst)
        print(f"skill: {dst}")


def main():
    args = set(sys.argv[1:])
    if "--skills-only" in args:
        if args != {"--skills-only"}:
            raise SystemExit("--skills-only cannot be combined with other options")
        install_skills()
        return
    if "--uninstall" in args:
        run(["claude", "mcp", "remove", "leap", "-s", "user"], check=False)
        _rm(INSTALL_APP)
        print(f"removed {INSTALL_APP}")
        for _name, _src, dst in each_skill():
            if os.path.exists(dst) or os.path.islink(dst):
                _rm(dst)
                print(f"removed {dst}")
        print("Uninstalled. Restart the Claude Code session.")
        return

    if "--no-build" not in args and not os.path.exists(DIST_SERVER):
        run([sys.executable, os.path.join(ROOT, "scripts", "bundle.py")])
    if not os.path.exists(DIST_SERVER):
        print(f"built app missing: {DIST_SERVER}\nrun scripts/bundle.py first (or drop --no-build)")
        sys.exit(1)

    install_app()
    install_skills()
    # Register the MCP server at the INSTALLED path (user scope, all projects).
    run(["claude", "mcp", "remove", "leap", "-s", "user"], check=False)
    run(["claude", "mcp", "add", "--scope", "user", "leap", "--", INSTALLED_SERVER])

    print("\nInstalled a self-contained copy; the repo is no longer needed at runtime.")
    print("Restart the Claude Code session so it loads the `leap` tools and the skills.")
    print('Permissions: on first use macOS lists "claude-leap" under Privacy & Security > Accessibility and > Screen Recording.')


if __name__ == "__main__":
    main()
