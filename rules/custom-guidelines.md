## Subagents

- When you launch subagents, wait for every launched subagent to complete before yielding to the user.
- Launch subagents when work items are independent, parallelizable, or slow enough that a worker can make progress without blocking the main agent.
- Keep dependent or high-context work on the primary agent unless the subagent can receive all required context explicitly.
- If a subagent fails or times out, collect the completed results, state what is missing, and either retry with narrower instructions or finish the remaining work on the primary agent.

## Bug Fixing Workflow

**Reproduce first. Fix second. Prove with tests.**

When a bug is reported:
1. Reproduce the bug before changing code.
2. If an automated reproduction is feasible, write or identify a failing test first (RED).
3. If automation is not feasible, capture the manual reproduction steps and state why automated coverage is impractical before fixing.
4. Fix the bug with the smallest change that makes the reproduction pass, whether on the primary agent or via subagents.
5. Declare the bug fixed only after the reproduction check passes again and the nearest affected checks are rerun.
