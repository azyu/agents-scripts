#!/usr/bin/env bash
# test-timeout.sh — Tests timeout behavior with a slow stub.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    printf "\033[32mPASS\033[0m %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "\033[31mFAIL\033[0m %s\n  expected: %s\n  actual:   %s\n" "$label" "$expected" "$actual"
    FAIL=$((FAIL + 1))
  fi
}

# --- Setup ---

TEAM_DIR="$TEST_DIR/.orc/teams/test-timeout"
WORKER_DIR="$TEAM_DIR/workers/codex-1"
mkdir -p "$WORKER_DIR" "$TEAM_DIR/tasks"
echo "Test task: this will timeout" > "$WORKER_DIR/inbox.md"

export ORC_BASE_DIR="$TEST_DIR"
export ORC_CODEX_BIN="$SCRIPT_DIR/stub-slow.sh"
export ORC_TIMEOUT=3  # 3 second timeout

echo "=== Test: Worker times out after ORC_TIMEOUT seconds ==="
START=$(date +%s)

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-timeout --worker codex-1 --type codex --cwd "$TEST_DIR" \
  2>/dev/null || true

END=$(date +%s)
ELAPSED=$((END - START))

DONE="$WORKER_DIR/done.json"
assert_eq "done.json exists" "true" "$(test -f "$DONE" && echo true || echo false)"
assert_eq "status is failed" "failed" "$(jq -r '.status' "$DONE")"

# Timeout should complete in roughly ORC_TIMEOUT seconds (allow some margin)
if [[ $ELAPSED -le 10 ]]; then
  printf "\033[32mPASS\033[0m timeout completed in %ds (< 10s)\n" "$ELAPSED"
  PASS=$((PASS + 1))
else
  printf "\033[31mFAIL\033[0m timeout took %ds (expected < 10s)\n" "$ELAPSED"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
