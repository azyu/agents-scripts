# Tools

the full tool catalog if it exists.

## gh
- GitHub CLI for PRs/issues/CI/releases. Given issue/PR URL: use gh, not web search.
- Examples: gh issue view <url> --comments, gh pr view <url> --comments --files, gh pr list, gh pr create, gh run list, gh api <endpoint>.
- Uses -R owner/repo flag (or defaults from current repo context).

## bb
- Bitbucket Cloud CLI for PRs/issues/pipelines.
- Examples: bb pr list, bb issue list, bb pr create, bb pipeline list, bb api <endpoint>.
- Uses --workspace and --repo flags (or defaults from current repo context).

## tmux
- Use only when you need persistence/interaction (debugger/server).
- Quick refs: `tmux new -d -s codex-shell`, `tmux attach -t codex-shell`, `tmux list-sessions`, `tmux kill-session -t codex-shell`.

## orchestrate (multi-CLI worker)
- Delegates tasks to Codex CLI and Gemini CLI via tmux workers.
- Scripts: `~/.agents/scripts/orchestrate-{start,status,collect}.sh`
- Routing: architecture/backend → codex, frontend/UI → gemini.
- Workflow: write tasks.json → `orchestrate-start.sh` → poll `orchestrate-status.sh` → `orchestrate-collect.sh`.
- State lives in `<project>/.orc/` (auto-gitignored).
- Use the `/orchestrate` skill for full protocol details.
