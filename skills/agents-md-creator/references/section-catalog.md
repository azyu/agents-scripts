# Section Catalog — AGENTS.md Patterns

Detailed templates for each section. Copy and adapt to the target project.

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Build/Test/Lint Commands](#2-buildtestlint-commands)
3. [Code Change Verification](#3-code-change-verification)
4. [Do's & Don'ts](#4-dos--donts)
5. [Commit & PR Guidelines](#5-commit--pr-guidelines)
6. [Secrets & Env Safety](#6-secrets--env-safety)
7. [Testing Patterns](#7-testing-patterns)
8. [Anti-patterns / Gotchas](#8-anti-patterns--gotchas)
9. [Good/Bad Example Files](#9-goodbad-example-files)
10. [Cross-tool Symlinks](#10-cross-tool-symlinks)
11. [Module-specific Rules](#11-module-specific-rules)
12. [Safety & Permissions](#12-safety--permissions)
13. [Context Efficiency](#13-context-efficiency)
14. [When Stuck Protocol](#14-when-stuck-protocol)

---

## 1. Project Structure

**Purpose**: Eliminate the discovery phase. Give agents a map.

**Template**:
```markdown
## Project Structure

project-name/
├── src/                    # Application source code
│   ├── components/         # Reusable UI components
│   ├── lib/                # Shared utilities
│   ├── api/                # API routes / handlers
│   └── types/              # TypeScript type definitions
├── tests/                  # Test suites
├── docs/                   # Documentation
├── scripts/                # Build and maintenance scripts
└── config/                 # Configuration files

### Key Entry Points
- Dev server: `src/index.ts`
- API routes: `src/api/routes/`
- Main config: `config/default.ts`
```

**Best practices**:
- Include only 2-3 levels of depth — enough to orient, not overwhelm
- Mark generated/disposable directories (`dist/`, `node_modules/`, `.next/`)
- Highlight "start here" entry points

**From Next.js**: "Dev server: `src/cli/next-dev.ts` → `src/server/dev/next-dev-server.ts`" — showing the flow, not just the file.

**From Agor**: "The `context/` folder is the source of truth. Use CLAUDE.md as a map, not a manual."

---

## 2. Build/Test/Lint Commands

**Purpose**: Provide exact, copy-pasteable commands. File-scoped first.

**Template**:
```markdown
## Build & Development

### File-scoped checks (preferred — seconds, not minutes)
npx tsc --noEmit path/to/file.ts          # Type check single file
npx prettier --write path/to/file.ts       # Format single file
npx eslint --fix path/to/file.ts           # Lint single file
npx vitest run path/to/file.test.ts        # Test single file

### Project-wide (use sparingly)
pnpm dev                                    # Dev server
pnpm build                                  # Production build
pnpm test                                   # Full test suite
pnpm lint                                   # Full lint

Note: Always run file-scoped checks on changed files.
Use project-wide commands only when explicitly needed.
```

**Best practices**:
- List file-scoped commands BEFORE project-wide commands
- Include the actual package manager the project uses (npm/pnpm/yarn/bun)
- Note when watch mode is running ("DO NOT run `pnpm build` — watch mode handles recompilation")
- For monorepos, show how to target specific packages: `pnpm --filter=next build`

**From Elasticsearch**: Separates commands by scope — single class, single package, full suite, with flags for seed/debug/CI reproduction.

---

## 3. Code Change Verification

**Purpose**: Mandatory post-edit checklist in explicit order.

**Template**:
```markdown
## After Code Changes

Run in this order after any code modification:

1. **Format**: `pnpm prettier --write <changed-files>`
2. **Lint**: `pnpm eslint --fix <changed-files>`
3. **Type check**: `pnpm tsc --noEmit` (or file-scoped)
4. **Test**: Run affected tests — `pnpm vitest run <related-test>`
5. **Build** (only if touching build config or before commit): `pnpm build`
```

**Best practices**:
- Numbered steps, explicit order
- Include the actual commands (not just "run linting")
- Note exceptions: "Skip build step if only modifying `.md` or `.json` files"

**From JetBrains**: "Full Bazel compilation after code changes: run `./bazel-build-all.cmd`. Skip if only `.js`, `.mjs`, `.md`, `.txt`, or `.json` files are modified."

---

## 4. Do's & Don'ts

**Purpose**: Project-specific rules. The most impactful section per token.

**Template**:
```markdown
## Code Standards

### Do
- Use [framework] v[X] — ensure code is v[X] compatible
- Use [state management] for state (e.g., `useLocalStore` for mobx)
- Use design tokens from `path/to/tokens.ts` for all styling
- Default to small components and small diffs
- Import types from `src/types/` — never redefine canonical types

### Don't
- Do not hard-code colors, sizes, or breakpoints
- Do not add new dependencies without checking existing alternatives
- Do not use `any`, `@ts-ignore`, or `@ts-expect-error`
- Do not use wildcard imports
- Do not suppress linter warnings
```

**Best practices**:
- Be specific: "use MUI v3" not "use a component library"
- Include library versions found in package.json/lockfile
- Reference actual file paths for tokens, types, shared utilities
- Keep each rule to one line

---

## 5. Commit & PR Guidelines

**Template**:
```markdown
## Commit & PR

### Commit Messages
Use Conventional Commits: `type(scope): description`

Types: feat | fix | refactor | docs | test | chore | perf | ci

### Before Committing
1. `pnpm fmt` — format code
2. `pnpm lint` — check for errors
3. `pnpm test --run` — run tests (if testable code changed)

### PR Rules
- Keep diffs small and focused
- Do NOT add "Generated with AI" or co-author footers
- Do NOT mark PRs as ready for review — leave in draft
- Include a brief summary of what changed and why
```

**From Next.js**: Explicitly bans AI attribution footers and auto-marking PRs as ready.

---

## 6. Secrets & Env Safety

**Template**:
```markdown
## Secrets & Environment

- Never print, paste, or log secret values (tokens, API keys, cookies)
- Never commit `.env`, credentials, or secret files
- If a required secret is missing, stop and ask — do not invent placeholders
- Use `import.meta.env.VITE_*` (or `process.env.*`) — never hard-code values
- When sharing command output, redact sensitive-looking values
```

**From Next.js**: "Mirror CI env **names and modes** exactly, but do not inline literal secret values in commands."

---

## 7. Testing Patterns

**Template**:
```markdown
## Testing

### Framework
- Unit: Vitest (or Jest)
- Integration: Supertest / Testing Library
- E2E: Playwright

### Conventions
- Test files: `*.test.ts` or `*.test.tsx` beside implementation
- Mock external services — never hit real endpoints in tests
- Prefer real classes over mocks unless the real class is complex
- Focus on behavior, not implementation details

### File Organization
src/
├── components/
│   └── Button/
│       ├── Button.tsx
│       └── Button.test.tsx
└── e2e/
    └── auth.spec.ts
```

**From Elasticsearch**: "Use real classes over mocks or stubs for unit tests. Ensure mocks are well-documented and clearly indicate why they were necessary."

**From OpenAI Codex**: Includes snapshot testing workflow with `cargo insta` — accept/review/pending cycle.

---

## 8. Anti-patterns / Gotchas

**Purpose**: Project-specific traps that waste time. High ROI section.

**Template**:
```markdown
## Known Gotchas

- `NEXT_SKIP_ISOLATE=1` hides module resolution failures — drop it when testing resolution changes
- Snapshot tests vary by env flags — match exact CI flags when updating
- The `app-page.ts` is a build template compiled by the user's bundler — cannot require internal modules with relative paths
- Cache invalidation requires restarting the dev server after changing `config/`
```

**Best practices**:
- Each gotcha should be a real trap you've encountered or can infer from the codebase
- Include the "fix" or workaround inline
- These are NOT generic advice — they are project-specific warnings

---

## 9. Good/Bad Example Files

**Purpose**: Point to concrete files as patterns to follow or avoid.

**Template**:
```markdown
## Code Examples

### Follow these patterns
- Functional components: see `src/components/Dashboard.tsx`
- API handlers: see `src/api/handlers/users.ts`
- Form validation: copy `src/components/forms/CreateUser.tsx`
- Data fetching: use the client in `src/lib/api-client.ts`

### Avoid these patterns (legacy)
- Class-based components like `src/legacy/AdminPanel.tsx`
- Direct fetch() calls like `src/old/fetchData.ts` — use api-client instead
- Inline styles like `src/legacy/OldButton.tsx` — use design tokens
```

---

## 10. Cross-tool Symlinks

**Template**:
```markdown
> **Note:** `CLAUDE.md` and `GEMINI.md` are symlinks to `AGENTS.md`. They are the same file.
```

And include setup instructions at the end:
```bash
ln -sf AGENTS.md CLAUDE.md
ln -sf AGENTS.md GEMINI.md
# ln -sf AGENTS.md .github/copilot-instructions.md
```

---

## 11. Module-specific Rules

**For monorepos or large codebases with directory-specific conventions.**

**Template**:
```markdown
## Module-specific Rules

Special handling applies to these directories. Read the referenced doc before making changes:

- **`packages/core/`**: Follow strict backward compatibility — see `packages/core/CONTRIBUTING.md`
- **`apps/web/`**: Uses App Router (Next.js 14+) — no Pages Router patterns
- **`plugins/`**: Each plugin has its own `AGENTS.md` — follow local rules when present

Module-specific rules override general guidelines when they conflict.
```

**From JetBrains**: Uses `Module/plugin directories may contain their own AGENTS/CLAUDE instructions; follow them when present.`

---

## 12. Safety & Permissions

**Template**:
```markdown
## Safety & Permissions

### Allowed without asking
- Read/search files
- File-scoped lint, format, type check
- Run single test files
- git status, diff, log

### Ask first
- Install new packages
- Delete files
- git push, branch changes
- Run full build or E2E suites
- Modify CI/CD config

### Never (unless explicitly asked)
- git push --force
- git reset --hard
- Delete/modify .env files
- Run chmod or chown
```

---

## 13. Context Efficiency

**For large codebases where token budget matters.**

**Template**:
```markdown
## Context Efficiency

### Reading large files (>500 lines)
- Grep first to find relevant line numbers, then read targeted ranges
- Never re-read the same section without code changes in between

### Generated files
- `dist/`, `node_modules/`, `.next/`: search only, don't read

### Build & test output
- Capture to file once, then analyze: `pnpm build 2>&1 | tee /tmp/build.log`
- Don't re-run the same command without code changes

### Batch edits
- Group related edits across files, then run one build — not build-per-edit
```

---

## 14. When Stuck Protocol

**Template**:
```markdown
## When Stuck

- Ask a clarifying question before guessing
- Propose a short plan with 2-3 options
- Open a draft PR with notes if partial progress is useful
- Do NOT push large speculative changes without confirmation
- Fix root causes, not symptoms — if unsure, read more code first
```
