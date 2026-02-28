#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/.agents"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/pre-symlink-$(date +%Y%m%d-%H%M%S)"

# Targets to symlink: source → destination
declare -a TARGETS=(
  "AGENTS.md:CLAUDE.md"
  "agents:agents"
  "skills:skills"
  "rules:rules"
)

log()  { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "\033[33m!\033[0m %s\n" "$1"; }
err()  { printf "\033[31m✗\033[0m %s\n" "$1" >&2; }

backup() {
  local target="$1"
  if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    log "Created backup dir: $BACKUP_DIR"
  fi
  cp -R "$target" "$BACKUP_DIR/"
  log "Backed up: $target → $BACKUP_DIR/"
}

if [ ! -d "$REPO_DIR" ]; then
  err "Repo not found at $REPO_DIR"
  exit 1
fi

if [ ! -d "$CLAUDE_DIR" ]; then
  err "$CLAUDE_DIR not found"
  exit 1
fi

echo "Installing symlinks: $REPO_DIR → $CLAUDE_DIR"
echo ""

for entry in "${TARGETS[@]}"; do
  src_name="${entry%%:*}"
  dst_name="${entry##*:}"
  src="$REPO_DIR/$src_name"
  dst="$CLAUDE_DIR/$dst_name"

  if [ ! -e "$src" ]; then
    warn "Source not found, skipping: $src"
    continue
  fi

  # Already correct symlink
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log "Already linked: $dst_name"
    continue
  fi

  # Existing file/dir — backup then remove
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup "$dst"
    rm -rf "$dst"
  fi

  ln -s "$src" "$dst"
  log "Linked: $dst_name → $src"
done

echo ""
echo "Done. Verify with: ls -la ~/.claude/{CLAUDE.md,agents,skills,rules}"
