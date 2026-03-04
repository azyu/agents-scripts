#!/usr/bin/env bash
# bw-env.sh — Legacy wrapper: delegates to bwenv CLI
# Usage: load_bw_env <item-name>

load_bw_env() {
  local item_name="${1:?Usage: load_bw_env <item-name>}"

  if ! command -v bwenv &>/dev/null; then
    echo "Error: bwenv not found. Ensure ~/.agents/scripts is in PATH" >&2
    return 1
  fi

  # bwenv load outputs export statements; source them
  eval "$(bwenv load "$item_name")"
}
