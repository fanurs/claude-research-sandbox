#!/usr/bin/env bash
set -euo pipefail
echo "Resuming __PROJECT_NAME__-sandbox..."
docker unpause __PROJECT_NAME__-sandbox
echo "Resumed."
