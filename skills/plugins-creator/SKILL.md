---
name: plugins-creator
description: Guide for creating Claude Code plugins with skills, commands, agents, hooks, and MCP servers. Use when users want to create a new plugin, convert standalone config to plugin, or add components to existing plugins.
---

# Creating Claude Code Plugins

## When to Use Plugins vs Standalone Configuration

**Use a Plugin when:**
- Distributing to others (team, community, marketplace)
- Bundling multiple related components (skills + agents + hooks)
- Creating reusable, versioned configurations
- Building domain-specific Claude extensions

**Use Standalone Configuration when:**
- Personal customizations only
- Single-purpose additions
- Experimentation before packaging

## Plugin Architecture

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: manifest
├── commands/                 # Optional: slash commands (/plugin:command)
│   └── command-name.md
├── skills/                   # Optional: skill definitions
│   └── my-skill/
│       ├── SKILL.md
│       └── scripts/
├── agents/                   # Optional: agent definitions
│   └── my-agent.md
├── hooks/                    # Optional: hook definitions
│   └── hooks.json           # MUST be hooks.json (runtime auto-loads this name)
├── mcp/                      # Optional: MCP server configs
│   └── servers.json
├── CLAUDE.md                 # Optional: plugin-level instructions (auto-injected)
├── README.md
└── LICENSE
```

## Creation Workflow

### Step 1: Initialize Plugin

```bash
python ~/.claude/skills/plugins-creator/scripts/init_plugin.py <plugin-name> [options]

# Options:
#   --skills      Include skills directory
#   --commands    Include commands directory
#   --agents      Include agents directory
#   --hooks       Include hooks directory
#   --mcp         Include MCP configuration
#   --all         Include all component types
```

### Step 2: Configure Manifest

Edit `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "description": "What the plugin does and when to use it",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "optional@email.com"
  }
}
```

### Step 3: Add Components

**Add a Skill:**
```bash
mkdir -p my-plugin/skills/my-skill
# Create my-plugin/skills/my-skill/SKILL.md with frontmatter
```

**Add a Command:**
```bash
mkdir -p my-plugin/commands
# Create my-plugin/commands/my-command.md with frontmatter
```

**Add an Agent:**
```bash
mkdir -p my-plugin/agents
# Create my-plugin/agents/my-agent.md with YAML frontmatter
```

**Add Hooks:**
```bash
mkdir -p my-plugin/hooks
# Create my-plugin/hooks/hooks.json (MUST be this filename)
```

### Step 4: Validate Plugin

```bash
python ~/.claude/skills/plugins-creator/scripts/validate_plugin.py <plugin-path>
```

### Step 5: Test Plugin

```bash
claude --plugin-dir ./my-plugin
```

### Step 6: Iterate

Refine based on usage. Keep SKILL.md files concise (<500 lines).

## Component Quick Reference

### Skills (SKILL.md)

```yaml
---
name: skill-name
description: What it does. When to use it.
---

# Instructions here
```

### Commands (command-name.md)

```yaml
---
name: command-name
description: What this command does
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/run.sh:*)
---

"$ARGUMENTS"

## Instructions
What Claude should do.
```

### Agents (agent-name.md)

```yaml
---
name: agent-name
description: Agent purpose
tools:
  - Read
  - Grep
  - Glob
model: sonnet  # or opus, haiku
---

# Agent instructions here
```

### Hooks (hooks.json)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/pre-bash.sh"
          }
        ]
      }
    ]
  }
}
```

> **Note:** Always use `${CLAUDE_PLUGIN_ROOT}` for paths in hook commands. Never use absolute paths.

## Migration: Standalone to Plugin

1. Create plugin directory with `init_plugin.py`
2. Move files to appropriate directories:
   - `~/.claude/skills/my-skill/` → `my-plugin/skills/my-skill/`
   - `~/.claude/agents/my-agent.md` → `my-plugin/agents/my-agent.md`
3. Update any hardcoded paths to use `${CLAUDE_PLUGIN_ROOT}`
4. Validate and test

## Hook Registration Patterns

| Pattern | Example | How hooks are registered |
|---------|---------|------------------------|
| Plugin (marketplace) | hookify, superpowers | `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` → runtime auto-loads |
| Standalone installer | peon-ping | Installer writes absolute paths into `settings.json` |
| Manual | obsidian-plan-sync | User manually edits `settings.json` |

## Marketplace Registration

To publish a plugin, add a `marketplace.json` at the repo root:

```json
{
  "name": "marketplace-name",
  "owner": { "name": "github-username" },
  "plugins": [
    { "name": "plugin-name", "source": "./plugin-dir", "description": "..." }
  ]
}
```

**Install flow:** `claude plugin install github:owner/repo/plugin-name` → cache → `installed_plugins.json` → `enabledPlugins`

## Resources

For detailed documentation, read:
- `~/.claude/skills/plugins-creator/references/plugin-reference.md`

For templates:
- `~/.claude/skills/plugins-creator/assets/plugin.json.template`
- `~/.claude/skills/plugins-creator/assets/SKILL.md.template`
