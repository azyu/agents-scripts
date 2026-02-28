#!/usr/bin/env bash
# orchestrate-status.sh — Check status of all workers in a team.
# Usage: orchestrate-status.sh --team <name> [--json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=orchestrate-lib.sh
source "$SCRIPT_DIR/orchestrate-lib.sh"

# --- Parse args ---

TEAM=""
JSON_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team) TEAM="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    *) orch_err "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$TEAM" ]]; then
  orch_err "Usage: orchestrate-status.sh --team <name> [--json]"
  exit 1
fi

export ORC_BASE_DIR="${ORC_BASE_DIR:-.}"
TEAM_DIR="$(orch_team_dir "$TEAM")"
WORKERS_DIR="$TEAM_DIR/workers"

if [[ ! -d "$WORKERS_DIR" ]]; then
  orch_err "No workers directory: $WORKERS_DIR"
  exit 1
fi

# --- Check each worker ---

RESULTS="[]"
TOTAL=0
COMPLETED=0
RUNNING=0
FAILED=0
CRASHED=0

for worker_dir in "$WORKERS_DIR"/*/; do
  [[ -d "$worker_dir" ]] || continue
  WORKER_NAME=$(basename "$worker_dir")
  TOTAL=$((TOTAL + 1))

  DONE_FILE="$worker_dir/done.json"
  PID_FILE="$worker_dir/pid"

  if [[ -f "$DONE_FILE" ]]; then
    # Worker has finished — read status from done.json
    STATUS=$(jq -r '.status' "$DONE_FILE" 2>/dev/null || echo "unknown")
    EXIT_CODE=$(jq -r '.exit_code' "$DONE_FILE" 2>/dev/null || echo "-1")
    DURATION=$(jq -r '.duration_seconds' "$DONE_FILE" 2>/dev/null || echo "0")

    case "$STATUS" in
      completed) COMPLETED=$((COMPLETED + 1)) ;;
      failed)    FAILED=$((FAILED + 1)) ;;
      crashed)   CRASHED=$((CRASHED + 1)) ;;
    esac

    ENTRY=$(jq -n \
      --arg name "$WORKER_NAME" \
      --arg status "$STATUS" \
      --argjson exit_code "${EXIT_CODE:--1}" \
      --argjson duration "${DURATION:-0}" \
      '{name: $name, status: $status, exit_code: $exit_code, duration_seconds: $duration}')
  else
    # No done.json — check if process is alive
    if [[ -f "$PID_FILE" ]]; then
      WORKER_PID=$(cat "$PID_FILE")
      if kill -0 "$WORKER_PID" 2>/dev/null; then
        STATUS="running"
        RUNNING=$((RUNNING + 1))
      else
        STATUS="crashed"
        CRASHED=$((CRASHED + 1))
      fi
    else
      STATUS="unknown"
      CRASHED=$((CRASHED + 1))
    fi

    ENTRY=$(jq -n \
      --arg name "$WORKER_NAME" \
      --arg status "$STATUS" \
      '{name: $name, status: $status}')
  fi

  RESULTS=$(echo "$RESULTS" | jq --argjson entry "$ENTRY" '. + [$entry]')
done

ALL_DONE=$(( COMPLETED + FAILED + CRASHED ))

# --- Output ---

if [[ "$JSON_MODE" == true ]]; then
  jq -n \
    --arg team "$TEAM" \
    --argjson total "$TOTAL" \
    --argjson completed "$COMPLETED" \
    --argjson running "$RUNNING" \
    --argjson failed "$FAILED" \
    --argjson crashed "$CRASHED" \
    --argjson all_done "$(( ALL_DONE >= TOTAL ? 1 : 0 ))" \
    --argjson workers "$RESULTS" \
    '{team: $team, total: $total, completed: $completed, running: $running, failed: $failed, crashed: $crashed, all_done: ($all_done == 1), workers: $workers}'
else
  echo "Team: $TEAM"
  echo "Total: $TOTAL | Completed: $COMPLETED | Running: $RUNNING | Failed: $FAILED | Crashed: $CRASHED"
  echo ""
  echo "$RESULTS" | jq -r '.[] | "  \(.name): \(.status)\(if .duration_seconds then " (\(.duration_seconds)s)" else "" end)"'
  echo ""
  if [[ $ALL_DONE -ge $TOTAL ]]; then
    echo "All workers done."
  else
    echo "$RUNNING worker(s) still running."
  fi
fi
