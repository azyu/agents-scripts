#!/usr/bin/env bash
# Stub that spawns a child process (simulates CLI spawning subprocesses).
# The child sleeps forever; used to test orphan process cleanup.

# Spawn a background child that writes its PID to a file
CHILD_PID_FILE="${ORC_ORPHAN_CHILD_PID_FILE:-/tmp/orc-test-orphan-child.pid}"

sleep 9999 &
CHILD_PID=$!
echo "$CHILD_PID" > "$CHILD_PID_FILE"

# Parent also sleeps forever (will be killed by timeout)
sleep 9999
