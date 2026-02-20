#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CRITERIA_ID=""
FIELD=""
VALUE=""
DRY_RUN=false
UPDATED_BY="${UPDATED_BY:-kaizen}"

usage() {
  cat <<EOF
Usage: $0 --id <criteria_id> --field <threshold|enabled> --value <new_value> [--dry-run]

Options:
  --id        Criteria ID (e.g. creator_satisfaction, geo_score_trend)
  --field     Field to update: threshold or enabled
  --value     New value (number for threshold, true/false for enabled)
  --dry-run   Show diff without writing
  --help      Show this help

Environment:
  UPDATED_BY  Who is making this update (default: kaizen)
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)      CRITERIA_ID="$2"; shift 2 ;;
    --field)   FIELD="$2";       shift 2 ;;
    --value)   VALUE="$2";       shift 2 ;;
    --dry-run) DRY_RUN=true;     shift   ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Validate required args
[[ -z "$CRITERIA_ID" ]] && { echo "Error: --id is required" >&2; exit 1; }
[[ -z "$FIELD" ]]       && { echo "Error: --field is required" >&2; exit 1; }
[[ -z "$VALUE" ]]       && { echo "Error: --value is required" >&2; exit 1; }

# Validate field
case "$FIELD" in
  threshold|enabled) ;;
  *) echo "Error: --field must be 'threshold' or 'enabled'" >&2; exit 1 ;;
esac

TARGET="$REPO_ROOT/eval-criteria.yaml"
[[ -f "$TARGET" ]] || { echo "Error: $TARGET not found" >&2; exit 1; }

# Check pyyaml available
if ! python3 -c "import yaml" 2>/dev/null; then
  echo "Error: python3 pyyaml not available. Install with: pip3 install pyyaml" >&2
  exit 1
fi

DATE="$(date '+%Y-%m-%d')"
BACKUP="${TARGET}.bak.$(date '+%Y%m%d%H%M%S')"

# Compute new content via python
python3 - "$TARGET" "$CRITERIA_ID" "$FIELD" "$VALUE" "$DATE" "$UPDATED_BY" > /tmp/kaizen-eval-result.yaml <<'PYEOF'
import yaml, sys

target_file  = sys.argv[1]
criteria_id  = sys.argv[2]
field        = sys.argv[3]
value_str    = sys.argv[4]
date         = sys.argv[5]
updated_by   = sys.argv[6]

with open(target_file) as f:
    content = f.read()

data = yaml.safe_load(content)

# Find and update criteria
found = False
for item in data.get("criteria", []):
    if item.get("id") == criteria_id:
        if field == "threshold":
            try:
                item["threshold"] = float(value_str)
                # Use int if it's a whole number
                if item["threshold"] == int(item["threshold"]):
                    item["threshold"] = int(item["threshold"])
            except ValueError:
                print(f"Error: threshold value must be numeric", file=sys.stderr)
                sys.exit(1)
        elif field == "enabled":
            if value_str.lower() in ("true", "1", "yes"):
                item["enabled"] = True
            elif value_str.lower() in ("false", "0", "no"):
                item["enabled"] = False
            else:
                print(f"Error: enabled value must be true or false", file=sys.stderr)
                sys.exit(1)
        found = True
        break

if not found:
    print(f"Error: criteria id not found: {criteria_id}", file=sys.stderr)
    sys.exit(1)

data["last_updated"] = date
data["updated_by"] = updated_by

print(yaml.dump(data, allow_unicode=True, default_flow_style=False, sort_keys=False), end="")
PYEOF
NEW_CONTENT="$(cat /tmp/kaizen-eval-result.yaml)"

if $DRY_RUN; then
  echo "[dry-run] Would update $TARGET"
  echo "  criteria: $CRITERIA_ID"
  echo "  field:    $FIELD"
  echo "  value:    $VALUE"
  echo "--- current"
  cat "$TARGET"
  echo "+++ new"
  echo "$NEW_CONTENT"
  exit 0
fi

# Backup + write
cp "$TARGET" "$BACKUP"
echo "$NEW_CONTENT" > "$TARGET"

echo "Updated $TARGET"
echo "  criteria:   $CRITERIA_ID"
echo "  field:      $FIELD → $VALUE"
echo "  updated_by: $UPDATED_BY"
echo "  backup:     $BACKUP"
