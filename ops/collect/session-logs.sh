#!/bin/bash
set -euo pipefail

# OpenClaw Session Logs Collector
# Usage: session-logs.sh [--dry-run] [--help]

SESSIONS_DIR="${HOME}/.openclaw/sessions"
DRY_RUN=false

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--dry-run] [--help]

Reads OpenClaw session files from ~/.openclaw/sessions/ and outputs JSON.

Flags:
  --dry-run     Output sample data without reading files
  --help        Show this help message

Output: JSON array [{key, agent, model, tokens, updatedAt, status}]
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
    "key": "session_abc123",
    "agent": "kaizen-agent",
    "model": "claude-sonnet-4-6",
    "tokens": 45230,
    "updatedAt": "2026-02-20T12:00:00Z",
    "status": "completed",
    "errorCount": 0
  },
  {
    "key": "session_def456",
    "agent": "research-agent",
    "model": "claude-opus-4-6",
    "tokens": 12800,
    "updatedAt": "2026-02-20T11:30:00Z",
    "status": "error",
    "errorCount": 2
  }
]
JSON
  exit 0
fi

if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "[]"
  exit 0
fi

python3 - "$SESSIONS_DIR" <<'PYEOF'
import json, sys, os, glob

sessions_dir = sys.argv[1]
result = []

# Look for .jsonl or .json session files
patterns = [
    os.path.join(sessions_dir, "*.jsonl"),
    os.path.join(sessions_dir, "*.json"),
    os.path.join(sessions_dir, "*", "*.jsonl"),
    os.path.join(sessions_dir, "*", "*.json"),
]

files = []
for pattern in patterns:
    files.extend(glob.glob(pattern))

for filepath in sorted(files):
    key = os.path.splitext(os.path.basename(filepath))[0]
    session = {
        "key": key,
        "agent": "",
        "model": "",
        "tokens": 0,
        "updatedAt": "",
        "status": "unknown",
        "errorCount": 0
    }

    try:
        stat = os.stat(filepath)
        import datetime
        session["updatedAt"] = datetime.datetime.fromtimestamp(
            stat.st_mtime, tz=datetime.timezone.utc
        ).isoformat()

        ext = os.path.splitext(filepath)[1]
        error_count = 0

        if ext == ".jsonl":
            with open(filepath, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                        # Try to extract session info from first entry
                        if not session["agent"] and "agent" in entry:
                            session["agent"] = entry["agent"]
                        if not session["model"] and "model" in entry:
                            session["model"] = entry["model"]
                        if "usage" in entry:
                            session["tokens"] += entry["usage"].get("total_tokens", 0)
                        if entry.get("type") == "error" or "error" in entry:
                            error_count += 1
                        if "status" in entry:
                            session["status"] = entry["status"]
                    except (json.JSONDecodeError, KeyError):
                        pass
        elif ext == ".json":
            with open(filepath, "r") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    session["agent"] = data.get("agent", "")
                    session["model"] = data.get("model", "")
                    session["tokens"] = data.get("tokens", 0)
                    session["status"] = data.get("status", "unknown")

        session["errorCount"] = error_count
    except (IOError, OSError):
        pass

    result.append(session)

print(json.dumps(result, indent=2))
PYEOF
