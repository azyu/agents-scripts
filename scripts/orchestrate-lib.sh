#!/usr/bin/env bash
# orchestrate-lib.sh — Common functions for tmux CLI worker orchestration.
# Source this file: source "$(dirname "$0")/orchestrate-lib.sh"

set -euo pipefail

# --- Logging ---

orch_log()  { printf "\033[32m[orc]\033[0m %s\n" "$1"; }
orch_warn() { printf "\033[33m[orc]\033[0m %s\n" "$1" >&2; }
orch_err()  { printf "\033[31m[orc]\033[0m %s\n" "$1" >&2; }

# --- Path helpers ---

# Returns and validates .orc/teams/$1 path. Creates if --create flag given.
# Usage: orch_team_dir <team-name> [--create]
orch_team_dir() {
  local team="$1"
  local create="${2:-}"
  local base_dir
  base_dir="${ORC_BASE_DIR:-.}/.orc/teams/${team}"

  if [[ "$create" == "--create" ]]; then
    mkdir -p "$base_dir"/{tasks,workers}
  elif [[ ! -d "$base_dir" ]]; then
    orch_err "Team directory not found: $base_dir"
    return 1
  fi
  printf '%s' "$base_dir"
}

# Ensures .orc/.gitignore exists with "*" content.
orch_ensure_gitignore() {
  local orc_dir="${ORC_BASE_DIR:-.}/.orc"
  mkdir -p "$orc_dir"
  if [[ ! -f "$orc_dir/.gitignore" ]]; then
    printf '*\n' > "$orc_dir/.gitignore"
  fi
}

# --- Dependency checks ---

# Checks that a command exists in PATH.
# Usage: orch_require_cmd <cmd> [<display-name>]
orch_require_cmd() {
  local cmd="$1"
  local name="${2:-$1}"
  if ! command -v "$cmd" &>/dev/null; then
    orch_err "Required command not found: $name ($cmd)"
    return 1
  fi
}

# --- JSON helpers ---

# Atomic JSON write: writes to .tmp then moves.
# Usage: orch_write_json <file> <json-string>
orch_write_json() {
  local file="$1"
  local json="$2"
  local tmp="${file}.tmp.$$"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$json" > "$tmp"
  mv -f "$tmp" "$file"
}

# Read a JSON field using jq.
# Usage: orch_read_json <file> <jq-filter>
orch_read_json() {
  local file="$1"
  local filter="$2"
  if [[ ! -f "$file" ]]; then
    orch_err "JSON file not found: $file"
    return 1
  fi
  jq -r "$filter" "$file"
}

# --- Timeout ---

# Run a command with a timeout (pure bash, macOS compatible).
# Usage: orch_timeout_run <seconds> <command> [args...]
orch_timeout_run() {
  local timeout_sec="$1"; shift
  "$@" &
  local cmd_pid=$!
  ( sleep "$timeout_sec" && kill -TERM "$cmd_pid" 2>/dev/null ) &
  local watchdog_pid=$!
  wait "$cmd_pid" 2>/dev/null
  local exit_code=$?
  kill "$watchdog_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null 2>&1 || true
  return "$exit_code"
}

# --- Timestamp ---

# ISO 8601 timestamp.
orch_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}
