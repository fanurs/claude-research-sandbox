#!/usr/bin/env bash
# Stop the research loop. Works from host or inside the container.
#
# Usage:
#   ./scripts/stop.sh         # stop after the current session
#   ./scripts/stop.sh 50      # stop when session count reaches 50
set -euo pipefail

STATE_DIR="$(dirname "$0")/../state"
mkdir -p "$STATE_DIR"

N="${1:-}"
if [ -z "$N" ]; then
    touch "$STATE_DIR/STOP"
    echo "Loop will stop after the current session finishes."
elif [[ "$N" =~ ^[0-9]+$ ]]; then
    echo "STOP-$N" > "$STATE_DIR/STOP"
    echo "Loop will stop once session count reaches $N."
else
    echo "error: argument must be a positive integer (got: $N)" >&2
    exit 1
fi
