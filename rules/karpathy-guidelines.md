---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
license: MIT
---

# Karpathy Guidelines

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**MUST distinguish observed facts, assumptions, and open questions. MUST surface uncertainty explicitly. SHOULD surface tradeoffs.**

Before implementing:
- MUST distinguish observed facts, assumptions, and open questions in separate bullets.
- If information is uncertain, MUST state what is uncertain and ask for the missing detail.
- If multiple interpretations exist, MUST present the alternatives and state which one you recommend.
- If a simpler approach exists, SHOULD propose it and explain why it is sufficient.
- If something remains unclear, MUST stop, name the ambiguity, and ask one clarifying question.

## 2. Simplicity First

**MUST write the minimum code that solves the problem. SHOULD prefer concrete solutions over speculative flexibility.**

- MUST implement only the requested features.
- MUST use direct, single-purpose code when the solution is single-use.
- If "flexibility" or "configurability" is not requested, SHOULD choose the simplest concrete behavior that satisfies the current requirement.
- SHOULD add error handling only for realistic scenarios you can name.
- If a 50-line solution solves the same problem as a 200-line solution, MUST use the 50-line solution.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**MUST touch only what is necessary. MUST clean up only your own mess.**

When editing existing code:
- MUST keep edits scoped to the lines required by the task.
- MUST leave adjacent code, comments, and formatting unchanged unless the task requires changes.
- MUST leave working code unrefactored unless the task requires it.
- MUST match the existing style, even if you would choose a different style.
- SHOULD mention unrelated dead code and leave it unchanged.

When your changes create orphans:
- MUST remove imports, variables, and functions that YOUR changes made unused.
- SHOULD leave pre-existing dead code unchanged unless removal is requested.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**MUST define success criteria before coding. MUST verify each step before declaring success.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
