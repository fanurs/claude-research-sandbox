#!/usr/bin/env bash
# Kill research loop and processes. Works from host or inside the container.
set -euo pipefail

CONTAINER="__PROJECT_NAME__-sandbox"
in_container() { [ -f /.dockerenv ]; }

echo "Killing tmux sessions..."
if in_container; then
    tmux kill-server 2>/dev/null || true
else
    docker exec "$CONTAINER" tmux kill-server 2>/dev/null || true
fi

echo "Killing python and node processes..."
if in_container; then
    pkill -f python || true; pkill -f node || true; pkill -f claude || true
else
    docker exec "$CONTAINER" bash -c 'pkill -f python || true; pkill -f node || true; pkill -f claude || true' 2>/dev/null
fi

echo "Removing STOP file..."
rm -f "$(dirname "$0")/../state/STOP"

echo "Cleanup done."
if in_container; then
    echo "To restart the loop: ./scripts/start-loop.sh"
else
    echo "Container is still running."
    echo "To restart the loop: ./scripts/start-loop.sh"
fi
