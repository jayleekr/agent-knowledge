#!/bin/bash
# ops/test-all.sh — Run all test suites and report summary

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "$SCRIPT_DIR/../tests" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

run_suite() {
  local name="$1"
  local path="$2"

  echo ""
  echo "════════════════════════════════════════"
  echo "  Suite: $name"
  echo "════════════════════════════════════════"

  if [[ ! -f "$path" ]]; then
    echo "  SKIP: $path not found"
    ((TOTAL_FAIL++)) || true
    FAILED_SUITES+=("$name (file missing)")
    return
  fi

  if [[ ! -x "$path" ]]; then
    echo "  SKIP: $path not executable"
    ((TOTAL_FAIL++)) || true
    FAILED_SUITES+=("$name (not executable)")
    return
  fi

  local output exit_code=0
  output=$(bash "$path" 2>&1) || exit_code=$?

  echo "$output"

  # Parse PASS/FAIL counts from output
  local suite_pass suite_fail
  suite_pass=$(echo "$output" | grep -oE 'PASS(ED)?[^0-9]*([0-9]+)' | grep -oE '[0-9]+' | tail -1 || echo "0")
  suite_fail=$(echo "$output"  | grep -oE 'FAIL(ED)?[^0-9]*([0-9]+)' | grep -oE '[0-9]+' | tail -1 || echo "0")

  # Fallback: count [PASS] and [FAIL] lines if summary not found
  if [[ -z "$suite_pass" || "$suite_pass" == "0" ]]; then
    local pass_count fail_count
    pass_count=$(echo "$output" | grep -c '^\[PASS\]\|^PASS:' || true)
    fail_count=$(echo "$output"  | grep -c '^\[FAIL\]\|^FAIL:' || true)
    suite_pass=$pass_count
    suite_fail=$fail_count
  fi

  ((TOTAL_PASS += suite_pass)) || true
  ((TOTAL_FAIL += suite_fail)) || true

  if [[ $exit_code -ne 0 ]]; then
    FAILED_SUITES+=("$name")
  fi
}

echo "════════════════════════════════════════"
echo "  ops/test-all.sh — Running all suites"
echo "════════════════════════════════════════"

run_suite "test_collect"     "$TESTS_DIR/test_collect.sh"
run_suite "test_analyze"     "$TESTS_DIR/test_analyze.sh"
run_suite "test_apply"       "$TESTS_DIR/test_apply.sh"
run_suite "test_integration" "$TESTS_DIR/test_integration.sh"

TOTAL=$((TOTAL_PASS + TOTAL_FAIL))

echo ""
echo "════════════════════════════════════════"
echo "  FINAL SUMMARY"
echo "════════════════════════════════════════"
echo "  Passed: $TOTAL_PASS / $TOTAL"
echo "  Failed: $TOTAL_FAIL / $TOTAL"

if [[ ${#FAILED_SUITES[@]} -gt 0 ]]; then
  echo ""
  echo "  Failed suites:"
  for s in "${FAILED_SUITES[@]}"; do
    echo "    ✗ $s"
  done
  echo "════════════════════════════════════════"
  exit 1
else
  echo ""
  echo "  All suites passed!"
  echo "════════════════════════════════════════"
fi
