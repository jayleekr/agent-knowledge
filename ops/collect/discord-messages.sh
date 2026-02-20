#!/bin/bash
set -euo pipefail

# Discord Messages Collector
# Usage: discord-messages.sh [channel_id] [--dry-run] [--help]

DEFAULT_CHANNEL_ID="1471863670718857247"
BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
if [[ -z "$BOT_TOKEN" && ! " $* " =~ " --dry-run " && ! " $* " =~ " --help " ]]; then
  echo "Error: DISCORD_BOT_TOKEN env var required" >&2; exit 1
fi
DRY_RUN=false
CHANNEL_ID=""

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [channel_id] [--dry-run] [--help]

Fetches last 20 messages from a Discord channel.

Arguments:
  channel_id    Discord channel ID (default: $DEFAULT_CHANNEL_ID)

Flags:
  --dry-run     Output sample data without making API call
  --help        Show this help message

Output: JSON array [{author, content, timestamp, reactions}]
EOF
  exit 0
}

# Parse args
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --dry-run) DRY_RUN=true ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) CHANNEL_ID="$arg" ;;
  esac
done

# Use default if no channel_id provided
if [[ -z "$CHANNEL_ID" ]]; then
  CHANNEL_ID="$DEFAULT_CHANNEL_ID"
fi

if $DRY_RUN; then
  cat <<'JSON'
[
  {
    "author": "sample_user",
    "content": "Hello world from dry run",
    "timestamp": "2026-02-20T12:00:00.000000+00:00",
    "reactions": []
  },
  {
    "author": "another_user",
    "content": "Test message with reaction",
    "timestamp": "2026-02-20T11:59:00.000000+00:00",
    "reactions": [{"emoji": "👍", "count": 3}]
  }
]
JSON
  exit 0
fi

# Fetch from Discord API
RESPONSE=$(curl -sf \
  -H "Authorization: Bot $BOT_TOKEN" \
  -H "Content-Type: application/json" \
  "https://discord.com/api/v10/channels/${CHANNEL_ID}/messages?limit=20") || {
  echo "Error: Failed to fetch Discord messages for channel $CHANNEL_ID" >&2
  exit 1
}

# Transform to clean JSON
echo "$RESPONSE" | python3 - <<'PYEOF'
import json, sys

data = json.load(sys.stdin)
result = []
for msg in data:
    reactions = []
    for r in msg.get("reactions", []):
        emoji = r.get("emoji", {})
        reactions.append({
            "emoji": emoji.get("name", ""),
            "count": r.get("count", 0)
        })
    result.append({
        "author": msg.get("author", {}).get("username", ""),
        "content": msg.get("content", ""),
        "timestamp": msg.get("timestamp", ""),
        "reactions": reactions
    })
print(json.dumps(result, indent=2))
PYEOF
