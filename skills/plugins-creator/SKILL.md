---
name: plugins-creator
description: Guide for creating Claude Code plugins with skills, agents, hooks, and MCP servers. Use when users want to create a new plugin, convert standalone config to plugin, or add components to existing plugins.
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
├── skills/                   # Optional: skill definitions
│   └── my-skill/
│       ├── SKILL.md
│       └── scripts/
├── agents/                   # Optional: agent definitions
│   └── my-agent.md
├── hooks/                    # Optional: hook definitions
│   └── my-hook.json
├── mcp/                      # Optional: MCP server configs
│   └── servers.json
└── CLAUDE.md                 # Optional: plugin-level instructions
```

## Creation Workflow

### Step 1: Initialize Plugin

```bash
python ~/.claude/skills/plugins-creator/scripts/init_plugin.py <plugin-name> [options]

# Options:
#   --skills      Include skills directory
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

**Add an Agent:**
```bash
mkdir -p my-plugin/agents
# Create my-plugin/agents/my-agent.md with YAML frontmatter
```

**Add Hooks:**
```bash
mkdir -p my-plugin/hooks
# Create my-plugin/hooks/my-hook.json
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

### Hooks (hook-name.json)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Pre-bash hook'"
          }
        ]
      }
    ]
  }
}
```

## Migration: Standalone to Plugin

1. Create plugin directory with `init_plugin.py`
2. Move files to appropriate directories:
   - `~/.claude/skills/my-skill/` → `my-plugin/skills/my-skill/`
   - `~/.claude/agents/my-agent.md` → `my-plugin/agents/my-agent.md`
3. Update any hardcoded paths in scripts
4. Validate and test

## Resources

For detailed documentation, read:
- `~/.claude/skills/plugins-creator/references/plugin-reference.md`

For templates:
- `~/.claude/skills/plugins-creator/assets/plugin.json.template`
- `~/.claude/skills/plugins-creator/assets/SKILL.md.template`
