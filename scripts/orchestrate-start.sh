#!/usr/bin/env bash
# orchestrate-start.sh — Create a team, spawn tmux workers.
# Usage: orchestrate-start.sh --team <name> --tasks <tasks.json> [--cwd <dir>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=orchestrate-lib.sh
source "$SCRIPT_DIR/orchestrate-lib.sh"

# --- Parse args ---

TEAM=""
TASKS_FILE=""
CWD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team)  TEAM="$2";       shift 2 ;;
    --tasks) TASKS_FILE="$2"; shift 2 ;;
    --cwd)   CWD="$2";        shift 2 ;;
    *) orch_err "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$TEAM" || -z "$TASKS_FILE" ]]; then
  orch_err "Usage: orchestrate-start.sh --team <name> --tasks <tasks.json> [--cwd <dir>]"
  exit 1
fi

CWD="${CWD:-$(pwd)}"
export ORC_BASE_DIR="$CWD"

# --- Validate inputs ---

if [[ ! -f "$TASKS_FILE" ]]; then
  orch_err "Tasks file not found: $TASKS_FILE"
  exit 1
fi

# Validate JSON
if ! jq empty "$TASKS_FILE" 2>/dev/null; then
  orch_err "Invalid JSON: $TASKS_FILE"
  exit 1
fi

orch_require_cmd jq
orch_require_cmd tmux

# Validate team name — reject special characters that could break tmux
if [[ ! "$TEAM" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  orch_err "Invalid team name: '$TEAM' (only alphanumeric, hyphen, underscore allowed)"
  exit 1
fi

# Check for required CLI binaries based on task worker_types
CODEX_BIN="${ORC_CODEX_BIN:-codex}"
GEMINI_BIN="${ORC_GEMINI_BIN:-gemini}"

NEEDS_CODEX=$(jq -r '[.[].worker_type] | if index("codex") then "yes" else "no" end' "$TASKS_FILE")
NEEDS_GEMINI=$(jq -r '[.[].worker_type] | if index("gemini") then "yes" else "no" end' "$TASKS_FILE")

if [[ "$NEEDS_CODEX" == "yes" ]]; then
  orch_require_cmd "$CODEX_BIN" "codex"
fi
if [[ "$NEEDS_GEMINI" == "yes" ]]; then
  orch_require_cmd "$GEMINI_BIN" "gemini"
fi

# Check for team name conflict
TMUX_SESSION="orc-${TEAM}"
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  orch_err "Team already exists: $TEAM (tmux session: $TMUX_SESSION)"
  exit 1
fi

# --- Create directory structure ---

orch_ensure_gitignore
TEAM_DIR="$(orch_team_dir "$TEAM" --create)"

TASK_COUNT=$(jq 'length' "$TASKS_FILE")
orch_log "Creating team '$TEAM' with $TASK_COUNT tasks"

# Write config.json
CONFIG_JSON=$(jq -n \
  --arg team "$TEAM" \
  --arg cwd "$CWD" \
  --arg created_at "$(orch_now)" \
  --argjson task_count "$TASK_COUNT" \
  '{team: $team, cwd: $cwd, created_at: $created_at, task_count: $task_count}')
orch_write_json "$TEAM_DIR/config.json" "$CONFIG_JSON"

# Write individual task files and create worker directories
WORKER_NAMES=()
for i in $(seq 0 $(( TASK_COUNT - 1 ))); do
  TASK=$(jq ".[$i]" "$TASKS_FILE")
  TASK_ID=$(echo "$TASK" | jq -r '.id')
  WORKER_TYPE=$(echo "$TASK" | jq -r '.worker_type')
  DESCRIPTION=$(echo "$TASK" | jq -r '.description')

  # Write task file
  orch_write_json "$TEAM_DIR/tasks/${TASK_ID}.json" "$TASK"

  # Create worker directory
  WORKER_NAME="${WORKER_TYPE}-${TASK_ID}"
  WORKER_DIR="$TEAM_DIR/workers/$WORKER_NAME"
  mkdir -p "$WORKER_DIR"

  # Write inbox.md
  printf '%s\n' "$DESCRIPTION" > "$WORKER_DIR/inbox.md"

  WORKER_NAMES+=("$WORKER_NAME")
done

# --- Create tmux session and spawn workers ---

orch_log "Creating tmux session: $TMUX_SESSION"
tmux new-session -d -s "$TMUX_SESSION" -x 200 -y 50

FIRST=true
for i in $(seq 0 $(( TASK_COUNT - 1 ))); do
  TASK=$(jq ".[$i]" "$TASKS_FILE")
  TASK_ID=$(echo "$TASK" | jq -r '.id')
  WORKER_TYPE=$(echo "$TASK" | jq -r '.worker_type')
  MODEL=$(echo "$TASK" | jq -r '.model // empty')
  WORKER_NAME="${WORKER_TYPE}-${TASK_ID}"

  # Build worker command
  WORKER_CMD="$SCRIPT_DIR/orchestrate-worker.sh --team '$TEAM' --worker '$WORKER_NAME' --type '$WORKER_TYPE' --cwd '$CWD'"
  if [[ -n "$MODEL" ]]; then
    WORKER_CMD="$WORKER_CMD --model '$MODEL'"
  fi

  # Export env vars for the worker
  ENV_PREFIX="export ORC_BASE_DIR='$CWD'"
  if [[ -n "${ORC_TIMEOUT:-}" ]]; then
    ENV_PREFIX="$ENV_PREFIX; export ORC_TIMEOUT='$ORC_TIMEOUT'"
  fi
  if [[ -n "${ORC_CODEX_BIN:-}" ]]; then
    ENV_PREFIX="$ENV_PREFIX; export ORC_CODEX_BIN='$ORC_CODEX_BIN'"
  fi
  if [[ -n "${ORC_GEMINI_BIN:-}" ]]; then
    ENV_PREFIX="$ENV_PREFIX; export ORC_GEMINI_BIN='$ORC_GEMINI_BIN'"
  fi

  if [[ "$FIRST" == true ]]; then
    # Use the initial pane
    tmux send-keys -t "$TMUX_SESSION" "$ENV_PREFIX; $WORKER_CMD" Enter
    FIRST=false
  else
    # Split a new pane — warn if terminal is too small
    if ! tmux split-window -t "$TMUX_SESSION" -v 2>/dev/null; then
      orch_warn "Failed to split tmux pane for $WORKER_NAME (terminal may be too small for $TASK_COUNT panes). Trying new window."
      tmux new-window -t "$TMUX_SESSION"
    fi
    tmux send-keys -t "$TMUX_SESSION" "$ENV_PREFIX; $WORKER_CMD" Enter
    tmux select-layout -t "$TMUX_SESSION" tiled 2>/dev/null || true
  fi

  orch_log "Spawned worker: $WORKER_NAME"
done

# --- Output metadata ---

RESULT_JSON=$(jq -n \
  --arg team "$TEAM" \
  --arg session "$TMUX_SESSION" \
  --arg team_dir "$TEAM_DIR" \
  --argjson task_count "$TASK_COUNT" \
  --argjson workers "$(printf '%s\n' "${WORKER_NAMES[@]}" | jq -R . | jq -s .)" \
  '{team: $team, tmux_session: $session, team_dir: $team_dir, task_count: $task_count, workers: $workers, status: "started"}')

echo "$RESULT_JSON"
orch_log "Team '$TEAM' started. Monitor with: orchestrate-status.sh --team '$TEAM'"
