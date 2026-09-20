# 2026-09-20 — Keep installed guidance synchronized with Leap

## Outcome and evidence

The user pointed out that restarted agents read the installed skill and could follow stale
instructions while Leap changes. Inspection found the standard installer copied skills only
to Claude, while recent development app-swap scripts did not copy skills at all. The existing
Claude-Leap entrypoint had 181 lines, including details irrelevant to most calls.

## Rationale and alternatives

Keep the skill installed: its non-obvious targeting, uncertainty and evidence rules prevent
mistakes. Removing it until development ends would discard useful guidance without fixing
delivery. A repository symlink would avoid copying but break the self-contained installation
contract. Instead use a concise maintained entrypoint, conditional reference material and
an explicit synchronization path shared by normal and development installs.

Live tool schemas define available arguments; the skill explains usage. Development status
belongs in FEATURES and the continuation handoff, not in an assertion that every implemented
capability is proven. Pending action deltas and interaction timelines are clearly identified.

## Changes

- Rewrote skills/claude-leap/SKILL.md as compact observation/action/evidence guidance. Moved
  text editing, menus, coordinates, screenshot and Simulator details into references/ui-details.md.
- Removed duplicated general approval policy and repeated workflow advice; retained uncertainty,
  freshness, coordinate-space and partial-capture rules. Clarified content-keyed target limits.
- Added scripts/install.py --skills-only, which copies repository skills to Claude and Codex
  (honoring CODEX_HOME) without replacing the app or changing MCP registrations. Normal install
  and uninstall now use both skill destinations. Repository-shipped companion skills are also
  synchronized by the existing all-skills loop.
- Added an explicit synchronization step to the current development installation script.
  AGENTS.md requires source skill updates when behavior changes, synchronization on each
  development install and source/installed comparison before handoff. Historical installer
  artifacts are retained as history rather than rewritten wholesale.

## Validation and delivery

Ran the new skills-only command successfully. The skill-creator validator accepted the
frontmatter and structure. Python AST parsing passed for both changed install scripts.
Byte comparisons of the Leap entrypoint and reference verified both installed copies match
source; [hash evidence](../../artifacts/test-runs/20260920-skill-sync/validation.json).
`git diff --check` passed. No binary rebuild or UI test was required for this guidance change.

The installed binary remains `2ff924fb96fddfe1451953c59b81af6ec808e195833a0ed2da8ce0df7832cdd3`.
Its batch-recovery native acceptance still awaits the previously requested restart. No new
restart cycle is introduced by this skill update; the next restart refreshes both together.

## Remaining work

Every future change to usage must update source guidance and synchronize it; copying alone
cannot guarantee semantic correctness. Do not mark timeline/action-scoped deltas available
until their tools are implemented. Next native case remains iPad AXSubrole batch recovery.
