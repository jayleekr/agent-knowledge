#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENT=""
ENTRY=""
CATEGORY=""
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 --agent <mother|walter|herald> --entry '<text>' --category '<category>' [--dry-run]

Options:
  --agent     Agent name: mother, walter, or herald
  --entry     Lesson text to append
  --category  Category name for the entry
  --dry-run   Show what would be appended without writing
  --help      Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)    AGENT="$2";    shift 2 ;;
    --entry)    ENTRY="$2";    shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true;  shift   ;;
    --help|-h)  usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Validate required args
[[ -z "$AGENT" ]]    && { echo "Error: --agent is required" >&2; exit 1; }
[[ -z "$ENTRY" ]]    && { echo "Error: --entry is required" >&2; exit 1; }
[[ -z "$CATEGORY" ]] && { echo "Error: --category is required" >&2; exit 1; }

# Validate agent name
case "$AGENT" in
  mother|walter|herald) ;;
  *) echo "Error: invalid agent '$AGENT'. Must be mother, walter, or herald." >&2; exit 1 ;;
esac

TARGET="$REPO_ROOT/lessons/${AGENT}.md"
[[ -f "$TARGET" ]] || { echo "Error: $TARGET not found" >&2; exit 1; }

DATE="$(date '+%Y-%m-%d')"
LINE="- **${DATE}** [${CATEGORY}]: ${ENTRY}"

if $DRY_RUN; then
  echo "[dry-run] Would append to $TARGET:"
  echo "$LINE"
  exit 0
fi

echo "" >> "$TARGET"
echo "$LINE" >> "$TARGET"
echo "Appended to $TARGET"
