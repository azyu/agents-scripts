## Subagents

- ALWAYS wait for all subagents to complete before yielding.
- Spawn subagents automatically when:
- Parallelizable work (e.g., install + verify, npm test + typecheck, multiple tasks from plan)
- Long-running or blocking tasks where a worker can run independently. Isolation for risky changes or checks

## Bug Fixing Workflow

**Reproduce first. Fix second. Prove with tests.**

When a bug is reported:
1. Do NOT attempt to fix it immediately.
2. Write a test that reproduces the bug (RED).
3. Spawn subagents to fix the bug and verify the fix passes the test (GREEN).
4. Only declare the bug fixed when the reproduction test passes.
