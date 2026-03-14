# AGENTS.md

Response in Korean.

## Agent Protocol

- Workspace: ~/.agents
- Read the relevant local files before proposing instruction changes or structural rewrites.
- Apply rules in this order: root `AGENTS.md` -> `rules/*` -> invoked skill -> task-local document.
- If two local documents conflict, follow the more specific document unless it contradicts a higher-level rule.
- Separate observed facts, assumptions, and open questions when requirements are incomplete.
- Ask one focused clarifying question only after local inspection cannot resolve an important ambiguity.
- Default to surgical edits. Restructure documents only when the change removes a concrete source of confusion or duplication.
- When writing or rewriting instruction documents, prefer executable `MUST`/`SHOULD` rules with explicit fallback behavior.

## Repository Map

- `rules/`: global operating defaults shared across this workspace
- `skills/`: reusable skills and supporting references; keep file contents in English
- `agents/`: role-specific agent prompts; keep file contents in English
- `orchestrate/`: worker orchestration skill and related materials

## Guidelines

Read these files first:

- `~/.agents/rules/karpathy-guidelines.md`
- `~/.agents/rules/custom-guidelines.md`
- `~/.agents/rules/tools.md`

## Skills

- `instruction-writer`: Use this skill when writing or rewriting prompts, `AGENTS.md`, `CLAUDE.md`, policy docs, or instruction files into clearer model-friendly rules.
