#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Building and starting __PROJECT_NAME__-sandbox..."
docker compose up -d --build
echo "Container started."
echo ""
echo "To start the research loop:"
echo "  docker exec __PROJECT_NAME__-sandbox tmux new -d -s research /workspace/loop.sh"
echo ""
echo "To watch it:"
echo "  docker exec -it __PROJECT_NAME__-sandbox tmux attach -t research"
echo ""
echo "To stop it:"
echo "  touch state/STOP"
