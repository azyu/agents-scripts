---
name: shell-script
description: Use when creating, editing, or reviewing shell scripts (.sh files). Triggers on bash/sh/zsh script creation, .sh file editing, shellcheck, shell scripting best practices. Keywords - "shell script", "bash script", ".sh file", "shellcheck", "쉘 스크립트".
---

# shell-script

Required rules and patterns for writing/editing bash scripts.

## Required Header

Every bash script MUST start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `#!/usr/bin/env bash`: portable shebang — no hardcoded bash path
- `set -e`: exit immediately on error
- `set -u`: error on undefined variable reference
- `set -o pipefail`: propagate failures through pipelines

## shellcheck Required

MUST run `shellcheck <file>` after writing/editing. Key rules:

| Code | Issue | Fix |
|------|-------|-----|
| SC2086 | Unquoted variable | Use `"$var"` |
| SC2034 | Unused variable | Remove or `export` |
| SC2155 | `local` + assignment combined | Split: `local var; var=$(cmd)` |
| SC2046 | Unquoted command substitution | Use `"$(cmd)"` |
| SC2064 | Double-quoted trap string | Use `trap '...' EXIT` |
| SC2162 | Missing `-r` on `read` | Use `read -r` |

## Variables and Quoting

```bash
# Always double-quote
echo "$variable"
cp "$src" "$dest"

# Expand full array
for item in "${array[@]}"; do

# Default value pattern (set -u safe)
val="${VAR:-default}"
```

## Function Pattern

```bash
my_func() {
  local arg1="$1"
  local result
  result=$(some_command "$arg1")
  printf '%s' "$result"
}
```

- Separate `local` declaration from assignment (SC2155)
- Use `printf` for output (not `echo`)
- Return values via stdout; use exit codes for success/failure

## Error Handling

```bash
# Allow failure under set -e
cmd_that_may_fail || true

# Fallback value
result=$(cmd 2>/dev/null || echo "fallback")

# Cleanup trap
cleanup() { rm -f "$tmpfile"; }
trap cleanup EXIT
```

## General Rules

- Temp files: use `mktemp` (never hardcode `/tmp/foo`)
- Arithmetic: use `$(( ))` (never `expr`)
- Conditionals: use `[[ ]]` (not `[ ]`)
- Process substitution: `< <(cmd)`
- Here-string: `<<< "$var"`
- Long pipelines: break with `\` or split into variables
