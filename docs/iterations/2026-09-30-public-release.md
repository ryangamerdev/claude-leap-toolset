# 2026-09-30 — Public open-source release preparation

## Outcome and evidence

Goal: publish Leap as an open, GPL-licensed project at github.com/gignit/leap-mcp so others can
use it, extend it and implement the missing Windows version.

Survey of public alternatives (GitHub API and project READMEs, 2026-09-30): several open projects
cover parts of the space. Background accessibility control on macOS exists in agent-desktop
(Apache-2.0), Cua Driver (MIT) and open-computer-use (MIT); Peekaboo (MIT) is screenshot-centric
with partial background input; Windows-MCP and microsoft/UFO target Windows; mobile-mcp,
appium-mcp and ios-simulator-mcp target mobile only. None found combines background AX control,
a durable project-local evidence store, verified multi-step workflows with separate
dispatch/verification reporting, and WebDriverAgent Simulator control in one server. This is a
point-in-time survey from READMEs, not a hands-on comparison. Commercial computer-use features
from model vendors are proprietary and tied to their accounts, which motivates an open
alternative.

## Rationale and alternatives

- History: the development history contained notes about proprietary third-party software,
  private test applications and local paths. Publishing a scrubbed tree as a single initial commit
  in a new repository was chosen over rewriting and pushing the full history.
- Scope: source, unit tests, portable scenarios, scripts, skills and user documentation are
  published. Internal research notes, trial reports, acceptance campaigns tied to a private app,
  and raw artifacts are not.
- License: GPL-3.0-or-later, so forks and derivative works remain free software.

## Changes

- Removed comparative references to a proprietary product from source comments, skills, scripts
  and documentation; comments now state the behavior and reason directly. No functional change.
- Replaced private-app examples in comments, tool descriptions and tests with generic ones.
- The scroll pixel-evidence unit test now generates its own images instead of reading private
  screenshots.
- Installer: removed cleanup of a pre-rename install and of another client's skill directory.
  `bundle.py` help shows a placeholder signing identity.
- `run-legacy-scenarios.sh` skips scenarios that are not present.
- Added LICENSE (GPL-3.0 text), SPDX headers on all Swift, Python and shell sources,
  CONTRIBUTING.md, SECURITY.md, docs/WINDOWS-PORT.md, issue/PR templates and a macOS CI workflow
  (build and unit tests). README rewritten for public users.

## Validation and delivery

- `swift build`: success. `swift test`: 69 tests, 0 failures.
- `python3 scripts/test-install-options.py`: pass.
- The public tree was produced by `scripts/export-public.py` (private repository only) and scanned
  for private names, local paths and addresses before the initial commit.
- No behavior change, so no native MCP re-verification was required; CI on GitHub-hosted macOS
  runners is untested at the time of writing.

## Remaining work

- Windows implementation (tracked in the pinned issue; guide in docs/WINDOWS-PORT.md).
- Portable desktop regression scenarios against built-in apps to replace the private-app set.
- Confirm the CI toolchain on GitHub-hosted runners satisfies the MCP Swift SDK requirement.
