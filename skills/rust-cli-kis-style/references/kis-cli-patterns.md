# kis-cli patterns

Concrete Rust CLI pattern extracted from the current `kis-cli` repository.

## Workspace shape

```text
rust/
  Cargo.toml
  kis-core/
  kis-api/
  kis-cli/
```

- `kis-core`: config, auth, HTTP client
- `kis-api`: domain APIs
- `kis-cli`: `clap` parser, runtime dispatch, render helpers, binary entrypoint

## File roles

- `rust/kis-cli/src/main.rs`
  - thin async entrypoint
  - parses CLI once
  - calls runtime
  - prints text-mode errors to stderr
  - prints JSON-mode errors to stdout as structured envelopes
  - returns `ExitCode`
- `rust/kis-cli/src/cli.rs`
  - owns all `clap` structs and enums
  - defines global flags `--config`, `--env`, `--output`, `--json`, `--quiet`
  - uses `global = true` on shared flags
- `rust/kis-cli/src/runtime.rs`
  - loads config
  - initializes client once
  - dispatches subcommands
  - resolves text vs JSON output once
  - wraps machine-readable success and failure output in stable envelopes
- `rust/kis-cli/src/render.rs`
  - keeps plain-text rendering separate from runtime logic
  - uses `unicode-width` to align Korean labels and table cells
- `rust/kis-cli/tests/cli_smoke.rs`
  - tests the real built binary with `env!("CARGO_BIN_EXE_kis")`

## Command contract patterns

- Public binary name is `kis`.
- Global flags are valid before and after subcommands.
- `--output text|json` is the primary output switch and `--json` maps to JSON mode.
- Text output is human-readable tables or key/value rows.
- JSON output uses `{ok, command, data|error}` envelopes for both success and failure.
- `--quiet` suppresses extra text in text mode only.
- Side-effecting order commands expose `--dry-run` instead of forcing a live API call.
- Explicit config paths fail early; default config path is `~/.config/kis/config.yaml`.

## Build and test commands

```bash
cargo build --manifest-path rust/Cargo.toml -p kis-cli --bin kis
cargo build --manifest-path rust/Cargo.toml -p kis-cli --bin kis --release
cargo run --manifest-path rust/Cargo.toml -p kis-cli --bin kis -- config
cargo test --manifest-path rust/Cargo.toml
cargo test --manifest-path rust/Cargo.toml -p kis-cli
```

## Test cases worth copying

- parser accepts global flags after subcommands
- smoke test runs the real binary through `config`
- smoke test verifies JSON success and JSON error envelopes
- smoke test verifies default XDG config path
- smoke test verifies behavior when `HOME` is missing
- smoke test verifies `--quiet` text output
- smoke test verifies order `--dry-run` without network access
- render tests validate width alignment for Korean text
