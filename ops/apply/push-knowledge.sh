#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DRY_RUN=false
COMMIT_MSG=""

usage() {
  cat <<EOF
Usage: $0 '<commit message>' [--dry-run]
       $0 --dry-run '<commit message>'

Options:
  --dry-run  Show git status and what would be committed without pushing
  --help     Show this help

Examples:
  $0 'kaizen: metrics update — 2026-02-20'
  $0 --dry-run 'kaizen: metrics update — 2026-02-20'
EOF
  exit 0
}

# Parse args (allow --dry-run before or after message)
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h) usage ;;
    --) shift; POSITIONAL+=("$@"); break ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)  POSITIONAL+=("$1"); shift ;;
  esac
done

[[ ${#POSITIONAL[@]} -gt 0 ]] && COMMIT_MSG="${POSITIONAL[0]}"
[[ -z "$COMMIT_MSG" ]] && { echo "Error: commit message is required" >&2; exit 1; }

cd "$REPO_ROOT"

# Check if there's anything to commit
STATUS="$(git status --porcelain)"

if [[ -z "$STATUS" ]]; then
  echo "Nothing to commit, working tree clean. Skipping."
  exit 0
fi

if $DRY_RUN; then
  echo "[dry-run] Repository: $REPO_ROOT"
  echo "[dry-run] Commit message: $COMMIT_MSG"
  echo ""
  echo "--- git status ---"
  git status
  echo ""
  echo "--- files that would be committed ---"
  git status --porcelain
  exit 0
fi

git add -A
git commit -m "$COMMIT_MSG"
git push origin main
echo "Pushed to origin/main"
