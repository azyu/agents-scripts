#!/usr/bin/env bash
# Stub for codex CLI — outputs fixture JSONL.
# Supports: exec [--yolo] [--json] [--ephemeral] [-m model] <prompt>
FIXTURE_DIR="$(cd "$(dirname "$0")" && pwd)"
cat "$FIXTURE_DIR/fixture-codex.jsonl"
