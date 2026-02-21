---
name: agents-md-creator
description: Create or update AGENTS.md files for any codebase. Use when user asks to "create AGENTS.md", "add CLAUDE.md", "set up agent instructions", "write coding agent config", "improve my AGENTS.md", or wants to configure AI coding assistants (Claude Code, Cursor, Codex, Gemini CLI, Copilot) for their project. Analyzes the codebase and generates a production-quality AGENTS.md based on patterns from top open-source repositories.
---

# AGENTS.md Creator

Generate or update AGENTS.md files following patterns from top repositories (Next.js 128k★, OpenAI Codex 25k★, Elasticsearch 72k★, JetBrains IntelliJ 19.7k★). Based on analysis of 10+ high-profile repos and academic research (2,926 repos).

## Key Principles

1. **Concrete > Abstract** — File paths and examples beat generic advice
2. **Short is better** — 100-300 lines sweet spot. Every line must earn its tokens
3. **Trial-and-error driven** — Same mistake twice → add a rule
4. **File-scoped commands first** — Single-file checks (seconds) over full builds (minutes)
5. **Symlink strategy** — AGENTS.md as canonical, symlink CLAUDE.md/GEMINI.md to it

## Workflow

### Phase 1: Codebase Discovery

Before writing anything, gather context by exploring:

1. **Project type & stack** — Read `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `build.gradle`, or equivalent
2. **Directory structure** — Map top-level layout, identify key directories
3. **Existing config** — Check for `.cursorrules`, `.github/copilot-instructions.md`, existing `CLAUDE.md` or `AGENTS.md`
4. **Build/test/lint commands** — Find actual commands from config files or scripts
5. **Code patterns** — Sample 2-3 files to detect conventions (naming, imports, state management, error handling)
6. **Monorepo detection** — Check for workspaces, multiple packages, nested build systems
7. **Test framework** — Identify testing stack and patterns used

### Phase 2: Generate AGENTS.md

Use the **Section Priority Table** to decide what to include. Start with Tier 1 (mandatory), add Tier 2 (recommended), include Tier 3 only when relevant.

| Tier | Section | Include When |
|------|---------|-------------|
| **1** | Project Structure | Always |
| **1** | Build/Test/Lint Commands | Always |
| **1** | Code Change Verification | Always |
| **1** | Do's & Don'ts | Always |
| **2** | Commit & PR Guidelines | Project uses git |
| **2** | Secrets & Env Safety | Project has env vars or API keys |
| **2** | Testing Patterns | Project has tests |
| **2** | Anti-patterns / Gotchas | Project has known pitfalls |
| **2** | Good/Bad Example Files | Mix of old and new code exists |
| **3** | Cross-tool Symlinks | Multiple AI tools used |
| **3** | Module-specific Rules | Monorepo or large codebase |
| **3** | Safety & Permissions | Autonomous agent usage |
| **3** | Context Efficiency | Large codebase (500+ files) |
| **3** | When Stuck Protocol | Complex projects |

For detailed patterns and templates for each section, see [references/section-catalog.md](references/section-catalog.md).

### Phase 3: Symlink Setup

After creating AGENTS.md, suggest symlinks:

```bash
ln -sf AGENTS.md CLAUDE.md
ln -sf AGENTS.md GEMINI.md
```

### Phase 4: Update Mode

When updating an existing AGENTS.md:

1. Read the existing file completely
2. Identify which Tier 1-2 sections are missing
3. Check if existing content contradicts current codebase patterns
4. Add missing sections, update stale content, preserve custom rules
5. Never remove user's custom rules unless explicitly asked

## Output Skeleton

The generated AGENTS.md must follow this structure (omit sections not applicable):

```markdown
# AGENTS.md

> **Note:** `CLAUDE.md` is a symlink to `AGENTS.md`.

## Project Structure
[directory tree + key entry points]

## Build & Development
[exact commands: dev, build, test, lint — file-scoped first]

## Code Standards
### Do
[concrete rules with library versions, patterns]
### Don't
[explicit prohibitions]

## After Code Changes
[mandatory verification steps in order]

## Testing
[framework, patterns, file organization]

## Commit & PR
[convention, checklist]

## Secrets & Environment
[safety rules]

## Known Gotchas
[project-specific pitfalls]
```

## Quality Checklist

Before delivering, verify:

- [ ] Every command is copy-pasteable (no unexplained placeholders)
- [ ] File paths reference real files that exist in the repo
- [ ] Library versions match what's actually installed
- [ ] Build commands match actual package.json scripts / Makefile targets
- [ ] No generic advice — every line is project-specific
- [ ] Under 300 lines (split into nested AGENTS.md for monorepos if needed)
- [ ] Includes file-scoped commands where possible

## References

- **[references/section-catalog.md](references/section-catalog.md)** — Detailed patterns and templates for each section with real examples. Read when writing any specific section.
- **[references/real-examples.md](references/real-examples.md)** — Curated excerpts from Next.js, OpenAI Codex, Elasticsearch, JetBrains, etc. Read when needing inspiration for a specific project type.
