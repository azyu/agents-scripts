# Tool Selection Rules

- Prefer the narrowest tool that can retrieve authoritative information for the target system.
- If a dedicated CLI exists for the system named in the task, use that CLI before generic web search or manual browsing.
- If the preferred CLI is unavailable, unauthenticated, or missing required context, say so briefly and use the next-best local fallback.

## gh
- Use `gh` when the user provides a GitHub URL or asks about GitHub PRs, issues, Actions, releases, or repository metadata.
- Collect only the fields needed for the task, such as title, state, comments, changed files, or workflow status.
- Prefer `-R owner/repo` when the repository context is ambiguous.
- If `gh` cannot access the target repository, report the limitation and fall back to local `git` data or ask for the missing repository context.

## bb
- Use `bb` when the task targets Bitbucket PRs, issues, or pipelines.
- Include `--workspace` and `--repo` when the current repo context is unclear.
- If `bb` is unavailable or unauthenticated, say that directly and fall back to available local repo data.

## tmux
- Use `tmux` only when the task needs persistence or interactive state, such as a dev server, debugger, or long-running worker.
- Name sessions clearly so they can be resumed or terminated later.
- If persistence is unnecessary, run the command directly instead of adding `tmux` overhead.

## notesmd-cli
- Use `notesmd-cli` for Obsidian vault reads or writes instead of editing vault files blindly.
- Confirm the target vault or note path before writing.
- If the CLI is unavailable, report that and avoid guessing vault structure from memory.
