#!/usr/bin/env bash
# test-orphan.sh — Tests that timeout kills child processes (no orphans).
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

TEAM_DIR="$TEST_DIR/.orc/teams/test-orphan"
WORKER_DIR="$TEAM_DIR/workers/codex-1"
mkdir -p "$WORKER_DIR" "$TEAM_DIR/tasks"
echo "Test task: this will spawn orphans" > "$WORKER_DIR/inbox.md"

CHILD_PID_FILE="$TEST_DIR/orphan-child.pid"

export ORC_BASE_DIR="$TEST_DIR"
export ORC_CODEX_BIN="$SCRIPT_DIR/stub-orphan.sh"
export ORC_TIMEOUT=3
export ORC_ORPHAN_CHILD_PID_FILE="$CHILD_PID_FILE"

echo "=== Test: Timeout kills child processes (no orphans) ==="

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-orphan --worker codex-1 --type codex --cwd "$TEST_DIR" \
  2>/dev/null || true

# done.json should exist with failed status
DONE="$WORKER_DIR/done.json"
assert_eq "done.json exists" "true" "$(test -f "$DONE" && echo true || echo false)"
assert_eq "status is failed" "failed" "$(jq -r '.status' "$DONE")"

# The child process should have been killed along with the parent
# Give a moment for process cleanup
sleep 1

if [[ -f "$CHILD_PID_FILE" ]]; then
  CHILD_PID=$(cat "$CHILD_PID_FILE")
  if kill -0 "$CHILD_PID" 2>/dev/null; then
    printf "\033[31mFAIL\033[0m child process %s is still alive (orphan!)\n" "$CHILD_PID"
    # Clean up the orphan
    kill -TERM "$CHILD_PID" 2>/dev/null || true
    FAIL=$((FAIL + 1))
  else
    printf "\033[32mPASS\033[0m child process was killed (no orphan)\n"
    PASS=$((PASS + 1))
  fi
else
  printf "\033[33mSKIP\033[0m child PID file not found (stub may not have started)\n"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
