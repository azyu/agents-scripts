#!/usr/bin/env bash
# orchestrate-worker.sh — Worker wrapper. Runs inside a tmux pane.
# Reads inbox.md, executes CLI, writes done.json.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=orchestrate-lib.sh
source "$SCRIPT_DIR/orchestrate-lib.sh"

# --- Parse args ---

TEAM=""
WORKER=""
WORKER_TYPE=""
MODEL=""
CWD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team)    TEAM="$2";        shift 2 ;;
    --worker)  WORKER="$2";      shift 2 ;;
    --type)    WORKER_TYPE="$2"; shift 2 ;;
    --model)   MODEL="$2";       shift 2 ;;
    --cwd)     CWD="$2";         shift 2 ;;
    *) orch_err "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$TEAM" || -z "$WORKER" || -z "$WORKER_TYPE" ]]; then
  orch_err "Usage: orchestrate-worker.sh --team <name> --worker <name> --type <codex|gemini> [--model <m>] [--cwd <dir>]"
  exit 1
fi

if [[ -n "$CWD" ]]; then
  cd "$CWD" || { orch_err "Cannot cd to $CWD"; exit 1; }
fi

TEAM_DIR="$(orch_team_dir "$TEAM")"
WORKER_DIR="$TEAM_DIR/workers/$WORKER"

if [[ ! -d "$WORKER_DIR" ]]; then
  orch_err "Worker directory not found: $WORKER_DIR"
  exit 1
fi

INBOX="$WORKER_DIR/inbox.md"
DONE_FILE="$WORKER_DIR/done.json"
RAW_FILE="$WORKER_DIR/raw.jsonl"
PID_FILE="$WORKER_DIR/pid"
STDERR_FILE="$WORKER_DIR/stderr.log"

TIMEOUT="${ORC_TIMEOUT:-300}"
CODEX_BIN="${ORC_CODEX_BIN:-codex}"
GEMINI_BIN="${ORC_GEMINI_BIN:-gemini}"

# Track CLI PID for cleanup
CLI_PID_FILE="$WORKER_DIR/.cli_pid"

# --- Crash guard ---

write_done() {
  local status="$1" exit_code="$2" output="$3" duration="$4"
  local completed_at
  completed_at="$(orch_now)"
  local json
  json=$(jq -n \
    --arg status "$status" \
    --argjson exit_code "$exit_code" \
    --arg output "$output" \
    --argjson duration "$duration" \
    --arg completed_at "$completed_at" \
    '{status: $status, exit_code: $exit_code, output: $output, duration_seconds: $duration, completed_at: $completed_at}')
  orch_write_json "$DONE_FILE" "$json"
}

cleanup() {
  # Kill any remaining CLI child processes
  if [[ -f "$CLI_PID_FILE" ]]; then
    local cli_pid
    cli_pid=$(cat "$CLI_PID_FILE" 2>/dev/null) || true
    if [[ -n "$cli_pid" ]] && kill -0 "$cli_pid" 2>/dev/null; then
      # Try process group kill first
      local cli_pgid
      cli_pgid=$(ps -o pgid= -p "$cli_pid" 2>/dev/null | tr -d ' ') || true
      local my_pgid
      my_pgid=$(ps -o pgid= -p $$ 2>/dev/null | tr -d ' ') || true
      if [[ -n "$cli_pgid" && "$cli_pgid" != "$my_pgid" && "$cli_pgid" != "0" ]]; then
        kill -TERM -- -"$cli_pgid" 2>/dev/null || true
      else
        kill -TERM "$cli_pid" 2>/dev/null || true
      fi
    fi
    rm -f "$CLI_PID_FILE"
  fi

  if [[ ! -f "$DONE_FILE" ]]; then
    local elapsed=0
    if [[ -n "${START_TIME:-}" ]]; then
      elapsed=$(( $(date +%s) - START_TIME ))
    fi
    write_done "crashed" 1 "Worker process terminated unexpectedly" "$elapsed"
    orch_warn "Worker $WORKER crashed — done.json written"
  fi
}
trap cleanup EXIT

# --- Read inbox ---

if [[ ! -f "$INBOX" ]]; then
  orch_err "Inbox not found: $INBOX"
  write_done "failed" 1 "inbox.md not found" 0
  exit 1
fi

PROMPT="$(cat "$INBOX")"

if [[ -z "$PROMPT" ]]; then
  orch_err "Empty inbox: $INBOX"
  write_done "failed" 1 "inbox.md is empty" 0
  exit 1
fi

# --- Record PID ---

echo $$ > "$PID_FILE"
orch_log "Worker $WORKER ($$) started — type=$WORKER_TYPE model=${MODEL:-default}"

# --- Execute CLI ---

START_TIME=$(date +%s)

case "$WORKER_TYPE" in
  codex)
    CODEX_ARGS=(exec --yolo --json --ephemeral)
    if [[ -n "$MODEL" ]]; then
      CODEX_ARGS+=(-m "$MODEL")
    fi
    CODEX_ARGS+=("$PROMPT")

    orch_log "Running: $CODEX_BIN ${CODEX_ARGS[*]:0:4} ..."
    if orch_timeout_run "$TIMEOUT" "$CODEX_BIN" "${CODEX_ARGS[@]}" > "$RAW_FILE" 2>"$STDERR_FILE"; then
      CLI_EXIT=0
    else
      CLI_EXIT=$?
    fi
    ;;

  gemini)
    GEMINI_ARGS=(-p "$PROMPT" --yolo --output-format json)
    if [[ -n "$MODEL" ]]; then
      GEMINI_ARGS+=(--model "$MODEL")
    fi

    RAW_FILE="$WORKER_DIR/raw.json"
    orch_log "Running: $GEMINI_BIN -p ... --yolo --output-format json"
    if orch_timeout_run "$TIMEOUT" "$GEMINI_BIN" "${GEMINI_ARGS[@]}" > "$RAW_FILE" 2>"$STDERR_FILE"; then
      CLI_EXIT=0
    else
      CLI_EXIT=$?
    fi
    ;;

  *)
    orch_err "Unknown worker type: $WORKER_TYPE"
    write_done "failed" 1 "Unknown worker type: $WORKER_TYPE" 0
    exit 1
    ;;
esac

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

# --- Parse output ---

OUTPUT=""

if [[ $CLI_EXIT -ne 0 ]]; then
  OUTPUT="CLI exited with code $CLI_EXIT"
  if [[ -f "$RAW_FILE" ]]; then
    OUTPUT="$OUTPUT. Raw tail: $(tail -5 "$RAW_FILE" 2>/dev/null || echo '(empty)')"
  fi
  # Append stderr if available
  if [[ -f "$STDERR_FILE" && -s "$STDERR_FILE" ]]; then
    OUTPUT="$OUTPUT. Stderr: $(tail -20 "$STDERR_FILE" 2>/dev/null || echo '(empty)')"
  fi
  write_done "failed" "$CLI_EXIT" "$OUTPUT" "$DURATION"
  orch_warn "Worker $WORKER failed (exit=$CLI_EXIT, ${DURATION}s)"
  exit 0  # Exit 0 so the trap doesn't overwrite done.json
fi

case "$WORKER_TYPE" in
  codex)
    # Extract last assistant message from JSONL stream using jq stream parsing.
    # Each line is parsed independently; non-JSON lines are silently skipped.
    OUTPUT=$(jq -R 'fromjson? | select(.type == "item.completed") | select(.item.role == "assistant") | [.item.content[]?.text // empty] | join("\n")' "$RAW_FILE" \
      | tail -1 \
      | jq -r '. // empty' 2>/dev/null \
      || true)

    if [[ -z "$OUTPUT" ]]; then
      OUTPUT="(could not parse codex output — see raw.jsonl)"
    fi
    ;;

  gemini)
    OUTPUT=$(jq -r '.response // empty' "$RAW_FILE" 2>/dev/null || true)
    if [[ -z "$OUTPUT" ]]; then
      OUTPUT="(could not parse gemini output — see raw.json)"
    fi
    ;;
esac

write_done "completed" "$CLI_EXIT" "$OUTPUT" "$DURATION"
orch_log "Worker $WORKER completed (${DURATION}s)"
