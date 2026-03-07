---
name: project-setup
description: This skill should be used when the user asks to "set up a project", "initialize project", "project scaffolding", "create AGENTS.md for a new project", "project-setup", or mentions "프로젝트 초기 설정". Provides a 4-step sequential workflow for initializing any new project with documentation, agent instructions, multi-agent coordination, and tooling recommendations.
---

# Project Setup

A 4-step sequential workflow for initializing new projects. Each step builds on the previous one. Steps can be executed individually via `/project-setup-1` through `/project-setup-4`, or run as a complete workflow.

## Prerequisites

Before starting, ensure:
- A conversation has occurred covering project concept, tech stack, and architecture decisions
- The current working directory is the project root (or an empty directory for new projects)
- Git is initialized (`git init` if needed)
- Use `main` as the default Git branch (`git init -b main` for new repos, or `git branch -M main` after init if needed)

## Step 1: Document Research

Compile everything discussed in the conversation into a structured reference document.

### Actions

1. Create `docs/` directory if it doesn't exist
2. Write `docs/references.md` using the template from `references/templates.md`
3. Populate all sections from conversation context: concept, tech stack rationale, architecture decisions, external references, and open questions
4. Include prior art, competitor analysis, or benchmarks if discussed

### Output
- `docs/references.md`

## Step 2: Create AGENTS.md

Generate a production-quality AGENTS.md tailored to the project, then symlink CLAUDE.md.

### Actions

1. Read `docs/references.md` for project context
2. Invoke the `agents-md-creator` skill — follow its full workflow (Codebase Discovery → Generate → Symlink)
3. Write `AGENTS.md` at project root with project-specific content:
   - Project structure and key entry points
   - Build, dev, test, lint commands (file-scoped first)
   - Code standards (Do / Don't with concrete examples)
   - Verification steps after code changes
   - Testing patterns and framework
   - Commit conventions
   - Secrets and environment safety
4. Create symlink: `ln -sf AGENTS.md CLAUDE.md`
5. Quality check — every command copy-pasteable, file paths reference real files, no generic advice

### Output
- `AGENTS.md`
- `CLAUDE.md` → symlink to `AGENTS.md`

### Key Principle

The output must be universal — readable and useful by Claude Code, Codex CLI, Gemini CLI, and Cursor alike. Avoid tool-specific syntax.

## Step 3: Multi-Agent Coordination

Set up shared coordination files so multiple agents can track progress and stay aligned.

### Actions

1. Create `.context/` directory
2. Create `.context/TASKS.md` — use template from `references/templates.md`
   - Populate initial tasks based on `docs/references.md` and `AGENTS.md`
   - Status symbols: `[ ]` pending, `[~]` in progress, `[x]` done, `[!]` blocked
   - Agent column: CLI instance or agent name (e.g., `CLI-1`, `Codex`)
3. Create `.context/STEERING.md` — use template from `references/templates.md`
   - Current priority, constraints, decisions log
4. Append **Multi-Agent Coordination** section to `AGENTS.md` — use template from `references/templates.md`
   - Rule: read `.context/TASKS.md` and `.context/STEERING.md` before starting any task
   - Rule: update TASKS.md on task start (`[~]`) and completion (`[x]`)
5. Commit on success:
   ```bash
   git add .context/TASKS.md .context/STEERING.md AGENTS.md
   git commit -m "chore: set up multi-agent coordination (.context/)"
   ```

### Output
- `.context/TASKS.md`
- `.context/STEERING.md`
- `AGENTS.md` (updated)

## Step 4: Propose Agents & Skills

Analyze the project and recommend custom agents and skills for effective multi-agent development.

### Actions

1. Read project context: `docs/references.md`, `AGENTS.md`, `.context/TASKS.md`, `.context/STEERING.md`
2. Review existing agents (`~/.claude/agents/`) and skills (`~/.claude/skills/`)
3. Identify which existing agents/skills are directly useful
4. Propose new agents and skills using the formats from `references/templates.md`
   - Always include the table format for agent/skill recommendations
   - When ownership splits cleanly by directory or module, also include an `Agent Roles` section with per-agent ownership, role, and skill assignments
5. Present the full proposal and **WAIT for user confirmation** before creating anything

### Output
- Conversation output (proposal tables)
- No files created until user confirms

## Step Execution

When invoked for a specific step only (via `/project-setup-N`):
- Execute only the requested step
- Assume prior steps have been completed
- If a required input file is missing (e.g., `docs/references.md` for Step 2), warn and offer to run the prerequisite step first

When invoked as a full workflow:
- Execute steps 1 through 4 in order
- Pause after each step for user review before proceeding

## Additional Resources

- **[references/templates.md](references/templates.md)** — Detailed templates for all output files
- **`~/.agents/skills/agents-md-creator/SKILL.md`** — Referenced in Step 2 for AGENTS.md generation
