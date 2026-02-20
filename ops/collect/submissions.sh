#!/bin/bash
set -euo pipefail

# Submissions Collector
# Usage: submissions.sh [--dry-run] [--help]

SUBMISSIONS_FILE="${HOME}/CodeWorkspace/hypeproof/scripts/submissions.json"
DRY_RUN=false

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--dry-run] [--help]

Reads submissions.json and outputs a summary.

Flags:
  --dry-run     Output sample data
  --help        Show this help message

Output: JSON object {total, by_status: {submitted: N, ...}, avg_geo_score}
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
{
  "total": 42,
  "by_status": {
    "submitted": 30,
    "pending": 8,
    "rejected": 4
  },
  "avg_geo_score": 78.5
}
JSON
  exit 0
fi

if [[ ! -f "$SUBMISSIONS_FILE" ]]; then
  cat <<'JSON'
{
  "total": 0,
  "by_status": {},
  "avg_geo_score": 0
}
JSON
  exit 0
fi

python3 - "$SUBMISSIONS_FILE" <<'PYEOF'
import json, sys

filepath = sys.argv[1]

with open(filepath, "r") as f:
    data = json.load(f)

# Handle both array and object formats
if isinstance(data, list):
    submissions = data
elif isinstance(data, dict):
    submissions = data.get("submissions", data.get("data", [data]))
else:
    submissions = []

total = len(submissions)
by_status = {}
geo_scores = []

for item in submissions:
    status = item.get("status", "unknown")
    by_status[status] = by_status.get(status, 0) + 1

    geo = item.get("geo_score", item.get("geoScore", None))
    if geo is not None:
        try:
            geo_scores.append(float(geo))
        except (ValueError, TypeError):
            pass

avg_geo = round(sum(geo_scores) / len(geo_scores), 2) if geo_scores else 0

result = {
    "total": total,
    "by_status": by_status,
    "avg_geo_score": avg_geo
}

print(json.dumps(result, indent=2))
PYEOF
