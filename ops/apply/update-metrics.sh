#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FILE=""
DATA=""
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 --file <geo-trends|agent-health|token-usage> --data '<json>' [--dry-run]

Options:
  --file     Metrics file: geo-trends, agent-health, or token-usage
  --data     JSON object to append/update (must include "date" field)
  --dry-run  Show diff without writing
  --help     Show this help

The data object must contain a "date" field (YYYY-MM-DD).
If an entry for that date already exists, it will be replaced.
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)    FILE="$2";     shift 2 ;;
    --data)    DATA="$2";     shift 2 ;;
    --dry-run) DRY_RUN=true;  shift   ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Validate required args
[[ -z "$FILE" ]] && { echo "Error: --file is required" >&2; exit 1; }
[[ -z "$DATA" ]] && { echo "Error: --data is required" >&2; exit 1; }

# Validate file name
case "$FILE" in
  geo-trends|agent-health|token-usage) ;;
  *) echo "Error: invalid file '$FILE'. Must be geo-trends, agent-health, or token-usage." >&2; exit 1 ;;
esac

# Validate JSON input
if ! python3 -c "import json,sys; json.loads(sys.argv[1])" "$DATA" 2>/dev/null; then
  echo "Error: --data is not valid JSON" >&2
  exit 1
fi

# Check date field exists
DATE="$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('date',''))" "$DATA")"
if [[ -z "$DATE" ]]; then
  echo "Error: JSON data must contain a 'date' field" >&2
  exit 1
fi

TARGET="$REPO_ROOT/metrics/${FILE}.json"
[[ -f "$TARGET" ]] || { echo "Error: $TARGET not found" >&2; exit 1; }

# Compute new JSON content (deduplicate by date)
NEW_CONTENT="$(python3 - "$TARGET" "$DATA" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    obj = json.load(f)

new_entry = json.loads(sys.argv[2])
date = new_entry["date"]

daily = obj.get("daily", [])

# Replace existing entry with same date, or append
replaced = False
for i, entry in enumerate(daily):
    if entry.get("date") == date:
        daily[i] = new_entry
        replaced = True
        break

if not replaced:
    daily.append(new_entry)

obj["daily"] = daily
print(json.dumps(obj, ensure_ascii=False, indent=2))
PYEOF
)"

if $DRY_RUN; then
  echo "[dry-run] Would update $TARGET (date: $DATE)"
  echo "--- current"
  python3 -c "
import json
with open('$TARGET') as f:
    print(json.dumps(json.load(f), ensure_ascii=False, indent=2))
"
  echo "+++ new"
  echo "$NEW_CONTENT"
  exit 0
fi

echo "$NEW_CONTENT" > "$TARGET"
echo "Updated $TARGET (date: $DATE)"
