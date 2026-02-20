#!/bin/bash
set -euo pipefail

# trend-compare.sh — Compare latest metrics entry vs average of previous N entries
# Output: [{metric, current, avg_previous, trend, change_pct}]

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--help] <metrics-json> [days]

Compare latest metrics entry vs average of previous N entries.

Arguments:
  <metrics-json>   Metrics JSON file: {daily: [...]} or plain array
  [days]           Number of previous entries to compare (default: 7)

Options:
  --dry-run   Output sample result
  --help      Show this help message

Output: JSON array of {metric, current, avg_previous, trend: up/down/stable, change_pct}
EOF
}

DRY_RUN=false
FILE=""
DAYS=7

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage; exit 0 ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    [0-9]*) DAYS="$arg" ;;
    *) FILE="$arg" ;;
  esac
done

if $DRY_RUN; then
  cat <<'JSON'
[
  {
    "metric": "avg_score",
    "current": 85,
    "avg_previous": 78.5,
    "trend": "up",
    "change_pct": 8.3
  },
  {
    "metric": "submissions",
    "current": 12,
    "avg_previous": 9.2,
    "trend": "up",
    "change_pct": 30.4
  }
]
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

python3 - "$FILE" "$DAYS" <<'PYEOF'
import json, sys

filepath = sys.argv[1]
days = int(sys.argv[2])

with open(filepath, "r", encoding="utf-8") as f:
    data = json.load(f)

if isinstance(data, dict) and "daily" in data:
    entries = data["daily"]
elif isinstance(data, list):
    entries = data
else:
    print(json.dumps({"error": "Unrecognized format — need {daily:[...]} or plain array"}))
    sys.exit(1)

if len(entries) < 2:
    print(json.dumps({"error": "Not enough entries to compare", "count": len(entries)}))
    sys.exit(0)

latest = entries[-1]
previous = entries[-(days + 1):-1] if len(entries) > days + 1 else entries[:-1]

results = []
for key, val in latest.items():
    if key in ("date", "notes"):
        continue
    if not isinstance(val, (int, float)) or val is None:
        continue

    prev_vals = [
        e[key] for e in previous
        if key in e and isinstance(e[key], (int, float)) and e[key] is not None
    ]
    if not prev_vals:
        continue

    avg_prev = sum(prev_vals) / len(prev_vals)

    if avg_prev == 0:
        change_pct = 0.0
        trend = "stable"
    else:
        change_pct = round(((val - avg_prev) / abs(avg_prev)) * 100, 1)
        if change_pct > 2:
            trend = "up"
        elif change_pct < -2:
            trend = "down"
        else:
            trend = "stable"

    results.append({
        "metric": key,
        "current": val,
        "avg_previous": round(avg_prev, 2),
        "trend": trend,
        "change_pct": change_pct
    })

print(json.dumps(results, ensure_ascii=False, indent=2))
PYEOF
