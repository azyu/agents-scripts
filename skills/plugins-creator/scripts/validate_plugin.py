#!/usr/bin/env python3
"""
Validate a Claude Code plugin structure and configuration.

Usage:
    python validate_plugin.py <plugin-path>

Checks:
    - plugin.json manifest exists and is valid
    - Directory structure is correct
    - Skill files have valid frontmatter
    - Agent files have valid frontmatter
    - Hook files are valid JSON
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional


class ValidationError:
    def __init__(self, level: str, message: str, path: Optional[Path] = None):
        self.level = level  # "error" or "warning"
        self.message = message
        self.path = path

    def __str__(self):
        prefix = "ERROR" if self.level == "error" else "WARNING"
        location = f" ({self.path})" if self.path else ""
        return f"[{prefix}]{location} {self.message}"


def validate_manifest(plugin_path: Path) -> list[ValidationError]:
    """Validate the plugin.json manifest."""
    errors = []
    manifest_path = plugin_path / ".claude-plugin" / "plugin.json"

    if not manifest_path.exists():
        errors.append(ValidationError("error", "Missing plugin.json manifest", manifest_path))
        return errors

    try:
        with open(manifest_path) as f:
            manifest = json.load(f)
    except json.JSONDecodeError as e:
        errors.append(ValidationError("error", f"Invalid JSON: {e}", manifest_path))
        return errors

    # Required fields
    required_fields = ["name", "description", "version"]
    for field in required_fields:
        if field not in manifest:
            errors.append(ValidationError("error", f"Missing required field: {field}", manifest_path))

    # Validate name format
    if "name" in manifest:
        name = manifest["name"]
        if not re.match(r'^[a-z0-9][a-z0-9\-_]*$', name):
            errors.append(ValidationError("error",
                f"Invalid plugin name '{name}'. Use lowercase alphanumeric, hyphens, or underscores.",
                manifest_path))

    # Validate version format (semver)
    if "version" in manifest:
        version = manifest["version"]
        if not re.match(r'^\d+\.\d+\.\d+', version):
            errors.append(ValidationError("warning",
                f"Version '{version}' doesn't follow semver format (x.y.z)",
                manifest_path))

    # Check description length
    if "description" in manifest:
        desc = manifest["description"]
        if len(desc) < 10:
            errors.append(ValidationError("warning",
                "Description is very short. Consider adding more detail.",
                manifest_path))
        if len(desc) > 1024:
            errors.append(ValidationError("warning",
                f"Description exceeds 1024 characters ({len(desc)})",
                manifest_path))

    return errors


def parse_yaml_frontmatter(content: str) -> Optional[dict]:
    """Extract YAML frontmatter from markdown content."""
    if not content.startswith('---'):
        return None

    parts = content.split('---', 2)
    if len(parts) < 3:
        return None

    frontmatter = parts[1].strip()
    result = {}

    for line in frontmatter.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()

            # Handle arrays
            if value.startswith('[') and value.endswith(']'):
                value = [v.strip().strip('"\'') for v in value[1:-1].split(',')]
            # Handle quoted strings
            elif value.startswith('"') or value.startswith("'"):
                value = value[1:-1]

            result[key] = value

    return result if result else None


def validate_skill(skill_path: Path) -> list[ValidationError]:
    """Validate a skill directory."""
    errors = []
    skill_md = skill_path / "SKILL.md"

    if not skill_md.exists():
        errors.append(ValidationError("error", "Missing SKILL.md", skill_path))
        return errors

    content = skill_md.read_text()

    # Check frontmatter
    frontmatter = parse_yaml_frontmatter(content)
    if frontmatter is None:
        errors.append(ValidationError("error", "Missing or invalid YAML frontmatter", skill_md))
        return errors

    # Required frontmatter fields
    if "name" not in frontmatter:
        errors.append(ValidationError("error", "Missing 'name' in frontmatter", skill_md))

    if "description" not in frontmatter:
        errors.append(ValidationError("error", "Missing 'description' in frontmatter", skill_md))
    elif len(frontmatter["description"]) > 1024:
        errors.append(ValidationError("warning",
            f"Description exceeds 1024 characters ({len(frontmatter['description'])})",
            skill_md))

    # Check content length
    lines = content.split('\n')
    if len(lines) > 500:
        errors.append(ValidationError("warning",
            f"SKILL.md has {len(lines)} lines. Consider splitting into references/.",
            skill_md))

    return errors


def validate_agent(agent_path: Path) -> list[ValidationError]:
    """Validate an agent file."""
    errors = []

    content = agent_path.read_text()

    # Check frontmatter
    frontmatter = parse_yaml_frontmatter(content)
    if frontmatter is None:
        errors.append(ValidationError("error", "Missing or invalid YAML frontmatter", agent_path))
        return errors

    # Required frontmatter fields
    if "name" not in frontmatter:
        errors.append(ValidationError("error", "Missing 'name' in frontmatter", agent_path))

    if "description" not in frontmatter:
        errors.append(ValidationError("error", "Missing 'description' in frontmatter", agent_path))

    # Optional but recommended
    if "tools" not in frontmatter:
        errors.append(ValidationError("warning", "Missing 'tools' specification", agent_path))

    if "model" not in frontmatter:
        errors.append(ValidationError("warning",
            "Missing 'model' specification. Will use default.", agent_path))
    elif frontmatter["model"] not in ["sonnet", "opus", "haiku"]:
        errors.append(ValidationError("warning",
            f"Unknown model '{frontmatter['model']}'. Use: sonnet, opus, haiku", agent_path))

    return errors


def validate_hooks(hooks_path: Path) -> list[ValidationError]:
    """Validate a hooks JSON file."""
    errors = []

    try:
        with open(hooks_path) as f:
            hooks = json.load(f)
    except json.JSONDecodeError as e:
        errors.append(ValidationError("error", f"Invalid JSON: {e}", hooks_path))
        return errors

    if "hooks" not in hooks:
        errors.append(ValidationError("warning", "Missing 'hooks' key", hooks_path))
        return errors

    valid_hook_types = ["PreToolUse", "PostToolUse", "Stop"]
    for hook_type in hooks["hooks"]:
        if hook_type not in valid_hook_types:
            errors.append(ValidationError("warning",
                f"Unknown hook type '{hook_type}'. Valid: {valid_hook_types}",
                hooks_path))

    return errors


def validate_plugin(plugin_path: Path) -> list[ValidationError]:
    """Validate the entire plugin structure."""
    errors = []

    if not plugin_path.exists():
        errors.append(ValidationError("error", f"Plugin directory does not exist: {plugin_path}"))
        return errors

    if not plugin_path.is_dir():
        errors.append(ValidationError("error", f"Not a directory: {plugin_path}"))
        return errors

    # Check .claude-plugin directory
    claude_plugin_dir = plugin_path / ".claude-plugin"
    if not claude_plugin_dir.exists():
        errors.append(ValidationError("error", "Missing .claude-plugin directory"))
        return errors

    # Validate manifest
    errors.extend(validate_manifest(plugin_path))

    # Validate skills
    skills_dir = plugin_path / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir():
                errors.extend(validate_skill(skill_dir))

    # Validate agents
    agents_dir = plugin_path / "agents"
    if agents_dir.exists():
        for agent_file in agents_dir.glob("*.md"):
            errors.extend(validate_agent(agent_file))

    # Validate hooks
    hooks_dir = plugin_path / "hooks"
    if hooks_dir.exists():
        for hooks_file in hooks_dir.glob("*.json"):
            errors.extend(validate_hooks(hooks_file))

    return errors


def main():
    parser = argparse.ArgumentParser(
        description="Validate a Claude Code plugin",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("path", type=Path, help="Path to plugin directory")
    parser.add_argument("--strict", action="store_true",
                        help="Treat warnings as errors")

    args = parser.parse_args()

    errors = validate_plugin(args.path)

    # Separate errors and warnings
    actual_errors = [e for e in errors if e.level == "error"]
    warnings = [e for e in errors if e.level == "warning"]

    # Print results
    for error in errors:
        print(error)

    if not errors:
        print(f"Plugin validation passed: {args.path}")
        sys.exit(0)

    print()
    print(f"Validation complete: {len(actual_errors)} error(s), {len(warnings)} warning(s)")

    if actual_errors or (args.strict and warnings):
        sys.exit(1)
    else:
        print("Plugin is valid (with warnings)")
        sys.exit(0)


if __name__ == "__main__":
    main()
