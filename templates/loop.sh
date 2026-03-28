#!/usr/bin/env bash
# Main research loop. Runs INSIDE the container (in tmux).
# Chains Claude sessions until state/STOP file appears.
#
# To start:  tmux new -d -s research '/workspace/loop.sh'
# To watch:  tmux attach -t research
# To stop:   touch /workspace/state/STOP
# To detach: Ctrl+B then D
set -euo pipefail

WORKSPACE="/workspace"
LOOP_LOG="${WORKSPACE}/logs/loop.log"

# Ensure runtime dirs exist
mkdir -p "${WORKSPACE}"/{state,logs,notes,results,checkpoints,data,src}

# Initialize state files if missing
if [ ! -f "${WORKSPACE}/state/summary.md" ]; then
    cat > "${WORKSPACE}/state/summary.md" << 'EOF'
# Research Summary

No research has been conducted yet. This is a fresh start.
EOF
fi

if [ ! -f "${WORKSPACE}/state/journal.md" ]; then
    cat > "${WORKSPACE}/state/journal.md" << 'EOF'
# Research Journal

(No entries yet)
EOF
fi

if [ ! -f "${WORKSPACE}/state/plan.md" ]; then
    cat > "${WORKSPACE}/state/plan.md" << 'EOF'
# Research Plan

(To be created by the first session after exploring the data and literature)
EOF
fi

# Remove stale STOP file if present
rm -f "${WORKSPACE}/state/STOP"

SESSION_COUNT=0

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOOP_LOG"
}

log "Research loop started. PID=$$"
log "To stop: touch ${WORKSPACE}/state/STOP"

while true; do
    # Check for stop signal
    if [ -f "${WORKSPACE}/state/STOP" ]; then
        log "STOP file detected. Exiting loop gracefully."
        break
    fi

    SESSION_COUNT=$((SESSION_COUNT + 1))
    log "========== Starting session #${SESSION_COUNT} =========="

    # Run one Claude session
    /workspace/scripts/run_session.sh 2>&1 | tee -a "$LOOP_LOG" || true

    log "========== Session #${SESSION_COUNT} finished =========="

    # Check for stop signal after session
    if [ -f "${WORKSPACE}/state/STOP" ]; then
        log "STOP file detected after session. Exiting loop."
        break
    fi

    # Pause between sessions
    log "Sleeping 10s before next session..."
    sleep 10
done

log "Research loop ended. Total sessions: ${SESSION_COUNT}"
