#!/usr/bin/env bash
set -euo pipefail

echo "=== Container Status ==="
docker inspect __PROJECT_NAME__-sandbox --format '{{.State.Status}}' 2>/dev/null || echo "Container not found"

echo ""
echo "=== Tmux Sessions ==="
docker exec __PROJECT_NAME__-sandbox tmux list-sessions 2>/dev/null || echo "No tmux sessions"

echo ""
echo "=== GPU Status ==="
docker exec __PROJECT_NAME__-sandbox nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "No GPU or cannot reach container"

echo ""
echo "=== Running Processes ==="
docker exec __PROJECT_NAME__-sandbox ps aux --sort=-rss 2>/dev/null | head -20 || echo "Cannot reach container"

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
