#!/usr/bin/env bash
# Main research loop. Runs INSIDE the container (in tmux).
# Chains Claude sessions until state/STOP file appears.
#
# To start:  tmux new -d -s research '/workspace/loop.sh'
# To watch:  tmux attach -t research
# To stop:                 /workspace/scripts/stop.sh
# To stop after session N: /workspace/scripts/stop.sh 50
# To detach: Ctrl+B then D
set -euo pipefail

WORKSPACE="/workspace"
LOOP_LOG="${WORKSPACE}/logs/loop.log"
COUNTER_FILE="${WORKSPACE}/state/.session_counter"

# Ensure runtime dirs exist
mkdir -p "${WORKSPACE}"/{state,logs,results,checkpoints,data,src,playground,reports/figures,tests}

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

# Restore persistent session counter (absolute count across restarts)
if [ -f "$COUNTER_FILE" ]; then
    SESSION_COUNT=$(cat "$COUNTER_FILE")
else
    SESSION_COUNT=0
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOOP_LOG"
}

# Check if the loop should stop, supporting STOP and STOP-N patterns
should_stop() {
    # Defensive: also accept a literal filename pattern state/STOP-N
    # (easy to create by mistake instead of writing "STOP-N" into state/STOP).
    local f name target
    for f in "${WORKSPACE}"/state/STOP-*; do
        [ -e "$f" ] || continue
        name="${f##*/STOP-}"
        if [[ "$name" =~ ^[0-9]+$ ]] && [ "$SESSION_COUNT" -ge "$name" ]; then
            return 0
        fi
    done

    [ ! -f "${WORKSPACE}/state/STOP" ] && return 1
    local content
    content=$(cat "${WORKSPACE}/state/STOP" 2>/dev/null | tr -d '[:space:]')
    # Empty STOP file = stop now
    [ -z "$content" ] && return 0
    # STOP-N = stop when session count >= N
    if [[ "$content" =~ ^STOP-([0-9]+)$ ]]; then
        target="${BASH_REMATCH[1]}"
        [ "$SESSION_COUNT" -ge "$target" ] && return 0
        log "STOP-${target} set. Currently at session ${SESSION_COUNT}. Continuing..."
        return 1
    fi
    # Any other content = stop now
    return 0
}

log "Research loop started. PID=$$"
log "To stop: ${WORKSPACE}/scripts/stop.sh"
log "To stop after N: ${WORKSPACE}/scripts/stop.sh 50"

while true; do
    # Check for stop signal
    if should_stop; then
        log "STOP signal detected. Exiting loop gracefully."
        break
    fi

    SESSION_COUNT=$((SESSION_COUNT + 1))
    echo "$SESSION_COUNT" > "$COUNTER_FILE"
    log "========== Starting session #${SESSION_COUNT} =========="

    # Run one Claude session
    /workspace/scripts/run_session.sh 2>&1 | tee -a "$LOOP_LOG" || true

    log "========== Session #${SESSION_COUNT} finished =========="

    # Safety-net: commit any uncommitted changes (in case Claude forgot)
    cd "$WORKSPACE"
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git add -A
        git commit -m "Auto-commit after session #${SESSION_COUNT}" 2>/dev/null || true
    fi

    # Check for stop signal after session
    if should_stop; then
        log "STOP signal detected after session. Exiting loop."
        break
    fi

    # Pause between sessions
    log "Sleeping 10s before next session..."
    sleep 10
done

log "Research loop ended. Total sessions this run: ${SESSION_COUNT}"
