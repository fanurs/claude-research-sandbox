#!/usr/bin/env bash
# Start the autonomous research loop. Works from host or inside the container.
set -euo pipefail

CONTAINER="__PROJECT_NAME__-sandbox"
in_container() { [ -f /.dockerenv ]; }

if in_container; then
    # Inside container — run tmux directly
    if tmux has-session -t research 2>/dev/null; then
        echo "Research loop is already running."
        echo "  To watch: tmux attach -t research"
        echo "  To stop:  touch /workspace/state/STOP"
        exit 0
    fi

    echo "Starting research loop..."
    tmux new -d -s research /workspace/loop.sh

    echo "Research loop started."
    echo ""
    echo "  Watch:   tmux attach -t research"
    echo "  Stop:    touch /workspace/state/STOP"
    echo "  Status:  ./scripts/status.sh"
    echo "  Reports: ls reports/"
else
    # On host — run via docker exec
    if ! docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null | grep -q running; then
        echo "Container $CONTAINER is not running. Run scripts/start.sh first."
        exit 1
    fi

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
fi
