#!/usr/bin/env bash
# test-worker.sh — Tests orchestrate-worker.sh with stub CLIs.
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

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf "\033[32mPASS\033[0m %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "\033[31mFAIL\033[0m %s (not found: '%s')\n" "$label" "$needle"
    FAIL=$((FAIL + 1))
  fi
}

# --- Setup ---

setup_team() {
  local worker_type="$1"
  local team_dir="$TEST_DIR/.orc/teams/test-team"
  local worker_dir="$team_dir/workers/${worker_type}-1"
  mkdir -p "$worker_dir" "$team_dir/tasks"
  echo "Test task: say hello" > "$worker_dir/inbox.md"
  echo "$team_dir"
}

# --- Test 1: Codex worker with stub ---

echo "=== Test 1: Codex worker produces done.json ==="
setup_team "codex" > /dev/null
TEAM_DIR="$TEST_DIR/.orc/teams/test-team"

export ORC_BASE_DIR="$TEST_DIR"
export ORC_CODEX_BIN="$SCRIPT_DIR/stub-codex.sh"
export ORC_TIMEOUT=30

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-team --worker codex-1 --type codex --cwd "$TEST_DIR" \
  2>/dev/null || true

DONE="$TEAM_DIR/workers/codex-1/done.json"
assert_eq "done.json exists" "true" "$(test -f "$DONE" && echo true || echo false)"
assert_eq "status is completed" "completed" "$(jq -r '.status' "$DONE")"
assert_eq "exit_code is 0" "0" "$(jq -r '.exit_code' "$DONE")"
assert_contains "output has codex text" "Hello from Codex" "$(jq -r '.output' "$DONE")"

# --- Test 2: Gemini worker with stub ---

echo ""
echo "=== Test 2: Gemini worker produces done.json ==="
rm -rf "$TEST_DIR/.orc"
setup_team "gemini" > /dev/null

export ORC_GEMINI_BIN="$SCRIPT_DIR/stub-gemini.sh"

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-team --worker gemini-1 --type gemini --cwd "$TEST_DIR" \
  2>/dev/null || true

DONE="$TEST_DIR/.orc/teams/test-team/workers/gemini-1/done.json"
assert_eq "done.json exists" "true" "$(test -f "$DONE" && echo true || echo false)"
assert_eq "status is completed" "completed" "$(jq -r '.status' "$DONE")"
assert_contains "output has gemini text" "Hello from Gemini" "$(jq -r '.output' "$DONE")"

# --- Test 3: Empty inbox ---

echo ""
echo "=== Test 3: Empty inbox produces failed done.json ==="
rm -rf "$TEST_DIR/.orc"
TEAM_DIR="$(setup_team "codex")"
true > "$TEAM_DIR/workers/codex-1/inbox.md"  # empty file

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-team --worker codex-1 --type codex --cwd "$TEST_DIR" \
  2>/dev/null || true

DONE="$TEAM_DIR/workers/codex-1/done.json"
assert_eq "done.json exists" "true" "$(test -f "$DONE" && echo true || echo false)"
assert_eq "status is failed" "failed" "$(jq -r '.status' "$DONE")"

# --- Test 4: PID file written ---

echo ""
echo "=== Test 4: PID file is written ==="
rm -rf "$TEST_DIR/.orc"
setup_team "codex" > /dev/null

"$SCRIPT_DIR/../orchestrate-worker.sh" \
  --team test-team --worker codex-1 --type codex --cwd "$TEST_DIR" \
  2>/dev/null || true

PID_FILE="$TEST_DIR/.orc/teams/test-team/workers/codex-1/pid"
assert_eq "pid file exists" "true" "$(test -f "$PID_FILE" && echo true || echo false)"

# --- Summary ---

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
