---
name: rust-cli-kis-style
description: Apply the kis-cli repository's Rust CLI conventions on top of $rust-cli. Use when working in the kis-cli repo or when the user wants the same workspace split, global flags, XDG config handling, JSON/text output split, and parser plus binary smoke test style.
---

# Rust CLI KIS Style

Apply this skill after `$rust-cli`.

Use it when:
- working in this `kis-cli` repository
- matching this repo's Rust CLI layout in another project
- extending a clap-based CLI with the same config/runtime/render/test conventions

## What this adds on top of `$rust-cli`

- Workspace split is fixed to:

```text
rust/
  kis-core/
  kis-api/
  kis-cli/
```

- `kis-core` owns config, auth, and shared HTTP client setup.
- `kis-api` owns domestic/overseas domain logic.
- `kis-cli` owns parser, runtime dispatch, formatting, and the binary entrypoint.

## Required conventions

- Public binary name is `kis`.
- Global flags are `--config`, `--env`, `--output`, `--json`, and `--quiet`.
- These flags must be `global = true` so they parse before or after subcommands.
- `--output text|json` is the primary output selector. `--json` remains as a compatibility alias for `--output json`.
- Default config path is `~/.config/kis/config.yaml`.
- Explicit config paths fail fast.
- Runtime initializes config and client once, then dispatches.
- Text rendering stays in `render.rs`; runtime does not format tables inline.
- Wide-character alignment must use `unicode-width`.
- JSON mode emits both success and failure as `{ok, command, data|error}` envelopes on stdout.
- Text mode keeps human-readable output on stdout and failures on stderr.
- Side-effecting order commands should expose `--dry-run` that resolves route, endpoint, TR ID, and request payload without calling the API.

## Test expectations

- Parser tests live with the clap types.
- Runtime tests cover routing and JSON serialization.
- `tests/cli_smoke.rs` exercises the real binary via `env!("CARGO_BIN_EXE_kis")`.
- Keep smoke coverage for:
  - `config` command success
  - global flags after subcommands
  - JSON success/error envelope behavior
  - default XDG path
  - missing `HOME`
  - text-mode `--quiet`
  - order `--dry-run` without network access
  - Korean width alignment in render helpers

## Reference

For the concrete file map and commands, read [references/kis-cli-patterns.md](references/kis-cli-patterns.md).
