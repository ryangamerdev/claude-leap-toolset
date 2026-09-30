#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Bridgetone, LLC and the Leap contributors
# Replays the interactive-tool regression scenarios (Tests/*.json) through stdio MCP.
# Harness evidence only, not native acceptance. Drives apps in the background.
#   scripts/run-legacy-scenarios.sh [scenario ...]
# LEAP_BIN selects the binary (default: the signed dist bundle, which carries the TCC grants).
# LEAP_SCENARIO_OUT selects the log directory (default: artifacts/test-runs/legacy-scenarios, ignored).
cd "$(dirname "$0")/.." || exit 2
export LEAP_BIN="${LEAP_BIN:-$PWD/dist/Leap.app/Contents/MacOS/leap}"
OUT="${LEAP_SCENARIO_OUT:-artifacts/test-runs/legacy-scenarios}"
mkdir -p "$OUT"
DESKTOP="index-stability background-keys label-targeting select-text wait-for-and-batch hidden-tab-content relaunch-guard"
SIMULATOR="ios-type-text menu-bar simulator-offscreen-press share-indicator"
if [ $# -eq 0 ]; then set -- $DESKTOP; fi
if [ "$1" = "simulator" ]; then set -- $SIMULATOR; fi
# Scenarios written against a private test app are not distributed; skip any that are absent.
present=()
for t in "$@"; do
  if [ -f "Tests/$t.json" ]; then present+=("$t"); else echo "SKIP $t (Tests/$t.json not present)"; fi
done
set -- "${present[@]}"
failed=0
for t in "$@"; do
  if python3 scripts/mcp-call.py script "Tests/$t.json" > "$OUT/$t.log" 2>&1; then
    echo "PASS $t"
  else
    echo "FAIL $t (see $OUT/$t.log)"; failed=1
  fi
done
exit $failed
