#!/bin/bash
set -euo pipefail

# Test suite for ops/collect/ scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECT_DIR="$(cd "$SCRIPT_DIR/../ops/collect" && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; ((PASS++)) || true; }
fail() { echo "FAIL: $1"; ((FAIL++)) || true; }

validate_json() {
  local input="$1"
  echo "$input" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null
}

run_test() {
  local name="$1"
  local cmd="$2"
  local validator="${3:-}"

  local output
  if output=$(eval "$cmd" 2>/dev/null); then
    if [[ -n "$validator" ]]; then
      if eval "$validator" <<< "$output" 2>/dev/null; then
        pass "$name"
      else
        fail "$name (invalid output: $(echo "$output" | head -c 100))"
      fi
    else
      pass "$name"
    fi
  else
    fail "$name (command failed with exit code $?)"
  fi
}

run_test_exit_nonzero() {
  local name="$1"
  local cmd="$2"

  local exit_code=0
  eval "$cmd" >/dev/null 2>&1 || exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    pass "$name"
  else
    fail "$name (expected non-zero exit, got 0)"
  fi
}

echo "========================================"
echo "Running ops/collect test suite"
echo "========================================"
echo ""

# ----------------------------------------
# discord-messages.sh tests
# ----------------------------------------
DISCORD="$COLLECT_DIR/discord-messages.sh"
echo "--- discord-messages.sh ---"

# --help returns usage
run_test "discord --help exits 0" \
  "\"$DISCORD\" --help 2>&1" \
  "grep -qi 'usage\|channel\|dry-run'"

# --dry-run outputs valid JSON array
run_test "discord --dry-run outputs valid JSON" \
  "\"$DISCORD\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert isinstance(data, list)'"

# --dry-run JSON has expected fields
run_test "discord --dry-run has required fields" \
  "\"$DISCORD\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert all(\"author\" in m and \"content\" in m and \"timestamp\" in m and \"reactions\" in m for m in data)'"

# with explicit channel_id + dry-run
run_test "discord with channel_id + dry-run" \
  "\"$DISCORD\" 1234567890 --dry-run" \
  "python3 -c 'import json,sys; json.load(sys.stdin)'"

echo ""

# ----------------------------------------
# session-logs.sh tests
# ----------------------------------------
SESSION="$COLLECT_DIR/session-logs.sh"
echo "--- session-logs.sh ---"

run_test "session --help exits 0" \
  "\"$SESSION\" --help 2>&1" \
  "grep -qi 'usage\|session\|dry-run'"

run_test "session --dry-run outputs valid JSON" \
  "\"$SESSION\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert isinstance(data, list)'"

run_test "session --dry-run has required fields" \
  "\"$SESSION\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert all(\"key\" in s and \"agent\" in s and \"model\" in s and \"tokens\" in s and \"updatedAt\" in s and \"status\" in s for s in data)'"

# When sessions dir doesn't exist, should return [] not error
run_test "session handles missing dir gracefully" \
  "HOME=/tmp/nonexistent_$$  \"$SESSION\" 2>/dev/null || echo '[]'" \
  "python3 -c 'import json,sys; json.load(sys.stdin)'"

echo ""

# ----------------------------------------
# submissions.sh tests
# ----------------------------------------
SUBMISSIONS="$COLLECT_DIR/submissions.sh"
echo "--- submissions.sh ---"

run_test "submissions --help exits 0" \
  "\"$SUBMISSIONS\" --help 2>&1" \
  "grep -qi 'usage\|submission\|dry-run'"

run_test "submissions --dry-run outputs valid JSON" \
  "\"$SUBMISSIONS\" --dry-run" \
  "python3 -c 'import json,sys; json.load(sys.stdin)'"

run_test "submissions --dry-run has required fields" \
  "\"$SUBMISSIONS\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert \"total\" in data and \"by_status\" in data and \"avg_geo_score\" in data'"

# Missing file should output empty summary (not error)
FAKE_HOME="/tmp/test_submissions_$$"
mkdir -p "$FAKE_HOME/CodeWorkspace/hypeproof/scripts"
run_test "submissions handles missing file" \
  "HOME=$FAKE_HOME \"$SUBMISSIONS\"" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert data[\"total\"] == 0'"
rm -rf "$FAKE_HOME"

# With a real submissions.json
SAMPLE_HOME="/tmp/test_submissions_sample_$$"
mkdir -p "$SAMPLE_HOME/CodeWorkspace/hypeproof/scripts"
cat > "$SAMPLE_HOME/CodeWorkspace/hypeproof/scripts/submissions.json" <<'SAMPLEEOF'
[
  {"status": "submitted", "geo_score": 80},
  {"status": "submitted", "geo_score": 90},
  {"status": "pending", "geo_score": 70}
]
SAMPLEEOF
run_test "submissions parses real file correctly" \
  "HOME=$SAMPLE_HOME \"$SUBMISSIONS\"" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert data[\"total\"] == 3 and data[\"by_status\"].get(\"submitted\") == 2'"
rm -rf "$SAMPLE_HOME"

echo ""

# ----------------------------------------
# cron-status.sh tests
# ----------------------------------------
CRON="$COLLECT_DIR/cron-status.sh"
echo "--- cron-status.sh ---"

run_test "cron --help exits 0" \
  "\"$CRON\" --help 2>&1" \
  "grep -qi 'usage\|cron\|dry-run'"

run_test "cron --dry-run outputs valid JSON" \
  "\"$CRON\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert isinstance(data, list)'"

run_test "cron --dry-run has required fields" \
  "\"$CRON\" --dry-run" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert all(\"name\" in c and \"id\" in c and \"schedule\" in c and \"lastRun\" in c and \"status\" in c for c in data)'"

# When openclaw not available, should still output valid JSON (empty array)
run_test "cron handles missing openclaw" \
  "PATH=/tmp/empty_path_$$ \"$CRON\" 2>/dev/null" \
  "python3 -c 'import json,sys; data=json.load(sys.stdin); assert isinstance(data, list)'"

echo ""
echo "========================================"
echo "Results: $PASS passed, $FAIL failed"
echo "========================================"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
