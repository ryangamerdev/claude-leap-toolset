# 2026-09-30 — Rename claude-leap to Leap

## Outcome

User direction: the product is called **leap** (repo folder `leap-mcp`). Choices confirmed by
question: product `leap`, change the bundle id, rename the GitHub repo.

## Changes

- App `Leap.app`, executable `leap`, bundle id `com.bridgetone.leap` (was `claude-leap.app`,
  `com.bridgetone.claude-leap`). Swift target/source dir `Sources/leap`. The MCP registration name
  `leap` is unchanged.
- Skill `skills/leap` (was `skills/claude-leap`); cross-references in the xcode,
  leap-3d-game-workflows and app-store-screenshots skills updated.
- The installer installs `~/Applications/Leap.app` and removes the pre-rename app and skill copies
  (Claude and Codex) on install, `--skills-only` and `--uninstall`.
- GitHub: `ryangamerdev/claude-leap-toolset` renamed to `ryangamerdev/leap-mcp` (gh); remote updated.
- Host configs: Claude re-registered by the installer; OpenCode `leap.command` points at the new
  binary (backup `opencode.json.bak-before-leap-rename`); the Codex project-trust entry moved from
  `/Users/ryan/src/claude-leap` to `/Users/ryan/src/leap-mcp` (Leap is still not registered in Codex).
- Removed the pre-rename build directory `.build/arm64-apple-macosx` (index with the old paths).
- History (iterations, research, artifacts, review docs) keeps the old name as written at the time.

## Tradeoff

A new bundle id is a new TCC identity: Accessibility and Screen Recording must be granted to
"Leap" once. The old "claude-leap" entries in System Settings can be removed.

## Validation

`make test` 69/69; the release bundle signs as `com.bridgetone.leap`; `claude mcp get leap` and
`opencode mcp list` report the new binary connected. Native tool use awaits the restart and the
permission grant.
