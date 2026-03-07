---
name: rust-cli
description: Build or refactor a Rust command line application using Cargo and clap. Use when creating a CLI binary, adding subcommands or global flags, splitting a workspace into core/api/cli crates, defining config precedence, or adding parser and smoke tests.
---

# Rust CLI

Use this skill when the task is specifically about building or reshaping a Rust CLI, not just generic terminal UX.

Typical triggers:
- create a new Rust CLI
- add or refactor `clap` subcommands, args, or global flags
- split a binary into workspace crates
- add config/env/file precedence
- add machine-readable output or text rendering
- add parser tests or real binary smoke tests

## Default shape

- Prefer Cargo as the build surface. Do not introduce `make` by default.
- For a small tool, a single crate is fine. For a CLI with real domain logic, prefer a workspace:

```text
rust/
  Cargo.toml
  app-core/
  app-api/
  app-cli/
```

- Keep the public binary name stable and match the user-facing command.
- Keep `main.rs` thin: parse CLI, call runtime, map failures to exit codes, and write the selected error contract.
- Put `clap` types in `src/cli.rs`.
- Put orchestration and dispatch in `src/runtime.rs`.
- Put plain-text formatting helpers in `src/render.rs`.
- Put reusable domain logic in library crates, not in `main.rs`.

## Implementation workflow

1. Define the command surface in `cli.rs` with `#[derive(Parser)]`, `#[derive(Subcommand)]`, and `#[derive(Args)]`.
2. Make truly global flags `global = true` so both `tool --config path cmd` and `tool cmd --config path` work.
3. Initialize config and clients once in `runtime.rs`, then dispatch by subcommand.
4. Resolve output mode once at the command boundary, then branch between text and machine-readable output.
5. Keep rendering width-aware if labels or cells can contain Korean or other wide characters.
6. Verify parser contracts and the real binary path with tests.

## Non-negotiables

- CLI precedence is `CLI args > env vars > config file > defaults`.
- Successful data goes to stdout. In text mode, failures go to stderr. If the CLI offers machine-readable output, emit failure payloads on stdout in that mode and rely on exit status.
- Use `ExitCode` or `Result` for failures. Do not panic for user-facing errors.
- Default config path should follow XDG on Unix-like systems: `~/.config/<app>/config.yaml`.
- If the user passes an explicit config path, fail fast when it is missing.
- Derive machine-readable output from structured data; do not build JSON by re-parsing formatted text.
- If the CLI serves both humans and automation, prefer an explicit output mode such as `--output text|json`; keep `--json` only as a compatibility shorthand when useful.
- For automation-facing commands, define a stable machine-readable contract for both success and failure, and test it.
- Redact secrets in config, debug, and dry-run output.
- Keep `main.rs` and `cli.rs` free of HTTP or business logic.

## Optional patterns

- Add `--quiet` when text mode would otherwise include headings or explanatory prose that automation does not want. Ignore it in machine-readable modes.
- For side-effecting commands, add `--dry-run` or validation-only execution that shows the resolved route, target, or request shape without performing the action.
- If machine-readable consumers need stable routing metadata, expose a command identifier in the output contract instead of deriving it from help text.
- A `config` or `doctor` command that prints the resolved config path and effective non-secret settings is often worth adding.

## Tests to add

- Parser unit tests in `src/cli.rs` for subcommand shapes and flag conflicts.
- Runtime unit tests in `src/runtime.rs` for routing, validation, and JSON serialization.
- Smoke tests in `tests/cli_smoke.rs` using `env!("CARGO_BIN_EXE_<bin>")`.
- Include at least these scenarios:
  - global flags before and after subcommands
  - resolved output mode and any compatibility alias such as `--json`
  - default config path resolution
  - explicit config path failure
  - missing `HOME` or `dirs::home_dir()` fallback if relevant
  - machine-readable error contract if the CLI supports it
  - text rendering with wide characters
  - binary invocation success path
  - dry-run or validation-only execution for side-effecting commands, if supported

## Build and run defaults

```bash
cargo build --manifest-path rust/Cargo.toml -p app-cli --bin app
cargo build --manifest-path rust/Cargo.toml -p app-cli --bin app --release
cargo run --manifest-path rust/Cargo.toml -p app-cli --bin app -- <args>
cargo test --manifest-path rust/Cargo.toml
cargo test --manifest-path rust/Cargo.toml -p app-cli
```

## Specializing this skill

For a repo-specific layer such as `rust-cli-kis-style`, keep that skill thin:
- first apply `$rust-cli`
- then add repo-specific rules such as workspace names, global flags, config schema, rendering conventions, and supported commands
- keep concrete examples in a reference file instead of duplicating this base skill
