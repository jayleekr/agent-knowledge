#!/bin/bash
set -euo pipefail

# error-patterns.sh — Analyze error patterns in session logs
# Output: {total_errors, by_agent: {}, top_patterns: [{message, count}]}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--help] <session-logs-json>

Analyze error patterns in session logs JSON.

Arguments:
  <session-logs-json>   JSON session logs file
    Supported formats:
      - Array of sessions: [{agent, errors: [{message},...]}]
      - {sessions: [...]}
      - Agent-health style: {daily: [{agents: {name: {errors: N}}}]}

Options:
  --dry-run   Output sample result
  --help      Show this help message

Output: JSON {total_errors, by_agent: {}, top_patterns: [{message, count}]}
EOF
}

DRY_RUN=false
FILE=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage; exit 0 ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) FILE="$arg" ;;
  esac
done

if $DRY_RUN; then
  cat <<'JSON'
{
  "total_errors": 15,
  "by_agent": {
    "mother": 3,
    "walter": 8,
    "herald": 4
  },
  "top_patterns": [
    {"message": "API timeout", "count": 5},
    {"message": "Missing required field", "count": 4},
    {"message": "JSON parse error", "count": 3}
  ]
}
JSON
  exit 0
fi

if [[ -z "$FILE" ]]; then
  echo '{"error": "No file specified"}' >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  python3 -c "import json; print(json.dumps({'error': 'File not found: ' + '$FILE'}))" >&2
  exit 1
fi

python3 - "$FILE" <<'PYEOF'
import json, sys
from collections import defaultdict, Counter

filepath = sys.argv[1]
with open(filepath, "r", encoding="utf-8") as f:
    data = json.load(f)

by_agent = defaultdict(int)
error_messages = []

def process_sessions(sessions):
    for session in sessions:
        agent = session.get("agent", session.get("name", "unknown"))
        errors = session.get("errors", [])
        if isinstance(errors, int):
            by_agent[agent] += errors
        elif isinstance(errors, list):
            by_agent[agent] += len(errors)
            for err in errors:
                if isinstance(err, str):
                    error_messages.append(err)
                elif isinstance(err, dict):
                    msg = err.get("message", err.get("error", err.get("msg", "")))
                    if msg:
                        error_messages.append(str(msg))

if isinstance(data, list):
    process_sessions(data)
elif isinstance(data, dict):
    if "sessions" in data:
        process_sessions(data["sessions"])
    elif "daily" in data:
        # agent-health.json style: {daily: [{agents: {name: {errors: N}}}]}
        for day in data["daily"]:
            for agent_name, info in day.get("agents", {}).items():
                by_agent[agent_name] += info.get("errors", 0)

counter = Counter(error_messages)
top_patterns = [{"message": msg, "count": cnt} for msg, cnt in counter.most_common(10)]

print(json.dumps({
    "total_errors": sum(by_agent.values()),
    "by_agent": dict(by_agent),
    "top_patterns": top_patterns
}, ensure_ascii=False, indent=2))
PYEOF
