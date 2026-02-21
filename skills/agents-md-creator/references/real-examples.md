# Real Examples — AGENTS.md from Top Repositories

Curated excerpts from production AGENTS.md files. Use as inspiration when writing sections for similar project types.

## Table of Contents

1. [TypeScript Monorepo (Next.js)](#1-typescript-monorepo-nextjs---128k)
2. [Rust CLI (OpenAI Codex)](#2-rust-cli-openai-codex---25k)
3. [Java Monorepo (Elasticsearch)](#3-java-monorepo-elasticsearch---72k)
4. [JVM IDE Monorepo (JetBrains IntelliJ)](#4-jvm-ide-monorepo-jetbrains-intellij---197k)
5. [React Frontend (Aptos Explorer)](#5-react-frontend-aptos-explorer)
6. [Personal Multi-project (steipete)](#6-personal-multi-project-steipete)
7. [TypeScript Full-stack (Agor)](#7-typescript-full-stack-agor)

---

## 1. TypeScript Monorepo (Next.js) — 128k★

**Notable patterns**: Fast local dev workflow, mode-specific test commands, context efficiency, PR triage skills.

### Fast Local Dev (standout section)
```markdown
## Fast Local Development

**1. Start watch build in background:**
pnpm --filter=next dev
# Auto-rebuilds on file changes (~1-2s per change vs ~60s full build)

**2. Run tests fast:**
NEXT_SKIP_ISOLATE=1 NEXT_TEST_MODE=dev pnpm testonly test/path/to/test.ts

**3. For type errors only:**
pnpm --filter=next types  # (~10s) instead of pnpm --filter=next build (~60s)
```

### Mode-specific Tests
```markdown
- pnpm test-dev-turbo — Development mode with Turbopack (default)
- pnpm test-dev-webpack — Development mode with Webpack
- pnpm test-start-turbo — Production build+start with Turbopack
- pnpm test-start-webpack — Production build+start with Webpack
```

### Context Efficiency
```markdown
## Context-Efficient Workflows

**Reading large files** (>500 lines):
- Grep first to find relevant line numbers, then read targeted ranges
- Never re-read the same section without code changes in between
- For generated files (dist/, node_modules/, .next/): search only, don't read

**Build & test output:**
- Capture to file once, then analyze: pnpm build 2>&1 | tee /tmp/build.log
- Don't re-run the same test command without code changes
```

### Test Writing Rules
```markdown
- Use retry() from next-test-utils instead of setTimeout for waiting
- Do NOT use check() — it is deprecated. Use retry() + expect() instead
- Prefer real fixture directories over inline files objects
- Use pnpm new-test to generate new test suites (mandatory)
```

---

## 2. Rust CLI (OpenAI Codex) — 25k★

**Notable patterns**: Clippy rules, snapshot testing workflow, API conventions, conditional test running.

### Rust Code Style
```markdown
- Always collapse if statements per clippy collapsible_if
- Always inline format! args when possible per clippy uninlined_format_args
- Use method references over closures when possible
- When possible, make match statements exhaustive — avoid wildcard arms
- Do not create small helper methods that are referenced only once
```

### Run-then-escalate Test Strategy
```markdown
1. Run the test for the specific project: cargo test -p codex-tui
2. Once those pass, if changes in common/core/protocol, run cargo test
   Avoid --all-features for routine local runs.

Run just fmt automatically after Rust code changes; do not ask for approval.
```

### Snapshot Testing
```markdown
Any change that affects user-visible UI must include insta snapshot coverage.

- Run tests: cargo test -p codex-tui
- Check pending: cargo insta pending-snapshots -p codex-tui
- Review: cargo insta show -p codex-tui path/to/file.snap.new
- Accept: cargo insta accept -p codex-tui
```

### API Naming Conventions
```markdown
- *Params for request payloads, *Response for responses, *Notification for notifications
- RPC methods as resource/method, keep resource singular (thread/read, app/list)
- camelCase on the wire with #[serde(rename_all = "camelCase")]
- Timestamps: integer Unix seconds (i64), named *_at (created_at, updated_at)
```

---

## 3. Java Monorepo (Elasticsearch) — 72k★

**Notable patterns**: Testing hierarchy, formatting rules, logging conventions, backward compatibility.

### Test Type Selection
```markdown
### Test Types
- Unit Tests: Preferred. Extend ESTestCase.
- Single Node: Extend ESSingleNodeTestCase (lighter than full integ test).
- Integration: Extend ESIntegTestCase.
- REST API: Extend ESRestTestCase. YAML based REST tests are preferred.
```

### Testing Philosophy
```markdown
- Use real classes over mocks or stubs for unit tests
- Ensure mocks or stubs are well-documented and clearly indicate why they were necessary
- Prefer deep equals comparisons over field-by-field assertions
```

### Logging Conventions
```markdown
- Use org.elasticsearch.logging.LogManager & Logger
- Always parameterized: logger.debug("operation [{}]", value) — never concatenation
- Wrap expensive construction in () -> suppliers for TRACE/DEBUG
- TRACE: verbose dev diagnostics
- DEBUG: detailed production troubleshooting
- INFO: operational milestones
- WARN: actionable problems
- ERROR: unrecoverable states only
```

### Backward Compatibility
```markdown
For changes to a Writeable implementation, add a new
  public static final <NAME> = TransportVersion.fromName("<name>")
and use it in the new code paths. Generate: ./gradlew generateTransportVersion
```

---

## 4. JVM IDE Monorepo (JetBrains IntelliJ) — 19.7k★

**Notable patterns**: Tool hierarchy, module-specific overrides, semantic tools over text search.

### Tool Priority Order
```markdown
## Tools (use in this order)

### ijproxy (required when available)
- Read: mcp__ijproxy__read_file
- Edit: mcp__ijproxy__apply_patch
- Search symbols (preferred): mcp__ijproxy__search_symbol

### jetbrains MCP (fallback)
- Read: get_file_text_by_path
- Edit: replace_text_in_file

### Client fallback (no MCP)
- Use ./tools/fd.cmd (file search) and ./tools/rg.cmd (text search)
```

### Module-specific Overrides
```markdown
## Module-specific rules

If a file you touch lives under one of these roots,
you must activate that module's rules first:

- Product DSL: read ./.claude/rules/product-dsl.md
- AI Assistant: follow plugins/llm/activation/.ai/guidelines.md
```

---

## 5. React Frontend (Aptos Explorer)

**Notable patterns**: Multi-agent roles, Kanban task management, cross-tool symlinks.

### Cross-tool Compatibility
```markdown
This document is symlinked as CLAUDE.md, GEMINI.md, WARP.md,
and .github/copilot-instructions.md for cross-tool compatibility.
```

### Agent Roles (7 specialized)
```markdown
1. Architect — Product roadmap, technical architecture
2. Coder — Implementation with tracking
3. Reviewer — Code quality
4. Tester — Unit, E2E, visual regression
5. QA/Auditor — Security and performance
6. Cost Cutter — Deployment cost optimization
7. Modernizer — Framework updates, refactoring
```

### Kanban Task Flow
```markdown
Tasks flow through stages in .agents/tasks/:
  backlog.md → ready.md → in-progress.md → review.md → done.md
```

---

## 6. Personal Multi-project (steipete)

**Notable patterns**: Telegraph style (minimal tokens), tool catalog, git safety defaults.

### Telegraph Style
```markdown
Peter owns this. Start: say hi + 1 motivating line.
Work style: telegraph; noun-phrases ok; drop grammar; min tokens.
```

### Git Safety Defaults
```markdown
## Git
- Safe by default: git status/diff/log. Push only when user asks.
- Branch changes require user consent.
- Destructive ops forbidden unless explicit (reset --hard, clean, restore, rm).
- No amend unless asked.
- Multi-agent: check git status/diff before edits; ship small commits.
```

### Guardrails
```markdown
- use trash for deletes (not rm)
- Keep files <~500 LOC; split/refactor as needed
- Fix root cause (not band-aid)
- Unsure: read more code; if still stuck, ask w/ short options
```

---

## 7. TypeScript Full-stack (Agor)

**Notable patterns**: Context-driven development, progressive disclosure, watch mode rules.

### Context-Driven Development
```markdown
## IMPORTANT: Context-Driven Development

This file is intentionally high-level.
Detailed documentation lives in context/.

When working on a task, you are EXPECTED to:
1. Read the relevant context/ docs based on your task
2. Fetch on-demand rather than trying to hold everything in context
3. Start with context/README.md if unsure where to look

The context/ folder is the source of truth. Use CLAUDE.md as a map, not a manual.
```

### Watch Mode Rules
```markdown
IMPORTANT FOR AGENTS:
- User runs dev environment in watch mode (daemon + UI)
- DO NOT run pnpm build or compilation commands unless explicitly asked
- DO NOT start background processes — user manages these
- Focus on code edits; watch mode handles recompilation automatically
```

### Adding a New Feature Checklist
```markdown
1. Read relevant context/ docs first
2. Check context/concepts/models.md for data models
3. Update types in packages/core/src/types/
4. Add repository layer in packages/core/src/db/repositories/
5. Create service in apps/agor-daemon/src/services/
6. Register in apps/agor-daemon/src/index.ts
7. Add CLI command (if needed)
8. Add UI component (if needed)
```
