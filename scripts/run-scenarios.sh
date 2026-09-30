#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Bridgetone, LLC and the Leap contributors
# Replays the interactive-tool regression scenarios (Tests/*.json) through stdio MCP.
# Harness evidence only, not native acceptance. Drives apps in the background.
#   scripts/run-scenarios.sh [scenario ...]
# LEAP_BIN selects the binary (default: the signed dist bundle, which carries the TCC grants).
# LEAP_SCENARIO_OUT selects the log directory (default: artifacts/test-runs/scenarios, ignored).
cd "$(dirname "$0")/.." || exit 2
export LEAP_BIN="${LEAP_BIN:-$PWD/dist/Leap.app/Contents/MacOS/leap}"
OUT="${LEAP_SCENARIO_OUT:-artifacts/test-runs/scenarios}"
mkdir -p "$OUT"
# Default: every Tests/*.json scenario. Scenarios drive real apps (Simulator ones need a booted device).
if [ $# -eq 0 ]; then set -- $(for f in Tests/*.json; do basename "$f" .json; done); fi
failed=0
for t in "$@"; do
  if python3 scripts/mcp-call.py script "Tests/$t.json" > "$OUT/$t.log" 2>&1; then
    echo "PASS $t"
  else
    echo "FAIL $t (see $OUT/$t.log)"; failed=1
  fi
done
exit $failed
