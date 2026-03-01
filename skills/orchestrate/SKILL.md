---
name: orchestrate
description: Use when delegating tasks to Codex CLI or Gemini CLI workers via tmux. Orchestrates multi-model parallel execution with file-based IPC.
---

# tmux CLI Worker Orchestration

Delegate tasks to Codex CLI (GPT-5.3) and Gemini CLI (Gemini 3.1 Pro) as parallel workers.
Claude acts as orchestrator — splitting work, dispatching, polling, and synthesizing results.

## When to Activate

- Multi-model parallel execution needed
- Architecture/backend tasks (route to Codex)
- Frontend/UI tasks (route to Gemini)
- Independent subtasks that benefit from parallel processing
- Cross-model validation or consensus

## Worker Routing Rules

| Domain | Worker | Model |
|--------|--------|-------|
| Architecture, backend, systems, DevOps, DB | Codex CLI | gpt-5.3-codex |
| Frontend, UI/UX, CSS, React, design | Gemini CLI | gemini-3.1-pro |
| Research, analysis, general | Codex CLI | gpt-5.2-codex |

## Orchestration Protocol

### Step 1: Task Decomposition

Break the user's request into self-contained subtasks. Each subtask must:
- Be independently executable (no cross-task dependencies)
- Include ALL context needed (file paths, constraints, patterns)
- Specify expected output format

### Step 2: Write tasks.json

```json
[
  {
    "id": 1,
    "subject": "Short title",
    "description": "Full self-contained instructions for the worker.\nInclude file paths, code context, constraints.\nThe worker has NO access to our conversation.",
    "worker_type": "codex",
    "model": "gpt-5.3-codex"
  },
  {
    "id": 2,
    "subject": "Short title",
    "description": "...",
    "worker_type": "gemini",
    "model": "gemini-3.1-pro"
  }
]
```

### Step 3: Start Workers

```bash
~/.agents/scripts/orchestrate-start.sh \
  --team "<team-name>" \
  --tasks /path/to/tasks.json \
  --cwd "$(pwd)"
```

### Step 4: Poll Status

```bash
# Check status (repeat until all done)
~/.agents/scripts/orchestrate-status.sh --team "<team-name>" --json
```

Poll every 10-30 seconds. Workers typically complete in 30-120 seconds.

### Step 5: Collect Results

```bash
~/.agents/scripts/orchestrate-collect.sh --team "<team-name>" --json
```

### Step 6: Synthesize

Review all worker outputs. Resolve conflicts. Apply changes. Report to user.

## Writing Good Inbox Instructions

Workers run in isolated contexts with NO access to our conversation history.
Every inbox.md must be completely self-contained:

```markdown
# Task: [Clear Title]

## Context
- Project: [path and description]
- Tech stack: [relevant technologies]
- Files involved: [absolute paths]

## Current State
[What exists now — paste relevant code snippets if needed]

## Required Changes
[Step-by-step instructions]

## Constraints
- [Style guide, naming conventions]
- [Performance requirements]
- [Compatibility requirements]

## Expected Output
[What the worker should produce]
```

## Error Recovery

| Situation | Action |
|-----------|--------|
| Worker timeout (300s default) | Check `ORC_TIMEOUT` env var, increase if needed, retry |
| Worker crash | Check `done.json` for error details, fix instructions, retry |
| CLI not installed | Run `npm i -g @openai/codex` or `npm i -g @google/gemini-cli` |
| Partial results | Collect what succeeded, manually complete failed tasks |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ORC_TIMEOUT` | 300 | Worker timeout in seconds |
| `ORC_BASE_DIR` | `.` (cwd) | Base directory for `.orc/` state |
| `ORC_CODEX_BIN` | `codex` | Path to codex binary (testing) |
| `ORC_GEMINI_BIN` | `gemini` | Path to gemini binary (testing) |

## Runtime State

All state lives in `<project>/.orc/` (auto-gitignored):

```
.orc/
  .gitignore              # Contains: *
  teams/<team-name>/
    config.json
    tasks/{1,2,...}.json
    workers/<type>-<id>/
      inbox.md            # Task instructions
      done.json           # Completion signal + output
      raw.jsonl / raw.json
      pid                 # Worker process PID
```
