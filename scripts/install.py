#!/usr/bin/env python3
"""Install leap for Claude Code the way a downloaded GitHub release would.

Usage:
  install.py            # build+sign the app if needed, then install a self-contained copy
  install.py --no-build # skip the build step (use the existing dist/ app)
  install.py --skills-only # refresh Claude skills without app/config changes
  install.py --uninstall

This does NOT symlink into the repo. It copies the signed app bundle to
  ~/Applications/Leap.app
and copies each skill to
  ~/.claude/skills/<name>
(not Codex: Codex uses its own computer-use service, and Leap is not registered there; a stale
Leap skill copy under $CODEX_HOME/skills is removed)
then registers the MCP server at the installed path. After this the repo can be moved
or deleted and the install keeps working. Re-run to update to a newer build.

Claude Code loads MCP servers and skills at session start: restart the session afterwards.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST_APP = os.path.join(ROOT, "dist", "Leap.app")
DIST_SERVER = os.path.join(DIST_APP, "Contents", "MacOS", "leap")

INSTALL_APP = os.path.expanduser("~/Applications/Leap.app")
INSTALLED_SERVER = os.path.join(INSTALL_APP, "Contents", "MacOS", "leap")

SKILLS_DIR = os.path.join(ROOT, "skills")
SKILLS_DST_ROOTS = [os.path.expanduser("~/.claude/skills")]
# Leap stays out of Codex (user direction 2026-09-30); earlier installs copied skills there.
CODEX_SKILLS = os.path.join(os.path.expanduser(os.environ.get("CODEX_HOME", "~/.codex")), "skills")


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


# Pre-rename installs (product "claude-leap", bundle com.bridgetone.claude-leap); removed on install.
LEGACY_APP = os.path.expanduser("~/Applications/claude-leap.app")
LEGACY_SKILLS = ["claude-leap"]


def remove_legacy():
    """Remove the pre-rename app bundle and skill copies (Claude and Codex)."""
    if os.path.lexists(LEGACY_APP):
        _rm(LEGACY_APP)
        print(f"removed pre-rename app: {LEGACY_APP}")
    for root in SKILLS_DST_ROOTS + [CODEX_SKILLS]:
        for name in LEGACY_SKILLS:
            stale = os.path.join(root, name)
            if os.path.lexists(stale):
                _rm(stale)
                print(f"removed pre-rename skill: {stale}")


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
    remove_codex_skills()


def remove_codex_skills():
    """Delete copies of this repo's skills that earlier installs put under Codex."""
    if not os.path.isdir(SKILLS_DIR):
        return
    for name in sorted(os.listdir(SKILLS_DIR)):
        stale = os.path.join(CODEX_SKILLS, name)
        if os.path.exists(os.path.join(SKILLS_DIR, name, "SKILL.md")) and os.path.lexists(stale):
            _rm(stale)
            print(f"removed Codex skill copy: {stale}")


def install_config():
    """Create defaults once; never overwrite the user's settings."""
    directory = os.path.expanduser("~/.config/leap")
    os.makedirs(directory, mode=0o700, exist_ok=True)
    path = os.path.join(directory, "leap.json")
    try:
        with open(path, "x") as stream:
            json.dump({"logging": {"level": "info"}}, stream, indent=2)
            stream.write("\n")
        os.chmod(path, 0o600)
        print(f"config: {path}")
    except FileExistsError:
        print(f"config preserved: {path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--no-build", action="store_true", help="Install the existing dist bundle")
    mode.add_argument("--skills-only", action="store_true", help="Refresh skills without app/config changes")
    mode.add_argument("--uninstall", action="store_true", help="Remove the app, registration and skills")
    parsed = parser.parse_args()
    args = {"--" + name.replace("_", "-") for name, enabled in vars(parsed).items() if enabled}
    if "--skills-only" in args:
        if args != {"--skills-only"}:
            raise SystemExit("--skills-only cannot be combined with other options")
        install_skills()
        remove_legacy()
        return
    if "--uninstall" in args:
        run(["claude", "mcp", "remove", "leap", "-s", "user"], check=False)
        _rm(INSTALL_APP)
        print(f"removed {INSTALL_APP}")
        for _name, _src, dst in each_skill():
            if os.path.exists(dst) or os.path.islink(dst):
                _rm(dst)
                print(f"removed {dst}")
        remove_codex_skills()
        remove_legacy()
        print("Uninstalled. Restart the Claude Code session.")
        return

    if "--no-build" not in args and not os.path.exists(DIST_SERVER):
        run([sys.executable, os.path.join(ROOT, "scripts", "bundle.py")])
    if not os.path.exists(DIST_SERVER):
        print(f"built app missing: {DIST_SERVER}\nrun scripts/bundle.py first (or drop --no-build)")
        sys.exit(1)

    install_app()
    install_skills()
    remove_legacy()
    install_config()
    # Register the MCP server at the INSTALLED path (user scope, all projects).
    run(["claude", "mcp", "remove", "leap", "-s", "user"], check=False)
    run(["claude", "mcp", "add", "--scope", "user", "leap", "--", INSTALLED_SERVER])
    # Ask for Leap's own grants now, as "Leap" (not the terminal): Accessibility prompt, and
    # System Settings opened at Screen Recording with the request made while it is visible
    # (Sky's approach). No-op when both are already granted.
    run([INSTALLED_SERVER, "--request-permissions"], check=False)

    print("\nInstalled a self-contained copy; the repo is no longer needed at runtime.")
    print("Restart the Claude Code session so it loads the `leap` tools and the skills.")
    print('Permissions: turn on "Leap" under Privacy & Security > Accessibility and > Screen & System Audio Recording.')
    print('If Leap is missing from Screen Recording, click + and choose ~/Applications/Leap.app. Restart the host afterwards.')


if __name__ == "__main__":
    main()
