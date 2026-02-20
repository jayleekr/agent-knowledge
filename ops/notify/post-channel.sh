#!/bin/bash
set -euo pipefail

# Discord Channel Poster
# Usage: post-channel.sh [--dry-run] <channel_id> <message>
#
# Queues a message to a Discord channel in notify-queue.json
# The queue is processed by the OpenClaw message tool.

QUEUE_FILE="${HOME}/.openclaw/workspace/notify-queue.json"
DRY_RUN=false
POSITIONAL=()

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--dry-run] <channel_id> <message>

Queues a Discord channel message via OpenClaw notify-queue.

Arguments:
  channel_id    Discord channel ID (e.g. 1471863670718857247)
  message       Text to post

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
    *) POSITIONAL+=("$arg") ;;
  esac
done

if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
  echo "Error: channel_id and message are required" >&2
  exit 1
fi

CHANNEL_ID="${POSITIONAL[0]}"
# Join remaining positional args as message
MESSAGE="${POSITIONAL[*]:1}"
TARGET="channel:${CHANNEL_ID}"

python3 - "$MESSAGE" "$QUEUE_FILE" "$DRY_RUN" "$TARGET" "$CHANNEL_ID" <<'PYEOF'
import json, sys, os
from datetime import datetime, timezone

message    = sys.argv[1]
queue_file = sys.argv[2]
dry_run    = sys.argv[3] == "true"
target     = sys.argv[4]
channel_id = sys.argv[5]

entry = {
    "timestamp":  datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "target":     target,
    "channel_id": channel_id,
    "message":    message,
    "sent":       False
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
