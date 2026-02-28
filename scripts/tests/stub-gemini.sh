#!/usr/bin/env bash
# Stub for gemini CLI — outputs fixture JSON.
# Supports: -p <prompt> [--yolo] [--output-format json]
FIXTURE_DIR="$(cd "$(dirname "$0")" && pwd)"
cat "$FIXTURE_DIR/fixture-gemini.json"
