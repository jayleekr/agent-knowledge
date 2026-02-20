#!/bin/bash
set -euo pipefail

# Discord DM Notifier — Jay
# Usage: dm-jay.sh [--dry-run] <message>
#
# Queues a DM to Jay (user:1186944844401225808) in notify-queue.json
# The queue is processed by the OpenClaw message tool.

TARGET="user:1186944844401225808"
QUEUE_FILE="${HOME}/.openclaw/workspace/notify-queue.json"
DRY_RUN=false
MESSAGE_PARTS=()

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--dry-run] <message>

Queues a Discord DM to Jay via OpenClaw notify-queue.

Arguments:
  message       Text to send (can be quoted or multi-word)

Flags:
  --dry-run     Print what would be queued without writing
  --help        Show this help message

Queue file: $QUEUE_FILE
Entry format: {timestamp, target, message, sent: false}
EOF
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --dry-run) DRY_RUN=true ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) MESSAGE_PARTS+=("$arg") ;;
  esac
done

if [[ ${#MESSAGE_PARTS[@]} -eq 0 ]]; then
  echo "Error: message is required" >&2
  exit 1
fi

MESSAGE="${MESSAGE_PARTS[*]}"

python3 - "$MESSAGE" "$QUEUE_FILE" "$DRY_RUN" "$TARGET" <<'PYEOF'
import json, sys, os
from datetime import datetime, timezone

message    = sys.argv[1]
queue_file = sys.argv[2]
dry_run    = sys.argv[3] == "true"
target     = sys.argv[4]

entry = {
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "target":    target,
    "message":   message,
    "sent":      False
}

if dry_run:
    print("Would queue:")
    print(json.dumps(entry, indent=2))
    sys.exit(0)

os.makedirs(os.path.dirname(queue_file), exist_ok=True)

if os.path.exists(queue_file):
    with open(queue_file, "r") as f:
        queue = json.load(f)
else:
    queue = []

queue.append(entry)

with open(queue_file, "w") as f:
    json.dump(queue, f, indent=2)

print(f"Queued. Total in queue: {len(queue)}")
PYEOF
