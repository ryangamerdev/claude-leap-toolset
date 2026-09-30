# Contributing to Leap

Thanks for helping. Leap aims to be a reliable, open, model-agnostic way for AI agents to
operate native applications. Issues, discussions and pull requests are welcome.

## Where help is most needed

- **Windows support.** See [docs/WINDOWS-PORT.md](docs/WINDOWS-PORT.md) and the pinned
  "Windows support" issue. Comment there before starting so work can be split.
- **Linux support** (AT-SPI), following the same contract.
- **Portable regression scenarios** against apps every user has (TextEdit, Calculator, Finder,
  Notepad), in `Tests/*.json`.
- **App compatibility reports**: an app whose tree is incomplete or whose controls ignore
  background input, with the `get_app_state` output and `diagnostic_query` results.

## Development setup (macOS)

```bash
python3 scripts/build.py          # build
python3 scripts/build.py test     # unit tests
python3 scripts/bundle.py         # signed dist/Leap.app
python3 scripts/install.py        # install app, skills and MCP registration for Claude Code
```

Restart your MCP client after installing a new build so it loads the new server and skills.

## Pull requests

- Keep changes focused; describe the user-visible behavior and how you verified it.
- Distinguish unit tests, scripted MCP scenarios and manual verification with a real MCP client.
- If tool behavior, parameters or recommended usage change, update `skills/` in the same PR and
  keep `SKILL.md` concise (conditional detail goes in `references/`).
- Add an entry under `docs/iterations/` for non-trivial changes (see the template).
- Do not commit runtime stores (`.leap/`), build outputs, logs, downloads or app bundles; they
  are ignored. Keep evidence you want reviewed small and curated.
- New source files carry the SPDX header used throughout the repo.

## License of contributions

Leap is licensed under GPL-3.0-or-later. By submitting a contribution you agree that it is
licensed under the same terms. Add a `Signed-off-by` line (`git commit -s`) to certify the
[Developer Certificate of Origin](https://developercertificate.org/).

## Conduct

Be respectful and constructive. Harassment or personal attacks are not tolerated; maintainers
may remove content or contributors that violate this.
