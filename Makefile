# Leap developer entry points. The pinned swift.org toolchain is selected inside the scripts.
TOOLCHAINS ?= org.swift.640202609131a
export TOOLCHAINS

.PHONY: build test bundle install skills scenarios

build:
	swift build

test:
	swift test

# Rebuild and sign dist/claude-leap.app from the current source.
bundle:
	python3 scripts/bundle.py

# Build, sign, install the self-contained app, register MCP "leap" and sync skills.
# Restart the Claude Code session afterwards to load the new server.
install: bundle
	python3 scripts/install.py --no-build

skills:
	python3 scripts/install.py --skills-only

# Replay the interactive-tool regression scenarios (Tests/*.json) against the signed bundle.
# Desktop set by default; `make scenarios SET=simulator` for the Simulator set. Uses Gameday.
scenarios: bundle
	scripts/run-legacy-scenarios.sh $(SET)
