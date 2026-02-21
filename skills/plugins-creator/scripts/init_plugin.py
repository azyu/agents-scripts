#!/usr/bin/env python3
"""
Initialize a new Claude Code plugin with proper directory structure.

Usage:
    python init_plugin.py <plugin-name> [options]

Options:
    --skills    Include skills directory
    --agents    Include agents directory
    --hooks     Include hooks directory
    --mcp       Include MCP server configuration
    --all       Include all component types
    --output    Output directory (default: current directory)
"""

import argparse
import json
import os
import sys
from pathlib import Path


def create_plugin_manifest(plugin_name: str, description: str = "") -> dict:
    """Create the plugin.json manifest structure."""
    return {
        "name": plugin_name,
        "description": description or f"{plugin_name} plugin for Claude Code",
        "version": "1.0.0",
        "author": {
            "name": os.environ.get("USER", "Author Name")
        }
    }


def create_skill_template(skill_name: str) -> str:
    """Create a basic SKILL.md template."""
    return f"""---
name: {skill_name}
description: Description of what this skill does. When to use it.
---

# {skill_name.replace('-', ' ').title()}

## Overview

Describe the skill's purpose and capabilities.

## Usage

Instructions for using this skill.

## Examples

Provide concrete examples.
"""


def create_agent_template(agent_name: str) -> str:
    """Create a basic agent template."""
    return f"""---
name: {agent_name}
description: Description of what this agent does
tools:
  - Read
  - Grep
  - Glob
model: sonnet
---

# {agent_name.replace('-', ' ').title()} Agent

## Role

Define the agent's role and expertise.

## Workflow

1. Step one
2. Step two
3. Step three

## Guidelines

- Guideline one
- Guideline two
"""


def create_hook_template() -> dict:
    """Create a basic hooks configuration template."""
    return {
        "hooks": {
            "PreToolUse": [],
            "PostToolUse": [],
            "Stop": []
        }
    }


def create_mcp_template() -> dict:
    """Create a basic MCP servers configuration template."""
    return {
        "mcpServers": {}
    }


def init_plugin(
    plugin_name: str,
    output_dir: Path,
    include_skills: bool = False,
    include_agents: bool = False,
    include_hooks: bool = False,
    include_mcp: bool = False
) -> Path:
    """Initialize a new plugin with the specified components."""

    # Validate plugin name
    if not plugin_name.replace('-', '').replace('_', '').isalnum():
        raise ValueError(f"Invalid plugin name: {plugin_name}. Use alphanumeric characters, hyphens, or underscores.")

    plugin_path = output_dir / plugin_name

    if plugin_path.exists():
        raise FileExistsError(f"Directory already exists: {plugin_path}")

    # Create base structure
    plugin_path.mkdir(parents=True)
    (plugin_path / ".claude-plugin").mkdir()

    # Create manifest
    manifest = create_plugin_manifest(plugin_name)
    manifest_path = plugin_path / ".claude-plugin" / "plugin.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)

    # Create optional components
    if include_skills:
        skills_dir = plugin_path / "skills" / f"{plugin_name}-skill"
        skills_dir.mkdir(parents=True)
        skill_content = create_skill_template(f"{plugin_name}-skill")
        with open(skills_dir / "SKILL.md", 'w') as f:
            f.write(skill_content)

    if include_agents:
        agents_dir = plugin_path / "agents"
        agents_dir.mkdir()
        agent_content = create_agent_template(f"{plugin_name}-agent")
        with open(agents_dir / f"{plugin_name}-agent.md", 'w') as f:
            f.write(agent_content)

    if include_hooks:
        hooks_dir = plugin_path / "hooks"
        hooks_dir.mkdir()
        hooks_content = create_hook_template()
        with open(hooks_dir / "hooks.json", 'w') as f:
            json.dump(hooks_content, f, indent=2)

    if include_mcp:
        mcp_dir = plugin_path / "mcp"
        mcp_dir.mkdir()
        mcp_content = create_mcp_template()
        with open(mcp_dir / "servers.json", 'w') as f:
            json.dump(mcp_content, f, indent=2)

    # Create CLAUDE.md
    claude_md = f"""# {plugin_name}

Plugin-level instructions and context for Claude.

## About This Plugin

Describe what this plugin provides and how to use it.

## Configuration

Any configuration notes.
"""
    with open(plugin_path / "CLAUDE.md", 'w') as f:
        f.write(claude_md)

    return plugin_path


def main():
    parser = argparse.ArgumentParser(
        description="Initialize a new Claude Code plugin",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python init_plugin.py my-plugin
    python init_plugin.py my-plugin --skills --agents
    python init_plugin.py my-plugin --all
    python init_plugin.py my-plugin --output ~/projects
        """
    )

    parser.add_argument("name", help="Plugin name (use hyphens for multi-word names)")
    parser.add_argument("--skills", action="store_true", help="Include skills directory")
    parser.add_argument("--agents", action="store_true", help="Include agents directory")
    parser.add_argument("--hooks", action="store_true", help="Include hooks directory")
    parser.add_argument("--mcp", action="store_true", help="Include MCP server configuration")
    parser.add_argument("--all", action="store_true", help="Include all component types")
    parser.add_argument("--output", "-o", type=Path, default=Path.cwd(),
                        help="Output directory (default: current directory)")

    args = parser.parse_args()

    include_all = args.all

    try:
        plugin_path = init_plugin(
            plugin_name=args.name,
            output_dir=args.output,
            include_skills=include_all or args.skills,
            include_agents=include_all or args.agents,
            include_hooks=include_all or args.hooks,
            include_mcp=include_all or args.mcp
        )

        print(f"Plugin initialized: {plugin_path}")
        print("\nCreated structure:")

        for root, dirs, files in os.walk(plugin_path):
            level = root.replace(str(plugin_path), '').count(os.sep)
            indent = '  ' * level
            print(f"{indent}{os.path.basename(root)}/")
            subindent = '  ' * (level + 1)
            for file in files:
                print(f"{subindent}{file}")

        print("\nNext steps:")
        print(f"  1. Edit {plugin_path}/.claude-plugin/plugin.json")
        print(f"  2. Add your components to the appropriate directories")
        print(f"  3. Validate: python validate_plugin.py {plugin_path}")
        print(f"  4. Test: claude --plugin-dir {plugin_path}")

    except (ValueError, FileExistsError) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
