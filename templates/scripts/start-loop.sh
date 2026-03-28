#!/usr/bin/env bash
# Start the autonomous research loop. Run from the HOST.
set -euo pipefail

CONTAINER="__PROJECT_NAME__-sandbox"

# Check container is running
if ! docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null | grep -q running; then
    echo "Container $CONTAINER is not running. Run scripts/start.sh first."
    exit 1
fi

# Check if loop is already running
if docker exec "$CONTAINER" tmux has-session -t research 2>/dev/null; then
    echo "Research loop is already running."
    echo "  To watch: docker exec -it $CONTAINER tmux attach -t research"
    echo "  To stop:  touch state/STOP"
    exit 0
fi

echo "Starting research loop in $CONTAINER..."
docker exec "$CONTAINER" tmux new -d -s research /workspace/loop.sh

echo "Research loop started."
echo ""
echo "  Watch:   docker exec -it $CONTAINER tmux attach -t research"
echo "  Stop:    touch state/STOP"
echo "  Status:  ./scripts/status.sh"
echo "  Reports: ls reports/"
