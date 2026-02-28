# Tools

the full tool catalog if it exists.

## gh
- GitHub CLI for PRs/CI/releases. Given issue/PR URL (or /pull/5): use gh, not web search.
- Examples: gh issue view <url> --comments -R owner/repo, gh pr view <url> --comments --files -R owner/repo.

## tmux
- Use only when you need persistence/interaction (debugger/server).
- Quick refs: `tmux new -d -s codex-shell`, `tmux attach -t codex-shell`, `tmux list-sessions`, `tmux kill-session -t codex-shell`.
