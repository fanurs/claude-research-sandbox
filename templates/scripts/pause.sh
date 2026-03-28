#!/usr/bin/env bash
set -euo pipefail
echo "Pausing __PROJECT_NAME__-sandbox..."
docker pause __PROJECT_NAME__-sandbox
echo "Paused. Use scripts/resume.sh to unpause."
