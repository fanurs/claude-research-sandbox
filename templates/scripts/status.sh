#!/usr/bin/env bash
# Show research loop status. Works from host or inside the container.
set -euo pipefail

CONTAINER="__PROJECT_NAME__-sandbox"
in_container() { [ -f /.dockerenv ]; }

if in_container; then
    echo "=== Running inside container ==="
else
    echo "=== Container Status ==="
    docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null || echo "Container not found"
fi

echo ""
echo "=== Tmux Sessions ==="
if in_container; then
    tmux list-sessions 2>/dev/null || echo "No tmux sessions"
else
    docker exec "$CONTAINER" tmux list-sessions 2>/dev/null || echo "No tmux sessions"
fi

echo ""
echo "=== GPU Status ==="
if in_container; then
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "No GPU"
else
    docker exec "$CONTAINER" nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "No GPU or cannot reach container"
fi

echo ""
echo "=== Running Processes ==="
if in_container; then
    ps aux --sort=-rss 2>/dev/null | head -20 || echo "Cannot list processes"
else
    docker exec "$CONTAINER" ps aux --sort=-rss 2>/dev/null | head -20 || echo "Cannot reach container"
fi

echo ""
echo "=== Stop Signal ==="
if [ -f "$(dirname "$0")/../state/STOP" ]; then
    echo "STOP file present — loop will halt after current session"
else
    echo "No STOP file — loop will continue"
fi

echo ""
echo "=== Recent Sessions ==="
ls -lt "$(dirname "$0")/../logs/"session_*.log 2>/dev/null | head -5 || echo "No session logs yet"
