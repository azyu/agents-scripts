---
name: update-claude
description: Update your CLAUDE.md so you don't make that mistake again. Use after Claude makes a mistake to add a rule preventing the same error in future sessions.
---

# Update Claude Skill

When invoked, analyze the recent conversation to identify what went wrong and create a rule to prevent it from happening again.

## Workflow

### Step 1: Identify the Mistake

Review the recent conversation to understand:
- What action Claude took that was wrong
- What the user expected instead
- Why the mistake occurred (misunderstanding, wrong assumption, etc.)

If the mistake is unclear, ask the user:
> "I want to make sure I capture this correctly. What specifically did I do wrong?"

### Step 2: Formulate a Rule

Create a concise, actionable guideline that:
- Uses imperative form ("Do X" or "Never do Y")
- Is specific enough to prevent the exact mistake
- Is general enough to apply to similar situations
- Includes a brief rationale if helpful

**Good examples:**
- "Always ask for confirmation before deleting files"
- "When modifying config files, create a backup first"
- "Never assume the user wants TypeScript - ask about language preference"

**Bad examples:**
- "Be more careful" (too vague)
- "Don't make mistakes" (not actionable)

### Step 3: Update CLAUDE.md

Append the rule to `./CLAUDE.md` in the project root:

1. If `./CLAUDE.md` doesn't exist, create it with this structure:
   ```markdown
   # Project Guidelines

   ## Learned Rules

   - [Your rule here]
   ```

2. If it exists but has no "## Learned Rules" section, add the section at the end

3. If the section exists, append the new rule as a bullet point

### Step 4: Confirm

Tell the user:
- What rule was added
- Where it was saved
- That future sessions will follow this rule

## Important Notes

- Keep rules concise (1-2 sentences max)
- One rule per mistake - don't over-generalize
- If a similar rule already exists, consider updating it instead of adding a duplicate
