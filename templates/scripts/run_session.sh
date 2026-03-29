#!/usr/bin/env bash
# Run a single Claude research session inside the container.
# Called by loop.sh. Produces both text and JSON logs.
set -euo pipefail

WORKSPACE="/workspace"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
TEXT_LOG="${WORKSPACE}/logs/session_${TIMESTAMP}.log"
JSON_LOG="${WORKSPACE}/logs/session_${TIMESTAMP}.json"

echo "=== Session started at ${TIMESTAMP} ===" | tee "$TEXT_LOG"

# The prompt tells Claude to follow the session protocol
PROMPT="You are an autonomous research agent. Your working directory is /workspace.

Follow the session protocol exactly:
1. Read state files: state/summary.md, state/journal.md, state/next_action.md, state/plan.md
2. Pick ONE objective for this session
3. Do the work
4. Update all state files before finishing (journal, next_action, plan if needed, summary if needed)

Start now by reading your state files."

# Run claude — stream NDJSON in real-time, save to file and show in tmux
claude --dangerously-skip-permissions \
  -p "$PROMPT" \
  --verbose \
  --output-format stream-json \
  2>>"$TEXT_LOG" | tee "$JSON_LOG"

EXIT_CODE=${PIPESTATUS[0]}

echo "" >> "$TEXT_LOG"
echo "=== Session ended at $(date +%Y-%m-%d_%H-%M-%S) exit=${EXIT_CODE} ===" | tee -a "$TEXT_LOG"

# Send report email if configured (subshell so API key doesn't leak to parent env)
(
  if [ -f "${WORKSPACE}/.env.email" ]; then
    set -a && source "${WORKSPACE}/.env.email" && set +a
    cd "${WORKSPACE}"
    uv run python "${WORKSPACE}/src/send_report_email.py" 2>>"$TEXT_LOG" \
      && echo "Report email sent" >> "$TEXT_LOG" \
      || echo "Report email failed" >> "$TEXT_LOG"
  fi
)
