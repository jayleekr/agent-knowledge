#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APPLY_DIR="$REPO_ROOT/ops/apply"

PASS=0
FAIL=0
ERRORS=()

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1"; ((FAIL++)); ERRORS+=("$1"); }

run_test() {
  local name="$1"; shift
  if "$@" 2>&1; then
    pass "$name"
  else
    fail "$name"
  fi
}

# Setup: temp copies for destructive tests
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/lessons" "$TMP/metrics"

cp "$REPO_ROOT/lessons/mother.md"         "$TMP/lessons/mother.md"
cp "$REPO_ROOT/lessons/walter.md"         "$TMP/lessons/walter.md"
cp "$REPO_ROOT/lessons/herald.md"         "$TMP/lessons/herald.md"
cp "$REPO_ROOT/metrics/agent-health.json" "$TMP/metrics/agent-health.json"
cp "$REPO_ROOT/metrics/geo-trends.json"   "$TMP/metrics/geo-trends.json"
cp "$REPO_ROOT/metrics/token-usage.json"  "$TMP/metrics/token-usage.json"
cp "$REPO_ROOT/eval-criteria.yaml"        "$TMP/eval-criteria.yaml"

echo "=== test_apply.sh ==="
echo "Repo: $REPO_ROOT"
echo "Tmp:  $TMP"
echo ""

# SECTION 1: update-lessons.sh
echo "--- update-lessons.sh ---"

# 1a: --help exits 0
run_test "lessons --help exits 0" \
  bash "$APPLY_DIR/update-lessons.sh" --help

# 1b: invalid agent fails
if bash "$APPLY_DIR/update-lessons.sh" --agent robot --entry "test" --category "test" 2>/dev/null; then
  fail "lessons invalid agent should fail"
else
  pass "lessons invalid agent rejects"
fi

# 1c: dry-run shows formatted line (no file write)
LESSONS_DRYRUN="$(bash "$APPLY_DIR/update-lessons.sh" \
  --agent mother --entry "test lesson entry" --category "Testing" --dry-run 2>&1)"

if echo "$LESSONS_DRYRUN" | grep -q "\[dry-run\]"; then
  pass "lessons dry-run shows [dry-run] prefix"
else
  fail "lessons dry-run missing [dry-run] prefix"
fi

# 1d: dry-run output contains date format YYYY-MM-DD
if echo "$LESSONS_DRYRUN" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  pass "lessons dry-run output contains date"
else
  fail "lessons dry-run output missing date"
fi

# 1e: dry-run output contains entry text
if echo "$LESSONS_DRYRUN" | grep -q "test lesson entry"; then
  pass "lessons dry-run output contains entry text"
else
  fail "lessons dry-run output missing entry text"
fi

# 1f: dry-run output contains bold date format **YYYY-MM-DD**
if echo "$LESSONS_DRYRUN" | grep -qE '\*\*[0-9]{4}-[0-9]{2}-[0-9]{2}\*\*'; then
  pass "lessons dry-run format uses **date** bold"
else
  fail "lessons dry-run format missing **date** bold"
fi

# 1g: actual write to tmp copy works
PATCHED_LESSONS="$TMP/update-lessons-patched.sh"
sed "s|REPO_ROOT=.*|REPO_ROOT=\"$TMP\"|" "$APPLY_DIR/update-lessons.sh" > "$PATCHED_LESSONS"
chmod +x "$PATCHED_LESSONS"

bash "$PATCHED_LESSONS" \
  --agent mother --entry "automated test entry" --category "Testing" 2>&1 | \
  grep -q "Appended" && pass "lessons write reports 'Appended'" || fail "lessons write missing 'Appended'"

# 1h: verify the entry was actually appended
if grep -q "automated test entry" "$TMP/lessons/mother.md"; then
  pass "lessons write actually appended to file"
else
  fail "lessons write did not append to file"
fi

# 1i: verify format in written file
if grep -qE '\*\*[0-9]{4}-[0-9]{2}-[0-9]{2}\*\*.*Testing.*automated test entry' "$TMP/lessons/mother.md"; then
  pass "lessons written format is correct"
else
  fail "lessons written format is incorrect"
fi

echo ""

# SECTION 2: update-metrics.sh
echo "--- update-metrics.sh ---"

# 2a: --help exits 0
run_test "metrics --help exits 0" \
  bash "$APPLY_DIR/update-metrics.sh" --help

# 2b: invalid file name fails
if bash "$APPLY_DIR/update-metrics.sh" --file bad-file --data '{"date":"2026-01-01"}' 2>/dev/null; then
  fail "metrics invalid file should fail"
else
  pass "metrics invalid file rejects"
fi

# 2c: invalid JSON fails
if bash "$APPLY_DIR/update-metrics.sh" --file agent-health --data 'not-json' 2>/dev/null; then
  fail "metrics invalid JSON should fail"
else
  pass "metrics invalid JSON rejects"
fi

# 2d: missing date field fails
if bash "$APPLY_DIR/update-metrics.sh" --file agent-health --data '{"foo":"bar"}' 2>/dev/null; then
  fail "metrics missing date field should fail"
else
  pass "metrics missing date field rejects"
fi

# 2e: dry-run shows output
METRICS_DRYRUN="$(bash "$APPLY_DIR/update-metrics.sh" \
  --file agent-health \
  --data '{"date":"2026-03-01","agents":{"mother":{"sessions":2,"errors":0}}}' \
  --dry-run 2>&1)"

if echo "$METRICS_DRYRUN" | grep -q "\[dry-run\]"; then
  pass "metrics dry-run shows [dry-run] prefix"
else
  fail "metrics dry-run missing [dry-run] prefix"
fi

# 2f: actual write to tmp + dedup check
PATCHED_METRICS="$TMP/update-metrics-patched.sh"
sed "s|REPO_ROOT=.*|REPO_ROOT=\"$TMP\"|" "$APPLY_DIR/update-metrics.sh" > "$PATCHED_METRICS"
chmod +x "$PATCHED_METRICS"

# Write new date entry
bash "$PATCHED_METRICS" \
  --file agent-health \
  --data '{"date":"2026-03-01","agents":{"mother":{"sessions":2,"errors":0}}}' 2>&1 | \
  grep -q "Updated" && pass "metrics write reports 'Updated'" || fail "metrics write missing 'Updated'"

# 2g: verify JSON validity after update
if python3 -c "import json; json.load(open('$TMP/metrics/agent-health.json'))" 2>/dev/null; then
  pass "metrics result is valid JSON"
else
  fail "metrics result is invalid JSON"
fi

# 2h: verify the new entry exists
if python3 -c "
import json
with open('$TMP/metrics/agent-health.json') as f:
    d = json.load(f)
dates = [e['date'] for e in d['daily']]
assert '2026-03-01' in dates, 'new date not found'
" 2>/dev/null; then
  pass "metrics new entry was appended"
else
  fail "metrics new entry not found in daily array"
fi

# 2i: deduplication
bash "$PATCHED_METRICS" \
  --file agent-health \
  --data '{"date":"2026-03-01","agents":{"mother":{"sessions":5,"errors":1}}}' 2>/dev/null

COUNT="$(python3 -c "
import json
with open('$TMP/metrics/agent-health.json') as f:
    d = json.load(f)
print(sum(1 for e in d['daily'] if e['date']=='2026-03-01'))
")"

if [[ "$COUNT" -eq 1 ]]; then
  pass "metrics deduplicates same-date entries"
else
  fail "metrics has duplicate date entries (count=$COUNT)"
fi

# 2j: verify dedup kept new value
SESSIONS="$(python3 -c "
import json
with open('$TMP/metrics/agent-health.json') as f:
    d = json.load(f)
for e in d['daily']:
    if e['date']=='2026-03-01':
        print(e['agents']['mother']['sessions'])
")"
if [[ "$SESSIONS" -eq 5 ]]; then
  pass "metrics dedup updated to latest value"
else
  fail "metrics dedup did not update value (sessions=$SESSIONS)"
fi

echo ""

# SECTION 3: update-eval.sh
echo "--- update-eval.sh ---"

# 3a: --help exits 0
run_test "eval --help exits 0" \
  bash "$APPLY_DIR/update-eval.sh" --help

# 3b: invalid field fails
if bash "$APPLY_DIR/update-eval.sh" --id creator_satisfaction --field badfield --value 0.9 2>/dev/null; then
  fail "eval invalid field should fail"
else
  pass "eval invalid field rejects"
fi

# 3c: invalid id fails
if bash "$APPLY_DIR/update-eval.sh" --id nonexistent_id --field threshold --value 0.9 2>/dev/null; then
  fail "eval invalid criteria id should fail"
else
  pass "eval invalid criteria id rejects"
fi

# 3d: dry-run shows diff
EVAL_DRYRUN="$(bash "$APPLY_DIR/update-eval.sh" \
  --id creator_satisfaction --field threshold --value 0.8 --dry-run 2>&1)"

if echo "$EVAL_DRYRUN" | grep -q "\[dry-run\]"; then
  pass "eval dry-run shows [dry-run] prefix"
else
  fail "eval dry-run missing [dry-run] prefix"
fi

# 3e: dry-run shows criteria info
if echo "$EVAL_DRYRUN" | grep -q "creator_satisfaction"; then
  pass "eval dry-run shows criteria id"
else
  fail "eval dry-run missing criteria id"
fi

# 3f: actual write to tmp
PATCHED_EVAL="$TMP/update-eval-patched.sh"
sed "s|REPO_ROOT=.*|REPO_ROOT=\"$TMP\"|" "$APPLY_DIR/update-eval.sh" > "$PATCHED_EVAL"
chmod +x "$PATCHED_EVAL"

bash "$PATCHED_EVAL" \
  --id creator_satisfaction --field threshold --value 0.85 2>&1 | \
  grep -q "Updated" && pass "eval write reports 'Updated'" || fail "eval write missing 'Updated'"

# 3g: verify YAML validity after update
if python3 -c "import yaml; yaml.safe_load(open('$TMP/eval-criteria.yaml'))" 2>/dev/null; then
  pass "eval result is valid YAML"
else
  fail "eval result is invalid YAML"
fi

# 3h: verify threshold was updated
THRESH="$(python3 -c "
import yaml
with open('$TMP/eval-criteria.yaml') as f:
    d = yaml.safe_load(f)
for c in d['criteria']:
    if c['id'] == 'creator_satisfaction':
        print(c['threshold'])
")"
if [[ "$THRESH" == "0.85" ]]; then
  pass "eval threshold value correctly updated"
else
  fail "eval threshold not updated correctly (got '$THRESH')"
fi

# 3i: verify last_updated was set
LAST_UPDATED="$(python3 -c "
import yaml
with open('$TMP/eval-criteria.yaml') as f:
    d = yaml.safe_load(f)
print(d.get('last_updated',''))
")"
TODAY="$(date '+%Y-%m-%d')"
if [[ "$LAST_UPDATED" == "$TODAY" ]]; then
  pass "eval last_updated set to today"
else
  fail "eval last_updated not updated (got '$LAST_UPDATED', expected '$TODAY')"
fi

# 3j: backup was created
BACKUP_COUNT="$(ls "$TMP"/eval-criteria.yaml.bak.* 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$BACKUP_COUNT" -ge 1 ]]; then
  pass "eval backup file created"
else
  fail "eval backup file not found"
fi

# 3k: test enabled field update
bash "$PATCHED_EVAL" \
  --id geo_score_trend --field enabled --value false 2>/dev/null

ENABLED="$(python3 -c "
import yaml
with open('$TMP/eval-criteria.yaml') as f:
    d = yaml.safe_load(f)
for c in d['criteria']:
    if c['id'] == 'geo_score_trend':
        print(c['enabled'])
")"
if [[ "$ENABLED" == "False" ]]; then
  pass "eval enabled field updated to false"
else
  fail "eval enabled field not updated (got '$ENABLED')"
fi

echo ""

# SECTION 4: push-knowledge.sh
echo "--- push-knowledge.sh ---"

# 4a: --help exits 0
run_test "push --help exits 0" \
  bash "$APPLY_DIR/push-knowledge.sh" --help

# 4b: missing commit message fails
if bash "$APPLY_DIR/push-knowledge.sh" 2>/dev/null; then
  fail "push missing message should fail"
else
  pass "push missing commit message rejects"
fi

# 4c: dry-run on actual repo shows git status
PUSH_DRYRUN="$(bash "$APPLY_DIR/push-knowledge.sh" --dry-run 'test: dry run commit' 2>&1)"

if echo "$PUSH_DRYRUN" | grep -qE '\[dry-run\]|Nothing to commit'; then
  pass "push dry-run shows expected output"
else
  fail "push dry-run output unexpected: $PUSH_DRYRUN"
fi

# 4d: dry-run on repo with changes
PUSH_TMP="$(mktemp -d)"
cp -r "$REPO_ROOT/.git" "$PUSH_TMP/"
cp -r "$REPO_ROOT/lessons" "$PUSH_TMP/"
cp -r "$REPO_ROOT/metrics" "$PUSH_TMP/"
cp "$REPO_ROOT/eval-criteria.yaml" "$PUSH_TMP/"

echo "# test change" >> "$PUSH_TMP/lessons/mother.md"

PATCHED_PUSH="$TMP/push-knowledge-patched.sh"
sed "s|REPO_ROOT=.*|REPO_ROOT=\"$PUSH_TMP\"|" "$APPLY_DIR/push-knowledge.sh" > "$PATCHED_PUSH"
chmod +x "$PATCHED_PUSH"

PUSH_DRYRUN2="$(bash "$PATCHED_PUSH" --dry-run 'test: push dry-run with changes' 2>&1)"

if echo "$PUSH_DRYRUN2" | grep -q "\[dry-run\]"; then
  pass "push dry-run shows [dry-run] with pending changes"
else
  fail "push dry-run missing [dry-run] output"
fi

if echo "$PUSH_DRYRUN2" | grep -qE 'mother\.md|modified'; then
  pass "push dry-run lists changed files"
else
  fail "push dry-run does not show changed files"
fi

rm -rf "$PUSH_TMP"

echo ""

# SUMMARY
TOTAL=$((PASS + FAIL))
echo "=============================="
echo "Results: $PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
  echo "Failed tests:"
  for e in "${ERRORS[@]}"; do
    echo "  - $e"
  done
  echo "=============================="
  exit 1
else
  echo "All tests passed!"
  echo "=============================="
fi
