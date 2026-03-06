# Rust Domain Relevance Check

All Rust skills and agents in this plugin **must** verify domain relevance before
proceeding. This document defines the signals to check and the confidence thresholds.

## Purpose

Before activating any Rust-specific skill, verify that the current user context is
actually related to Rust development. This avoids false activation on unrelated ecosystems.

## When Rust Skills Are Relevant

Check for these positive signals. Any single signal from the **High confidence**
category is sufficient to activate Rust skills.

### 1. Project File Presence
- `Cargo.toml` (crate manifest — strongest signal)
- `Cargo.lock` (dependency lock file)
- `rust-toolchain.toml` or `rust-toolchain` (toolchain pinning)
- `*.rs` files (Rust source code)
- `.cargo/config.toml` (Cargo configuration)
- `build.rs` (Cargo build script, only if accompanied by Cargo.toml)

### 2. CLI Command Context
- `cargo build`, `cargo test`, `cargo check`, `cargo run`, `cargo clippy`
- `cargo fmt`, `cargo doc`, `cargo bench`, `cargo publish`
- `rustup`, `rustc`

### 3. Error Code Prefixes
- `E0xxx` (Rust compiler errors, e.g., E0382, E0308)
- Error messages containing `rustc`, `cargo`, `borrow checker`, `lifetime`

### 4. Build Artifacts
- `target/` directory (Cargo build output)
- `target/debug/`, `target/release/`
- `*.rlib`, `*.rmeta` files

### 5. Cargo Manifest Content
- `[package]`, `[dependencies]`, `[dev-dependencies]`, `[build-dependencies]`
- `[workspace]`, `[features]`, `[profile.*]`
- `edition = "2021"` or similar

## When Rust Skills Are NOT Relevant
- .NET/MSBuild (`.csproj`, `dotnet build`, CS/MSB/NU errors)
- Node.js/JavaScript (`package.json`, `npm`, `yarn`)
- Python (`requirements.txt`, `setup.py`, `pip`)
- Java/Kotlin (`pom.xml`, `build.gradle`)
- C/C++ (`CMakeLists.txt`, `Makefile` without Cargo.toml)
- Go (`go.mod`, `go.sum`)

## Confidence Assessment

### High Confidence — Activate Immediately
- `Cargo.toml` present
- `E0xxx` error codes in output
- `cargo build`/`cargo test`/`cargo check` commands
- `*.rs` files with `fn main()` or `pub fn`
- `rustc` error output

### Medium Confidence — Investigate Further
- `target/` directory without Cargo.toml in view
- "Build failed" + some Rust indicators (`.rs` files mentioned)
- `build.rs` alone (could be unrelated)

### Low Confidence — Do Not Activate
- No Rust indicators present
- Different build system artifacts are the primary context
