#!/bin/bash
set -euo pipefail

# Cron Status Collector
# Usage: cron-status.sh [--dry-run] [--help]

DRY_RUN=false

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--dry-run] [--help]

Fetches OpenClaw cron job status and outputs JSON.

Flags:
  --dry-run     Output sample data without running openclaw
  --help        Show this help message

Output: JSON array [{name, id, schedule, lastRun, status}]
EOF
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

if $DRY_RUN; then
  cat <<'JSON'
[
  {
    "name": "kaizen-daily",
    "id": "cron_001",
    "schedule": "0 9 * * *",
    "lastRun": "2026-02-20T09:00:00Z",
    "status": "success"
  },
  {
    "name": "session-sync",
    "id": "cron_002",
    "schedule": "*/30 * * * *",
    "lastRun": "2026-02-20T12:30:00Z",
    "status": "running"
  }
]
JSON
  exit 0
fi

# Try JSON mode first
if command -v openclaw &>/dev/null; then
  if OUTPUT=$(openclaw cron list --json 2>/dev/null); then
    # Validate it's JSON
    echo "$OUTPUT" | python3 -c "import json, sys; data=json.load(sys.stdin); print(json.dumps(data, indent=2))" 2>/dev/null && exit 0

    # If not valid JSON, parse text output
    echo "$OUTPUT" | python3 - <<'PYEOF'
import sys, json, re

lines = sys.stdin.read().strip().splitlines()
result = []
for line in lines:
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    # Try to parse tab/space separated fields
    parts = re.split(r'\s{2,}|\t', line)
    if len(parts) >= 3:
        result.append({
            "name": parts[0].strip() if len(parts) > 0 else "",
            "id": parts[1].strip() if len(parts) > 1 else "",
            "schedule": parts[2].strip() if len(parts) > 2 else "",
            "lastRun": parts[3].strip() if len(parts) > 3 else "",
            "status": parts[4].strip() if len(parts) > 4 else "unknown"
        })
print(json.dumps(result, indent=2))
PYEOF
    exit 0
  fi
fi

# openclaw not available or failed
echo "Warning: openclaw command not available or cron list failed" >&2
echo "[]"
