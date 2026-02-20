#!/bin/bash
set -euo pipefail

# Integration Test Suite
# Tests end-to-end pipeline: collect → analyze → apply
# Verifies all scripts exist, are executable, and produce valid outputs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
ERRORS=()

pass() { echo "[PASS] $1"; ((PASS++)) || true; }
fail() { echo "[FAIL] $1"; ((FAIL++)) || true; ERRORS+=("$1"); }

validate_json() {
  python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null
}

echo "========================================"
echo "Integration Test Suite"
echo "Repo: $REPO_ROOT"
echo "========================================"
echo ""

# ──────────────────────────────────────────────
# SECTION 1: Script Existence & Syntax Check
# ──────────────────────────────────────────────
echo "--- 1. Script Existence & Syntax Check ---"

check_script() {
  local path="$1"
  local rel="${path#$REPO_ROOT/}"
  if [[ ! -f "$path" ]]; then
    fail "missing: $rel"
    return
  fi
  # Verify bash syntax (no execute bit required)
  if bash -n "$path" 2>/dev/null; then
    pass "exists+valid: $rel"
  else
    fail "syntax error: $rel"
  fi
}

# ops/collect/
check_script "$REPO_ROOT/ops/collect/submissions.sh"
check_script "$REPO_ROOT/ops/collect/discord-messages.sh"
check_script "$REPO_ROOT/ops/collect/session-logs.sh"
check_script "$REPO_ROOT/ops/collect/cron-status.sh"

# ops/analyze/
check_script "$REPO_ROOT/ops/analyze/geo-check.sh"

# ops/apply/
check_script "$REPO_ROOT/ops/apply/update-metrics.sh"
check_script "$REPO_ROOT/ops/apply/update-eval.sh"
check_script "$REPO_ROOT/ops/apply/update-lessons.sh"
check_script "$REPO_ROOT/ops/apply/push-knowledge.sh"

# ops/notify/
check_script "$REPO_ROOT/ops/notify/dm-jay.sh"
check_script "$REPO_ROOT/ops/notify/post-channel.sh"

echo ""

# ──────────────────────────────────────────────
# SECTION 2: .claude/commands/ Existence
# ──────────────────────────────────────────────
echo "--- 2. .claude/commands/ Files ---"

check_command() {
  local name="$1"
  local path="$REPO_ROOT/.claude/commands/${name}.md"
  if [[ -f "$path" ]]; then
    pass "command exists: $name.md"
  else
    fail "missing command: $name.md"
  fi
}

check_command "kaizen-status"
check_command "kaizen-run"
check_command "geo-check"
check_command "propose"
check_command "lessons"
check_command "metrics"

echo ""

# ──────────────────────────────────────────────
# SECTION 3: Commands Reference Correct Scripts
# ──────────────────────────────────────────────
echo "--- 3. Command → Script References ---"

check_command_refs() {
  local cmd_name="$1"
  local script_pattern="$2"
  local cmd_file="$REPO_ROOT/.claude/commands/${cmd_name}.md"
  if [[ ! -f "$cmd_file" ]]; then
    fail "command file missing: $cmd_name.md (cannot check refs)"
    return
  fi
  if grep -q "$script_pattern" "$cmd_file"; then
    pass "command $cmd_name references $script_pattern"
  else
    fail "command $cmd_name missing reference to $script_pattern"
  fi
}

check_command_refs "kaizen-status" "ops/collect/submissions.sh"
check_command_refs "kaizen-status" "ops/collect/cron-status.sh"
check_command_refs "kaizen-run"    "ops/collect/"
check_command_refs "kaizen-run"    "ops/analyze/"
check_command_refs "kaizen-run"    "ops/apply/"
check_command_refs "geo-check"     "ops/analyze/geo-check.sh"
check_command_refs "propose"       "proposals/pending/"
check_command_refs "lessons"       "lessons/"
check_command_refs "metrics"       "metrics/"

echo ""

# ──────────────────────────────────────────────
# SECTION 4: Full Pipeline --dry-run
# ──────────────────────────────────────────────
echo "--- 4. Full Pipeline (--dry-run) ---"

# Collect stage
SUBMISSIONS_OUT="$(bash "$REPO_ROOT/ops/collect/submissions.sh" --dry-run 2>/dev/null)"
if echo "$SUBMISSIONS_OUT" | validate_json; then
  pass "collect/submissions.sh --dry-run produces valid JSON"
else
  fail "collect/submissions.sh --dry-run produced invalid JSON"
fi

DISCORD_OUT="$(bash "$REPO_ROOT/ops/collect/discord-messages.sh" --dry-run 2>/dev/null)"
if echo "$DISCORD_OUT" | validate_json; then
  pass "collect/discord-messages.sh --dry-run produces valid JSON"
else
  fail "collect/discord-messages.sh --dry-run produced invalid JSON"
fi

SESSION_OUT="$(bash "$REPO_ROOT/ops/collect/session-logs.sh" --dry-run 2>/dev/null)"
if echo "$SESSION_OUT" | validate_json; then
  pass "collect/session-logs.sh --dry-run produces valid JSON"
else
  fail "collect/session-logs.sh --dry-run produced invalid JSON"
fi

CRON_OUT="$(bash "$REPO_ROOT/ops/collect/cron-status.sh" --dry-run 2>/dev/null)"
if echo "$CRON_OUT" | validate_json; then
  pass "collect/cron-status.sh --dry-run produces valid JSON"
else
  fail "collect/cron-status.sh --dry-run produced invalid JSON"
fi

# Analyze stage
GEO_OUT="$(bash "$REPO_ROOT/ops/analyze/geo-check.sh" --dry-run 2>/dev/null)"
if echo "$GEO_OUT" | validate_json; then
  pass "analyze/geo-check.sh --dry-run produces valid JSON"
else
  fail "analyze/geo-check.sh --dry-run produced invalid JSON"
fi

# Apply stage
METRICS_OUT="$(bash "$REPO_ROOT/ops/apply/update-metrics.sh" \
  --file geo-trends \
  --data '{"date":"2099-01-01","avg_score":75,"submissions":5,"published":3}' \
  --dry-run 2>/dev/null)"
if echo "$METRICS_OUT" | grep -q "dry-run"; then
  pass "apply/update-metrics.sh --dry-run runs without error"
else
  fail "apply/update-metrics.sh --dry-run failed or missing dry-run output"
fi

PUSH_OUT="$(bash "$REPO_ROOT/ops/apply/push-knowledge.sh" \
  --dry-run 'test: integration dry-run' 2>/dev/null)"
if echo "$PUSH_OUT" | grep -qE "dry-run|Nothing to commit"; then
  pass "apply/push-knowledge.sh --dry-run runs without error"
else
  fail "apply/push-knowledge.sh --dry-run failed"
fi

echo ""

# ──────────────────────────────────────────────
# SECTION 5: Notify Scripts
# ──────────────────────────────────────────────
echo "--- 5. Notify Scripts (--dry-run) ---"

DM_OUT="$(bash "$REPO_ROOT/ops/notify/dm-jay.sh" --dry-run "Integration test message" 2>/dev/null)"
if echo "$DM_OUT" | grep -q "Would queue"; then
  pass "notify/dm-jay.sh --dry-run shows 'Would queue'"
else
  fail "notify/dm-jay.sh --dry-run missing 'Would queue'"
fi

# Check the queued entry is valid JSON
DM_JSON="$(echo "$DM_OUT" | tail -n +2)"
if echo "$DM_JSON" | validate_json; then
  pass "notify/dm-jay.sh --dry-run entry is valid JSON"
else
  fail "notify/dm-jay.sh --dry-run entry is not valid JSON"
fi

# Check required fields in queued entry
if echo "$DM_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert 'timestamp' in d
assert d['target'] == 'user:1186944844401225808'
assert 'message' in d
assert d['sent'] == False
" 2>/dev/null; then
  pass "notify/dm-jay.sh --dry-run entry has correct fields"
else
  fail "notify/dm-jay.sh --dry-run entry missing required fields"
fi

CHAN_OUT="$(bash "$REPO_ROOT/ops/notify/post-channel.sh" --dry-run 1471863670718857247 "Test channel post" 2>/dev/null)"
if echo "$CHAN_OUT" | grep -q "Would queue"; then
  pass "notify/post-channel.sh --dry-run shows 'Would queue'"
else
  fail "notify/post-channel.sh --dry-run missing 'Would queue'"
fi

CHAN_JSON="$(echo "$CHAN_OUT" | tail -n +2)"
if echo "$CHAN_JSON" | validate_json; then
  pass "notify/post-channel.sh --dry-run entry is valid JSON"
else
  fail "notify/post-channel.sh --dry-run entry is not valid JSON"
fi

if echo "$CHAN_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert 'timestamp' in d
assert d['target'] == 'channel:1471863670718857247'
assert 'message' in d
assert d['sent'] == False
" 2>/dev/null; then
  pass "notify/post-channel.sh --dry-run entry has correct fields"
else
  fail "notify/post-channel.sh --dry-run entry missing required fields"
fi

echo ""

# ──────────────────────────────────────────────
# SECTION 6: Metrics Files are Valid JSON
# ──────────────────────────────────────────────
echo "--- 6. Metrics File Validity ---"

for mfile in geo-trends agent-health token-usage; do
  path="$REPO_ROOT/metrics/${mfile}.json"
  if [[ -f "$path" ]]; then
    if python3 -c "import json; json.load(open('$path'))" 2>/dev/null; then
      pass "metrics/${mfile}.json is valid JSON"
    else
      fail "metrics/${mfile}.json is invalid JSON"
    fi
  else
    fail "metrics/${mfile}.json does not exist"
  fi
done

echo ""

# ──────────────────────────────────────────────
# SUMMARY
# ──────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo "========================================"
echo "Integration Results: $PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failed:"
  for e in "${ERRORS[@]}"; do
    echo "  ✗ $e"
  done
  echo "========================================"
  exit 1
else
  echo "All integration tests passed!"
  echo "========================================"
fi
