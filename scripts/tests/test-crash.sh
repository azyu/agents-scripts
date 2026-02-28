#!/usr/bin/env bash
# test-crash.sh — Tests crash recovery (EXIT trap writes done.json).
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

# --- Test: CLI crash produces failed done.json ---

echo "=== Test: CLI crash produces done.json with failed status ==="
TEAM_DIR="$TEST_DIR/.orc/teams/test-crash"
WORKER_DIR="$TEAM_DIR/workers/codex-1"
mkdir -p "$WORKER_DIR" "$TEAM_DIR/tasks"
echo "Test task: this will crash" > "$WORKER_DIR/inbox.md"

export ORC_BASE_DIR="$TEST_DIR"
export ORC_CODEX_BIN="$SCRIPT_DIR/stub-crash.sh"
export ORC_TIMEOUT=30

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-crash --worker codex-1 --type codex --cwd "$TEST_DIR" \
  2>/dev/null || true

DONE="$WORKER_DIR/done.json"
assert_eq "done.json exists" "true" "$(test -f "$DONE" && echo true || echo false)"
assert_eq "status is failed" "failed" "$(jq -r '.status' "$DONE")"
assert_eq "exit_code is non-zero" "true" "$(jq -r 'if .exit_code != 0 then "true" else "false" end' "$DONE")"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
