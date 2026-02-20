#!/bin/bash
set -euo pipefail

# tests/test_analyze.sh — Test suite for ops/analyze/ scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYZE_DIR="$(cd "$SCRIPT_DIR/../ops/analyze" && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1 — $2"; ((FAIL++)) || true; }

# Run cmd, check output with validator python expression
# validator: python3 one-liner that reads stdin and exits 0 on success
assert_json() {
  local name="$1"
  local cmd="$2"
  local check="${3:-}"

  local out
  if ! out=$(eval "$cmd" 2>/dev/null); then
    fail "$name" "command exited non-zero"
    return
  fi

  if ! echo "$out" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    fail "$name" "not valid JSON: $(echo "$out" | head -c 80)"
    return
  fi

  if [[ -n "$check" ]]; then
    if ! echo "$out" | python3 -c "$check" 2>/dev/null; then
      fail "$name" "check failed: $check | output: $(echo "$out" | head -c 120)"
      return
    fi
  fi

  pass "$name"
}

assert_exit0() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    pass "$name"
  else
    fail "$name" "expected exit 0"
  fi
}

assert_nonzero() {
  local name="$1"
  local cmd="$2"
  local code=0
  eval "$cmd" >/dev/null 2>&1 || code=$?
  if [[ $code -ne 0 ]]; then
    pass "$name"
  else
    fail "$name" "expected non-zero exit"
  fi
}

echo "========================================"
echo "  test_analyze.sh"
echo "========================================"

# ── geo-check.sh ──────────────────────────────────────────────
echo ""
echo "[ geo-check.sh ]"
GEO="$ANALYZE_DIR/geo-check.sh"

assert_exit0   "geo-check --help"                        "bash '$GEO' --help"
assert_json    "geo-check --dry-run valid JSON"          "bash '$GEO' --dry-run"
assert_json    "geo-check --dry-run has file+score+grade+findings+suggestions" \
  "bash '$GEO' --dry-run" \
  "import json,sys; d=json.load(sys.stdin); assert all(k in d for k in ['file','score','grade','findings','suggestions'])"
assert_json    "geo-check --dry-run score is int"        "bash '$GEO' --dry-run" \
  "import json,sys; d=json.load(sys.stdin); assert isinstance(d['score'], int)"
assert_json    "geo-check --dry-run grade is str"        "bash '$GEO' --dry-run" \
  "import json,sys; d=json.load(sys.stdin); assert isinstance(d['grade'], str)"
assert_json    "geo-check with sample-article.md"        "bash '$GEO' '$FIXTURES/sample-article.md'"
assert_json    "geo-check article has score+grade"       "bash '$GEO' '$FIXTURES/sample-article.md'" \
  "import json,sys; d=json.load(sys.stdin); assert 'score' in d and 'grade' in d"
assert_json    "geo-check article score 0-100"           "bash '$GEO' '$FIXTURES/sample-article.md'" \
  "import json,sys; d=json.load(sys.stdin); assert 0 <= d['score'] <= 100"
assert_nonzero "geo-check fails missing file"            "bash '$GEO' /tmp/no_such_file_$$"
assert_nonzero "geo-check fails no args"                 "bash '$GEO'"

# ── sentiment.sh ──────────────────────────────────────────────
echo ""
echo "[ sentiment.sh ]"
SENT="$ANALYZE_DIR/sentiment.sh"

assert_exit0   "sentiment --help"                         "bash '$SENT' --help"
assert_json    "sentiment --dry-run valid JSON"           "bash '$SENT' --dry-run"
assert_json    "sentiment --dry-run has required keys"    "bash '$SENT' --dry-run" \
  "import json,sys; d=json.load(sys.stdin); assert all(k in d for k in ['total','positive','negative','neutral','request','ratio'])"
assert_json    "sentiment with sample-messages.json"      "bash '$SENT' '$FIXTURES/sample-messages.json'"
assert_json    "sentiment total = 10"                     "bash '$SENT' '$FIXTURES/sample-messages.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['total'] == 10"
assert_json    "sentiment positive >= 1"                  "bash '$SENT' '$FIXTURES/sample-messages.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['positive'] >= 1"
assert_json    "sentiment negative >= 1"                  "bash '$SENT' '$FIXTURES/sample-messages.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['negative'] >= 1"
assert_json    "sentiment request >= 1"                   "bash '$SENT' '$FIXTURES/sample-messages.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['request'] >= 1"
assert_json    "sentiment counts sum to total"            "bash '$SENT' '$FIXTURES/sample-messages.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['positive']+d['negative']+d['neutral']+d['request'] == d['total']"
assert_json    "sentiment ratio keys present"             "bash '$SENT' '$FIXTURES/sample-messages.json'" \
  "import json,sys; d=json.load(sys.stdin); assert all(k in d['ratio'] for k in ['positive','negative','neutral','request'])"
assert_nonzero "sentiment fails missing file"             "bash '$SENT' /tmp/no_such_file_$$"
assert_nonzero "sentiment fails no args"                  "bash '$SENT'"

# ── trend-compare.sh ──────────────────────────────────────────
echo ""
echo "[ trend-compare.sh ]"
TREND="$ANALYZE_DIR/trend-compare.sh"

assert_exit0   "trend-compare --help"                     "bash '$TREND' --help"
assert_json    "trend-compare --dry-run valid JSON"       "bash '$TREND' --dry-run"
assert_json    "trend-compare --dry-run is array"         "bash '$TREND' --dry-run" \
  "import json,sys; d=json.load(sys.stdin); assert isinstance(d, list)"
assert_json    "trend-compare with sample-metrics.json"   "bash '$TREND' '$FIXTURES/sample-metrics.json' 6"
assert_json    "trend-compare result is array"            "bash '$TREND' '$FIXTURES/sample-metrics.json' 6" \
  "import json,sys; d=json.load(sys.stdin); assert isinstance(d, list) and len(d) > 0"
assert_json    "trend-compare has metric+current+avg_previous+trend+change_pct" \
  "bash '$TREND' '$FIXTURES/sample-metrics.json' 6" \
  "import json,sys; d=json.load(sys.stdin); assert all(all(k in e for k in ['metric','current','avg_previous','trend','change_pct']) for e in d)"
assert_json    "trend-compare trend values valid"         "bash '$TREND' '$FIXTURES/sample-metrics.json' 6" \
  "import json,sys; d=json.load(sys.stdin); assert all(e['trend'] in ['up','down','stable'] for e in d)"
assert_json    "trend-compare avg_score detected"         "bash '$TREND' '$FIXTURES/sample-metrics.json' 6" \
  "import json,sys; d=json.load(sys.stdin); assert any(e['metric']=='avg_score' for e in d)"
assert_nonzero "trend-compare fails missing file"         "bash '$TREND' /tmp/no_such_file_$$"
assert_nonzero "trend-compare fails no args"              "bash '$TREND'"

# ── error-patterns.sh ─────────────────────────────────────────
echo ""
echo "[ error-patterns.sh ]"
ERR="$ANALYZE_DIR/error-patterns.sh"

assert_exit0   "error-patterns --help"                    "bash '$ERR' --help"
assert_json    "error-patterns --dry-run valid JSON"      "bash '$ERR' --dry-run"
assert_json    "error-patterns --dry-run has required keys" "bash '$ERR' --dry-run" \
  "import json,sys; d=json.load(sys.stdin); assert all(k in d for k in ['total_errors','by_agent','top_patterns'])"
assert_json    "error-patterns with sample-sessions.json" "bash '$ERR' '$FIXTURES/sample-sessions.json'"
assert_json    "error-patterns total_errors = 10"         "bash '$ERR' '$FIXTURES/sample-sessions.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['total_errors'] == 10"
assert_json    "error-patterns by_agent has walter"       "bash '$ERR' '$FIXTURES/sample-sessions.json'" \
  "import json,sys; d=json.load(sys.stdin); assert 'walter' in d['by_agent']"
assert_json    "error-patterns walter has 5 errors"       "bash '$ERR' '$FIXTURES/sample-sessions.json'" \
  "import json,sys; d=json.load(sys.stdin); assert d['by_agent']['walter'] == 5"
assert_json    "error-patterns top_patterns is list"      "bash '$ERR' '$FIXTURES/sample-sessions.json'" \
  "import json,sys; d=json.load(sys.stdin); assert isinstance(d['top_patterns'], list)"
assert_json    "error-patterns top pattern is API timeout" "bash '$ERR' '$FIXTURES/sample-sessions.json'" \
  "import json,sys; d=json.load(sys.stdin); p=d['top_patterns']; assert len(p)>0 and p[0]['message']=='API timeout'"
assert_json    "error-patterns top_patterns has count"    "bash '$ERR' '$FIXTURES/sample-sessions.json'" \
  "import json,sys; d=json.load(sys.stdin); assert all('message' in p and 'count' in p for p in d['top_patterns'])"
assert_nonzero "error-patterns fails missing file"        "bash '$ERR' /tmp/no_such_file_$$"
assert_nonzero "error-patterns fails no args"             "bash '$ERR'"

# ── agent-health.json via error-patterns ──────────────────────
echo ""
echo "[ error-patterns with agent-health.json ]"
HEALTH="$(cd "$SCRIPT_DIR/.." && pwd)/metrics/agent-health.json"
assert_json    "error-patterns with agent-health.json"    "bash '$ERR' '$HEALTH'"
assert_json    "agent-health has by_agent"                "bash '$ERR' '$HEALTH'" \
  "import json,sys; d=json.load(sys.stdin); assert isinstance(d['by_agent'], dict)"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [[ $FAIL -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  exit 1
fi
