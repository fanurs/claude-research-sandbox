#!/usr/bin/env bash
set -euo pipefail

echo "Killing tmux sessions..."
docker exec __PROJECT_NAME__-sandbox tmux kill-server 2>/dev/null || true

echo "Killing python and node processes..."
docker exec __PROJECT_NAME__-sandbox bash -c 'pkill -f python || true; pkill -f node || true; pkill -f claude || true' 2>/dev/null

echo "Removing STOP file..."
rm -f "$(dirname "$0")/../state/STOP"

echo "Cleanup done. Container is still running."
echo "To restart the loop: docker exec __PROJECT_NAME__-sandbox tmux new -d -s research /workspace/loop.sh"
