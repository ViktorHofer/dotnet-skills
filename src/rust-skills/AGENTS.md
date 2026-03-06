# Rust Project Instructions

<!-- Copy this file to your repository root as AGENTS.md for cross-agent support -->

## Build System

This repository uses Cargo for building Rust projects. Key commands:
- Build: `cargo build`
- Test: `cargo test`
- Check (fast type-check): `cargo check`
- Lint: `cargo clippy --all-targets -- -D warnings`
- Format check: `cargo fmt --check`
- Run: `cargo run`

## Build Failure Handling

When a build fails:
1. Run `cargo build 2>&1` and capture the full compiler output
2. Look for error codes (E0xxx) — each has a specific cause and fix pattern
3. For borrow checker errors (E0382, E0499, E0502, E0505, E0507, E0597), trace the ownership/lifetime chain
4. After fixing, rebuild to verify the fix compiles
5. Run `cargo clippy` after fixing to catch remaining quality issues

## Cargo Project File Conventions

- Use workspace (`[workspace]` in root `Cargo.toml`) for multi-crate projects
- Keep dependencies minimal; prefer `std` types where possible
- Use `rust-toolchain.toml` to pin the Rust toolchain version
- Feature flags must be additive — never break compilation by enabling a feature
- Use `thiserror` for library error types, `anyhow` or `eyre` for application errors

## Error Handling

- Use `Result<T, E>` for recoverable errors, `panic!` only for programming bugs
- Define custom error types with `#[derive(Debug, thiserror::Error)]`
- Include backtrace support in error structs
- Never use `.unwrap()` in library code; prefer `?` operator

## Testing

- Unit tests go in `#[cfg(test)] mod tests { ... }` inside the source file
- Integration tests go in the `tests/` directory
- Use `#[test]` for sync tests, `#[tokio::test]` for async
- Doc tests in `///` comments are run by `cargo test`
