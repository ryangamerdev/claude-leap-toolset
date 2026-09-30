# Leap development workflow (for coding agents and contributors)

Leap is a general-purpose, any-application computer-use MCP server. The objective is reliable
native app operation with compact observations, background-first actions and retrievable
evidence. Read README.md, CONTRIBUTING.md and, for platform work, docs/WINDOWS-PORT.md first.

## Iteration history

For every non-trivial implementation/test/install iteration, add a dated entry under
docs/iterations/ (use docs/iterations/TEMPLATE.md) and update its README index. Record:

- The user outcome and observed problem; separate evidence from hypotheses.
- Root cause or uncertainty, alternatives considered, and why the chosen change fits.
- Concrete implementation and agent-facing behavior; compatibility and tradeoffs.
- Validation commands and results, distinguishing unit tests, scripted MCP scenarios and
  verification through a real MCP client driving real apps.
- Known limitations and the next concrete test case.

Do not invent missing history or call a harness run a native pass. Correct earlier conclusions
with a new entry or a dated addendum.

## Artifacts

Keep scripts, tests and outputs inside this repository. Commit source, reusable tests, curated
evidence and small metadata. Keep runtime `.leap` stores, generated fixtures, databases, caches,
build logs, downloads and app bundles ignored and local (see .gitignore).

Preserve the MCP registration name `leap`. After installing a new build, restart the MCP client
session before testing through it; tool descriptions and skills are cached at session start.

## Skill maintenance

When tool behavior, parameters or recommended usage change, update skills/ in the same change.
Keep SKILL.md concise; put conditional detail in linked references. Describe implemented
capabilities, not aspirations. Source skills are authoritative; `python3 scripts/install.py
--skills-only` refreshes the installed copies.

## Code navigation (Swift)

Prefer semantic navigation (SourceKit-LSP, the compiler index, or equivalent tools) over text
search for Swift sources: find references and callers of a symbol before changing its behavior,
and rebuild with `swift build --enable-index-store` after large edits so the index is current.

## Style

No emojis in code, documentation, comments or logs. New source files carry the SPDX header
`GPL-3.0-or-later` used throughout the repository.
