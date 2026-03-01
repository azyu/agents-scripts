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

### Commands

Commands are slash-command definitions that users invoke as `/plugin:command-name`.

**Location:** `<plugin>/commands/<command-name>.md`

**Frontmatter:**
```yaml
---
name: command-name
description: What this command does
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/run.sh:*)
---
```

**Body:**
```markdown
"$ARGUMENTS"

## Instructions

What Claude should do when this command is invoked.
```

**Key Details:**
- `$ARGUMENTS`: Variable replaced with user-provided arguments after the slash command
- `${CLAUDE_PLUGIN_ROOT}`: Runtime variable resolved to the plugin's install path; use in `allowed-tools` to reference scripts within the plugin
- `allowed-tools`: Restricts which tools the command can use; supports glob patterns
- Command names must be lowercase with hyphens

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

**Location:** `<plugin>/hooks/hooks.json`

> **IMPORTANT:** The file MUST be named `hooks.json`. The runtime auto-loads only this filename from the plugin's `hooks/` directory.

**Hook Types:**

| Type | When | Use Case |
|------|------|----------|
| `PreToolUse` | Before tool executes | Validation, modification, blocking |
| `PostToolUse` | After tool executes | Formatting, logging, verification |
| `Stop` | Session ends normally | Cleanup, final checks |
| `UserPromptSubmit` | User submits prompt | Context enrichment |
| `SessionStart` | Session starts | Initialization, state loading |
| `SessionEnd` | Session ends | State saving |
| `PermissionRequest` | Permission prompt shown | Custom approval (e.g., ExitPlanMode) |
| `Notification` | Notification event | Notification routing |
| `SubagentStart` | Subagent created | Context injection |
| `PostToolUseFailure` | Tool execution fails | Error logging |
| `PreCompact` | Before context compaction | State preservation |

**Schema:**
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
    ],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

**Matcher Patterns:**

| Pattern | Description | Example |
|---------|-------------|---------|
| (omitted) | Match ALL events of this type | hookify's catch-all pattern |
| Exact name | Match specific tool/event | `"Bash"`, `"ExitPlanMode"` |
| Pipe-delimited | Match any of listed names | `"startup\|resume\|clear\|compact"` |
| Glob | Wildcard matching | `"*"` |

**Hook Actions:**
```json
{
  "type": "command",
  "command": "echo 'Hook executed'",
  "timeout": 5000
}
```

### `${CLAUDE_PLUGIN_ROOT}` Environment Variable

The runtime injects `${CLAUDE_PLUGIN_ROOT}` with the plugin's actual install path. This is critical for portability.

**Rules:**
- ALWAYS use `${CLAUDE_PLUGIN_ROOT}` in hook commands and allowed-tools
- NEVER use absolute paths (`/Users/...`) or relative paths (`./hooks/...`)
- Works in: `hooks.json` commands, command frontmatter `allowed-tools`

**Examples:**
```json
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/pre_tool.py"
"command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/validate.py"
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

### Installation Flow (Marketplace)

```
marketplace.json registration
→ claude plugin install github:owner/repo/plugin-name
→ ~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/ (files copied)
→ installed_plugins.json (plugin registered)
→ settings.json enabledPlugins (plugin activated)
→ Runtime auto-loads hooks/hooks.json with ${CLAUDE_PLUGIN_ROOT} resolved
```

### From Installed Location
Place in `~/.claude/plugins/` for automatic loading.

## Hook Registration Patterns

| Pattern | Example | How hooks are registered |
|---------|---------|------------------------|
| Plugin (marketplace) | hookify, superpowers | `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` → runtime auto-loads |
| Standalone installer | peon-ping | Installer script writes absolute paths into `settings.json` |
| Manual | obsidian-plan-sync | User manually adds entries to `settings.json` |

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
1. Verify file is named `hooks.json` (not any other name)
2. Validate JSON syntax
3. Check matcher matches tool name
4. Verify command exists and is executable
5. Check command timeout
6. Ensure `${CLAUDE_PLUGIN_ROOT}` is used (not absolute paths)

## Marketplace Deployment

### marketplace.json Schema

The `marketplace.json` in the repo root registers plugins for installation.

```json
{
  "name": "marketplace-name",
  "owner": {
    "name": "github-username"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./plugin-dir",
      "description": "What this plugin does"
    }
  ]
}
```

### Preparation Checklist
- [ ] All components validated
- [ ] README.md with usage instructions
- [ ] LICENSE file included
- [ ] Version follows semver
- [ ] Keywords for discovery
- [ ] Tested with `--plugin-dir`
- [ ] marketplace.json registered
- [ ] hooks.json uses `${CLAUDE_PLUGIN_ROOT}` (not absolute paths)

### Package Structure
```
my-plugin-1.0.0/
├── .claude-plugin/
│   └── plugin.json
├── commands/
├── skills/
├── agents/
├── hooks/
│   └── hooks.json
├── CLAUDE.md
├── README.md
└── LICENSE
```

### Versioning
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes
