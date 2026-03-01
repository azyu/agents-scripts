#!/usr/bin/env bash
# orchestrate-collect.sh — Collect results and clean up.
# Usage: orchestrate-collect.sh --team <name> [--keep-session] [--json] [--cleanup]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=orchestrate-lib.sh
source "$SCRIPT_DIR/orchestrate-lib.sh"

# --- Parse args ---

TEAM=""
KEEP_SESSION=false
JSON_MODE=false
CLEANUP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team)         TEAM="$2"; shift 2 ;;
    --keep-session) KEEP_SESSION=true; shift ;;
    --json)         JSON_MODE=true; shift ;;
    --cleanup)      CLEANUP=true; shift ;;
    *) orch_err "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$TEAM" ]]; then
  orch_err "Usage: orchestrate-collect.sh --team <name> [--keep-session] [--json] [--cleanup]"
  exit 1
fi

export ORC_BASE_DIR="${ORC_BASE_DIR:-.}"
TEAM_DIR="$(orch_team_dir "$TEAM")"
WORKERS_DIR="$TEAM_DIR/workers"
TMUX_SESSION="orc-${TEAM}"

if [[ ! -d "$WORKERS_DIR" ]]; then
  orch_err "No workers directory: $WORKERS_DIR"
  exit 1
fi

# --- Helper: write crash marker for dead workers ---

write_crash_done() {
  local done="$1"
  local json
  json=$(jq -n \
    --arg status "crashed" \
    --arg completed_at "$(orch_now)" \
    '{status: $status, exit_code: 1, output: "Worker died without producing done.json", duration_seconds: 0, completed_at: $completed_at}')
  orch_write_json "$done" "$json"
}

# --- Check all workers are done ---

STILL_RUNNING=0
for worker_dir in "$WORKERS_DIR"/*/; do
  [[ -d "$worker_dir" ]] || continue
  WORKER_NAME=$(basename "$worker_dir")
  DONE_FILE="$worker_dir/done.json"
  PID_FILE="$worker_dir/pid"

  if [[ ! -f "$DONE_FILE" ]]; then
    # Check if process is alive
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      STILL_RUNNING=$((STILL_RUNNING + 1))
      orch_warn "Worker still running: $WORKER_NAME"
    else
      # Dead without done.json — write crash marker
      orch_warn "Worker crashed without done.json: $WORKER_NAME"
      write_crash_done "$DONE_FILE"
    fi
  fi
done

if [[ $STILL_RUNNING -gt 0 ]]; then
  orch_err "$STILL_RUNNING worker(s) still running. Wait for completion or kill them."
  exit 1
fi

# --- Collect results ---

RESULTS="[]"
for worker_dir in "$WORKERS_DIR"/*/; do
  [[ -d "$worker_dir" ]] || continue
  WORKER_NAME=$(basename "$worker_dir")
  DONE_FILE="$worker_dir/done.json"

  if [[ -f "$DONE_FILE" ]]; then
    ENTRY=$(jq --arg name "$WORKER_NAME" '. + {name: $name}' "$DONE_FILE")
    RESULTS=$(echo "$RESULTS" | jq --argjson entry "$ENTRY" '. + [$entry]')
  fi
done

TOTAL=$(echo "$RESULTS" | jq 'length')
SUCCEEDED=$(echo "$RESULTS" | jq '[.[] | select(.status == "completed")] | length')
FAILED_COUNT=$(echo "$RESULTS" | jq '[.[] | select(.status != "completed")] | length')

# --- Clean up tmux session ---

if [[ "$KEEP_SESSION" == false ]]; then
  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    tmux kill-session -t "$TMUX_SESSION"
    orch_log "Killed tmux session: $TMUX_SESSION"
  fi
fi

# --- Output ---

SUMMARY=$(jq -n \
  --arg team "$TEAM" \
  --argjson total "$TOTAL" \
  --argjson succeeded "$SUCCEEDED" \
  --argjson failed "$FAILED_COUNT" \
  --argjson results "$RESULTS" \
  '{team: $team, total: $total, succeeded: $succeeded, failed: $failed, results: $results}')

if [[ "$JSON_MODE" == true ]]; then
  echo "$SUMMARY"
else
  echo "Team: $TEAM — $SUCCEEDED/$TOTAL succeeded"
  echo ""
  echo "$RESULTS" | jq -r '.[] | "[\(.status)] \(.name) (\(.duration_seconds)s)\n  \(.output | split("\n") | .[0])\n"'
fi

# --- Optional cleanup of team directory ---

if [[ "$CLEANUP" == true ]]; then
  # Safety: re-check no workers are running before deleting
  for worker_dir in "$WORKERS_DIR"/*/; do
    [[ -d "$worker_dir" ]] || continue
    PID_FILE="$worker_dir/pid"
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      orch_err "Cannot cleanup: worker $(basename "$worker_dir") still running"
      exit 1
    fi
  done
  rm -rf "$TEAM_DIR"
  orch_log "Cleaned up team directory: $TEAM_DIR"
fi
