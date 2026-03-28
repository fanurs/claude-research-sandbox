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

# Run claude — capture JSON output, tee text to log
claude --dangerously-skip-permissions \
  -p "$PROMPT" \
  --output-format json \
  > "$JSON_LOG" 2>>"$TEXT_LOG"

EXIT_CODE=$?

# Extract the text result from JSON for the text log
if command -v python3 &>/dev/null; then
  python3 -c "
import json, sys
try:
    data = json.load(open('$JSON_LOG'))
    if isinstance(data, dict) and 'result' in data:
        print(data['result'])
    elif isinstance(data, dict) and 'message' in data:
        print(data['message'])
    else:
        print(json.dumps(data, indent=2)[:2000])
except:
    print('(could not parse JSON output)')
" >> "$TEXT_LOG" 2>/dev/null
fi

echo "" >> "$TEXT_LOG"
echo "=== Session ended at $(date +%Y-%m-%d_%H-%M-%S) exit=${EXIT_CODE} ===" | tee -a "$TEXT_LOG"
