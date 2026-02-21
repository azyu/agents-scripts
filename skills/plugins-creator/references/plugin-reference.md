# Claude Code Plugin Reference

Complete reference documentation for creating Claude Code plugins.

## Plugin Manifest Schema

The `.claude-plugin/plugin.json` file is the required manifest for every plugin.

### Full Schema

```json
{
  "name": "string (required)",
  "description": "string (required)",
  "version": "string (required, semver)",
  "author": {
    "name": "string (required)",
    "email": "string (optional)",
    "url": "string (optional)"
  },
  "repository": "string (optional, URL)",
  "license": "string (optional, e.g., MIT)",
  "keywords": ["string", "array", "optional"],
  "engines": {
    "claude": ">=1.0.0"
  }
}
```

### Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Plugin identifier. Lowercase, alphanumeric, hyphens, underscores. Max 64 chars. |
| `description` | Yes | What the plugin does. Max 1024 chars. Include use cases. |
| `version` | Yes | Semantic version (x.y.z). |
| `author.name` | Yes | Author or organization name. |
| `author.email` | No | Contact email. |
| `author.url` | No | Author website or GitHub profile. |
| `repository` | No | Plugin repository URL. |
| `license` | No | SPDX license identifier. |
| `keywords` | No | Discovery tags for marketplace. |
| `engines.claude` | No | Minimum Claude Code version required. |

## Component Specifications

### Skills

Skills are specialized knowledge bundles that guide Claude through specific tasks.

**Location:** `<plugin>/skills/<skill-name>/SKILL.md`

**Structure:**
```
skills/
└── my-skill/
    ├── SKILL.md        # Required: skill definition
    ├── scripts/        # Optional: executable automation
    ├── references/     # Optional: detailed docs loaded on-demand
    └── assets/         # Optional: templates, files for output
```

**SKILL.md Frontmatter:**
```yaml
---
name: skill-name
description: |
  Multi-line description explaining what the skill does
  and when Claude should use it. This is critical for
  triggering - max 1024 characters.
---
```

**Best Practices:**
- Keep SKILL.md under 500 lines
- Use references/ for detailed documentation
- Use scripts/ for deterministic operations
- Description determines when skill triggers

### Agents

Agents are specialized domain experts with specific tool access.

**Location:** `<plugin>/agents/<agent-name>.md`

**Frontmatter:**
```yaml
---
name: agent-name
description: What this agent specializes in
tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Bash
model: sonnet  # sonnet (default), opus, haiku
---
```

**Available Tools:**
| Tool | Purpose |
|------|---------|
| Read | Read file contents |
| Write | Create/overwrite files |
| Edit | Modify existing files |
| Grep | Search file contents |
| Glob | Find files by pattern |
| Bash | Execute shell commands |
| WebFetch | Fetch web content |
| WebSearch | Search the web |
| Task | Launch sub-agents |

**Model Selection:**
- `haiku`: Fast, cost-effective for simple tasks
- `sonnet`: Balanced for most coding tasks (default)
- `opus`: Deep reasoning for complex architecture

### Hooks

Hooks execute commands at specific points in Claude's workflow.

**Location:** `<plugin>/hooks/<hook-name>.json`

**Hook Types:**

| Type | When | Use Case |
|------|------|----------|
| `PreToolUse` | Before tool executes | Validation, modification, blocking |
| `PostToolUse` | After tool executes | Formatting, logging, verification |
| `Stop` | Session ends | Cleanup, final checks |

**Schema:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "shell command to execute"
          }
        ]
      }
    ],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

**Matcher Options:**
- Exact tool name: `"Bash"`, `"Write"`, `"Edit"`
- Glob pattern: `"*"` (all tools)

**Hook Actions:**
```json
{
  "type": "command",
  "command": "echo 'Hook executed'",
  "timeout": 5000
}
```

### MCP Servers

Model Context Protocol servers provide additional tools and resources.

**Location:** `<plugin>/mcp/servers.json`

**Schema:**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@namespace/mcp-server"],
      "env": {
        "API_KEY": "${env:MY_API_KEY}"
      }
    }
  }
}
```

**Environment Variables:**
- `${env:VAR_NAME}`: Reference environment variable
- Direct values: For non-sensitive configuration

### LSP Configuration

Language Server Protocol configuration for code intelligence.

**Location:** `<plugin>/lsp/config.json`

**Schema:**
```json
{
  "languageServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    }
  }
}
```

## Plugin-Level CLAUDE.md

The `CLAUDE.md` file in the plugin root provides instructions loaded when the plugin is active.

**Location:** `<plugin>/CLAUDE.md`

**Use For:**
- Plugin usage instructions
- Configuration guidance
- Cross-component coordination
- Project-specific context

## Loading Plugins

### Development
```bash
claude --plugin-dir ./my-plugin
```

### Multiple Plugins
```bash
claude --plugin-dir ./plugin-a --plugin-dir ./plugin-b
```

### From Installed Location
Place in `~/.claude/plugins/` for automatic loading.

## Debugging

### Plugin Not Loading
1. Check `.claude-plugin/plugin.json` exists
2. Validate JSON syntax
3. Verify required fields
4. Check directory permissions

### Skill Not Triggering
1. Verify description includes trigger phrases
2. Check SKILL.md frontmatter syntax
3. Ensure name matches directory name

### Agent Not Available
1. Verify frontmatter YAML syntax
2. Check tools list is valid
3. Ensure model is valid (sonnet/opus/haiku)

### Hooks Not Executing
1. Validate JSON syntax
2. Check matcher matches tool name
3. Verify command exists and is executable
4. Check command timeout

## Marketplace Deployment

### Preparation Checklist
- [ ] All components validated
- [ ] README.md with usage instructions
- [ ] LICENSE file included
- [ ] Version follows semver
- [ ] Keywords for discovery
- [ ] Tested with `--plugin-dir`

### Package Structure
```
my-plugin-1.0.0/
├── .claude-plugin/
│   └── plugin.json
├── skills/
├── agents/
├── hooks/
├── CLAUDE.md
├── README.md
└── LICENSE
```

### Versioning
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes
