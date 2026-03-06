# Rust Skills Plugin — Implementation Plan

> **Purpose:** Self-contained, step-by-step plan for implementing the `rust-skills` plugin.
> Ready for execution in a separate context without additional research.
> **Date:** 2026-02-19
> **Based on:** [rust-skills-research.md](rust-skills-research.md)

---

## Table of Contents

1. [Scope & Deliverables](#1-scope--deliverables)
2. [Plugin Scaffold](#2-plugin-scaffold)
3. [Skill Specifications](#3-skill-specifications)
4. [Agent Specification](#4-agent-specification)
5. [Test Case Specifications](#5-test-case-specifications)
6. [Build Script](#6-build-script)
7. [Evaluation Pipeline Changes](#7-evaluation-pipeline-changes)
8. [Implementation Order & Checklist](#8-implementation-order--checklist)
9. [V2 Roadmap Summary](#9-v2-roadmap-summary)

---

## 1. Scope & Deliverables

### Phase 1 (this plan)

| Component | Count | Items |
|-----------|-------|-------|
| **Skills** | 4 | `common-rust-errors`, `borrow-checker-errors`, `rust-error-handling`, `rust-domain-check` (shared) |
| **Agents** | 1 | `rust.agent.md` |
| **Test cases** | 4 | `borrow-errors`, `type-errors`, `import-resolution`, `poor-error-handling` |
| **Infrastructure** | 4 files | `plugin.json`, `README.md`, `AGENTS.md`, `build.js` |

### What is NOT in Phase 1

- Copilot extension, agentic workflows, prompt templates
- Code review agent (`rust-code-review.agent.md`)
- Test generation agent and skill (`rust-test-gen.agent.md`, `rust-unit-testing`)
- Style/antipatterns/API design/clippy/performance/unsafe/logging skills
- Docker image changes for CI (documented but not implemented)

### Versioning

Initial version: **`1.0.0`** in `plugin.json`. Per repository `AGENTS.md`:
- Adding skills/agents = minor bump
- Content fixes = patch bump
- Breaking changes = major bump

---

## 2. Plugin Scaffold

### Directory Layout

```
src/rust-skills/
├── plugin.json
├── README.md
├── AGENTS.md
├── build.js
├── agents/
│   └── rust.agent.md
├── skills/
│   ├── shared/
│   │   └── domain-check.md
│   ├── common-rust-errors/
│   │   └── SKILL.md
│   ├── borrow-checker-errors/
│   │   └── SKILL.md
│   └── rust-error-handling/
│       └── SKILL.md
└── testcases/
    ├── README.md
    ├── borrow-errors/
    │   ├── Cargo.toml
    │   ├── rust-toolchain.toml
    │   ├── src/
    │   │   └── main.rs
    │   ├── expected-output.md
    │   └── README.md
    ├── type-errors/
    │   ├── ...
    │   └── expected-output.md
    ├── import-resolution/
    │   ├── ...
    │   └── expected-output.md
    └── poor-error-handling/
        ├── ...
        └── expected-output.md
```

### `plugin.json`

```json
{
  "name": "rust-skills",
  "version": "1.0.0",
  "description": "Rust development skills: compiler error diagnosis, borrow checker resolution, error handling patterns, and code quality guidance.",
  "skills": "./skills/",
  "agents": "./agents/"
}
```

### `AGENTS.md`

This file provides cross-agent instructions (for Copilot, Claude Code, etc.) when copied to a Rust repository root. Content:

```markdown
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
```

### `README.md`

```markdown
# Rust Skills

Rust development skills: compiler error diagnosis, borrow checker resolution,
error handling patterns, and code quality guidance.

## Skills

### Build & Compilation Errors

| Skill | Description |
|-------|-------------|
| [`common-rust-errors`](skills/common-rust-errors/) | Top Rust compiler errors (E0xxx) with root causes and step-by-step fixes |
| [`borrow-checker-errors`](skills/borrow-checker-errors/) | Deep-dive into ownership, borrowing, and lifetime errors |

### Error Handling

| Skill | Description |
|-------|-------------|
| [`rust-error-handling`](skills/rust-error-handling/) | Error design patterns: canonical structs, thiserror, anyhow, Result vs panic |

### Shared

| Skill | Description |
|-------|-------------|
| [`domain-check`](skills/shared/domain-check.md) | Determines if the workspace is a Rust project |

## Agents

| Agent | Description |
|-------|-------------|
| [`rust`](agents/rust.agent.md) | General Rust expert — triages problems and routes to specialized skills |

## Test Cases

| Test Case | Skills Tested | Description |
|-----------|--------------|-------------|
| [`borrow-errors`](testcases/borrow-errors/) | borrow-checker-errors, common-rust-errors | Ownership and borrowing violations |
| [`type-errors`](testcases/type-errors/) | common-rust-errors | Type mismatches and trait bound failures |
| [`import-resolution`](testcases/import-resolution/) | common-rust-errors | Unresolved imports and missing dependencies |
| [`poor-error-handling`](testcases/poor-error-handling/) | rust-error-handling | Anti-pattern error handling that builds but is fragile |
```

---

## 3. Skill Specifications

Each skill is a `SKILL.md` with YAML frontmatter and markdown body. The domain gate phrase for all Rust skills is:

```
Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals).
```

### 3.1 `skills/shared/domain-check.md`

**Purpose:** Cross-cutting domain relevance check. All skills and the agent reference this.

```markdown
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
```

### 3.2 `skills/common-rust-errors/SKILL.md`

**Frontmatter:**

```yaml
---
name: common-rust-errors
description: "Knowledge base of common Rust compiler errors (E0xxx) with root causes and solutions. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when encountering E0xxx error codes during cargo build, cargo check, or cargo test. Covers type errors (E0308), import/resolution errors (E0425, E0432, E0433), pattern errors (E0004), mutability errors (E0384, E0596), trait errors (E0277, E0599), and feature gate errors (E0658). For ownership/borrowing/lifetime errors (E0382, E0499, E0502, E0505, E0507, E0106, E0597, E0515, E0621, E0373), defer to the borrow-checker-errors skill which provides deeper analysis. DO NOT use for non-Rust build errors (.NET, npm, Gradle, CMake, etc.)."
---
```

**Body — error entries to include (each with: What it means, Common root causes, Step-by-step fix, Prevention):**

| Error | Category | Description |
|-------|----------|-------------|
| **E0308** | Type system | Mismatched types — expected one type, found another |
| **E0277** | Traits | Trait bound not satisfied — type doesn't implement required trait |
| **E0599** | Methods | No method named X found for type Y |
| **E0425** | Resolution | Cannot find value/function in this scope |
| **E0432** | Imports | Unresolved import |
| **E0433** | Resolution | Failed to resolve: use of undeclared crate or module |
| **E0004** | Patterns | Non-exhaustive patterns in match |
| **E0384** | Mutability | Cannot assign twice to immutable variable |
| **E0596** | Mutability | Cannot borrow as mutable (variable not declared `mut`) |
| **E0658** | Features | Unstable feature — requires nightly or feature gate |

**Body structure for each error:**

```markdown
# Common Rust Compiler Errors

## Type Errors

### E0308: Mismatched types

**What it means:** The compiler expected one type but found a different one. This
is the most common Rust error — it fires whenever a value's type doesn't match
what the surrounding context requires.

**Common root causes:**
- Function argument type doesn't match the parameter type in the signature
- Return value type doesn't match the declared return type
- Variable assignment with incompatible type
- Integer type mismatch (e.g., `u32` vs `i32`, or `usize` vs `u64`)
- Missing `.as_str()`, `.to_string()`, or other conversion method
- `if` / `match` arms returning different types
- Forgetting `&` or `*` for reference/dereference

**Step-by-step fix:**
1. Read the full error message — Rust shows "expected `X`, found `Y`" with exact types.
2. Check if a simple conversion exists: `.into()`, `.as_ref()`, `.to_string()`,
   `as u32`, etc.
3. For `&str` vs `String`: use `.to_string()` to go from `&str` → `String`,
   or `&s` / `.as_str()` to go from `String` → `&str`.
4. For integer types: use `as` cast (e.g., `x as u64`) or `.try_into().unwrap()`
   for fallible conversion.
5. For `if`/`match` arms: ensure all arms return the same concrete type; use
   `Box<dyn Trait>` or an enum if they're genuinely different types.
6. For option/result mismatches: use `.unwrap()`, `?`, `.ok()`, `.map()` as appropriate.

**Prevention:**
- Let the compiler infer types where possible; add explicit annotations when
  inference fails.
- Use `clippy::cast_possible_truncation` to catch lossy integer casts.

---

### E0277: Trait bound not satisfied
...
```

Continue this pattern for all 10 errors listed above. Each entry should be 15–30 lines
including blank lines. Here is a second fully-written entry as a template:

```markdown
### E0277: Trait bound not satisfied

**What it means:** A type was used in a context that requires it to implement a
specific trait, but the type does not implement that trait.

**Common root causes:**
- Passing a type to a generic function with a trait bound it doesn't satisfy
  (e.g., passing a struct to a function requiring `Display` when the struct
  doesn't implement `Display`)
- Using a type in a collection or API that requires `Clone`, `Debug`, `Hash`,
  `Eq`, `Send`, `Sync`, `Serialize`, etc.
- Missing `#[derive(...)]` on a struct or enum
- Implementing a trait for the wrong type or with wrong generic parameters
- Trying to use `?` in a function whose error type doesn't implement `From<E>`

**Step-by-step fix:**
1. Read the error — it says "the trait `X` is not implemented for `Y`".
2. If it's a standard trait (`Debug`, `Clone`, `PartialEq`, etc.), add
   `#[derive(Debug, Clone, PartialEq)]` to your type definition.
3. If it's a third-party trait (`Serialize`, `Deserialize`), add the derive
   attribute and ensure the crate is in `[dependencies]` with the `derive` feature.
4. If it's a custom trait, implement it manually with `impl MyTrait for MyType`.
5. If the error is about `From<E>` for the `?` operator, add a `From` impl or
   use `.map_err(...)` to convert.

**Prevention:**
- Derive common traits proactively: `#[derive(Debug, Clone, PartialEq, Eq, Hash)]`.
- Check trait bounds in function signatures before calling them.
```

Also include at the end of the skill:

- A **"Cross-reference"** section: "For ownership, borrowing, and lifetime errors
  (E0382, E0499, E0502, E0505, E0507, E0106, E0597, E0515, E0621, E0373), see
  the `borrow-checker-errors` skill."
- A **"Getting More Help"** section mentioning `rustc --explain E0xxx` for any error code.

**Authoring guidance:** Each of the 10 error entries follows the same 4-section
format (What it means / Common root causes / Step-by-step fix / Prevention).
Use concrete Rust code snippets in the fix steps where they add clarity. Keep
language direct and practical — these are reference entries, not tutorials.

**Approximate length:** 400–500 lines.

### 3.3 `skills/borrow-checker-errors/SKILL.md`

**Frontmatter:**

```yaml
---
name: borrow-checker-errors
description: "Deep-dive guide to Rust ownership, borrowing, and lifetime errors. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when encountering borrow checker errors: E0382 (use of moved value), E0499 (multiple mutable borrows), E0502 (conflicting borrows), E0505 (move out of borrow), E0507 (move out of borrowed content), E0106 (missing lifetime), E0597 (value does not live long enough), E0515 (cannot return reference to local), E0621 (explicit lifetime required), E0373 (closure outlives function). Provides ownership mental model, resolution patterns, and refactoring strategies. DO NOT use for non-Rust errors."
---
```

**Body structure:**

```markdown
# Rust Borrow Checker Errors

The borrow checker is Rust's core safety mechanism. It enforces three rules:
1. Each value has exactly one owner at a time
2. You can have either ONE mutable reference OR any number of immutable references (not both)
3. References must not outlive the data they point to

When these rules are violated, the compiler produces errors in the E0382–E0621 range.
This skill covers every major borrow checker error with concrete fix patterns.

## Mental Model: Ownership Flow

Before diving into specific errors, understand how Rust tracks ownership:

- **Move:** Assigning a non-Copy value transfers ownership. The original binding
  becomes invalid.
- **Borrow (`&T`):** An immutable reference lets you read but not modify. Multiple
  immutable borrows can coexist.
- **Mutable borrow (`&mut T`):** A mutable reference lets you modify. Only one
  mutable borrow can exist at a time, and no immutable borrows can coexist with it.
- **Lifetime:** Every reference has a lifetime — the scope for which it is valid.
  The compiler infers lifetimes where possible (lifetime elision rules).

## Ownership Errors

### E0382: Use of moved value

**What it means:** A value was used after its ownership was transferred (moved)
to another variable or function.

**Common root causes:**
- Assigning a `String`, `Vec`, `Box`, or other non-Copy type to a new variable
  and then using the original
- Passing a non-Copy value to a function (transfers ownership) and then using
  the original
- Moving a value into a closure with `move` and then using the original
- Moving a value out of a loop iteration and then looping again

**Resolution patterns:**

1. **Clone if cheap:** If the type implements Clone and copying is acceptable:
   ```rust
   let s1 = String::from("hello");
   let s2 = s1.clone();  // s1 is still valid
   ```

2. **Borrow instead of move:** Pass a reference:
   ```rust
   fn process(s: &str) { /* ... */ }
   let s = String::from("hello");
   process(&s);  // s is still valid
   ```

3. **Restructure to avoid double use:** Move the use of the original before
   the move, or restructure so only one path uses the value.

4. **Use `Rc<T>` or `Arc<T>` for shared ownership:** When multiple owners
   genuinely need the same data:
   ```rust
   use std::rc::Rc;
   let s = Rc::new(String::from("hello"));
   let s2 = Rc::clone(&s);  // both s and s2 own the data
   ```

5. **Derive `Copy`** if the type is small and stack-only (all fields are Copy):
   ```rust
   #[derive(Copy, Clone)]
   struct Point { x: i32, y: i32 }
   ```

---

### E0499: Cannot borrow as mutable more than once at a time
...

### E0502: Cannot borrow as immutable because it is also borrowed as mutable
...

### E0505: Cannot move out of borrowed content
...

### E0507: Cannot move out of behind a shared/mutable reference
...
```

Continue for: **E0106** (missing lifetime specifier), **E0597** (value does not live long enough), **E0515** (cannot return reference to local variable), **E0621** (explicit lifetime required), **E0373** (closure may outlive current function).

Include a **"Common Refactoring Strategies"** section at the end:

```markdown
## Common Refactoring Strategies

### Strategy: Extract to owned type
When lifetime errors become complex, consider returning owned types (`String`
instead of `&str`, `Vec<T>` instead of `&[T]`). This trades a small allocation
for simpler code.

### Strategy: Scope narrowing
Limit the scope of borrows by introducing inner blocks `{ ... }`. The borrow
ends at the closing brace, freeing the value for other uses.

### Strategy: Split struct into borrowed and owned parts
If a struct holds references and is causing lifetime headaches, consider
splitting it into a "builder" (owned) and a "view" (borrowed).

### Strategy: Use interior mutability
`RefCell<T>` (single-thread) or `Mutex<T>` / `RwLock<T>` (multi-thread)
move borrow checking to runtime when the static rules are too restrictive.

## Getting More Help
Run `rustc --explain E0xxx` for the official explanation of any error code.
```

**Authoring guidance:** This is the most important skill — borrow checker errors
are Rust's hardest concept for developers. Each of the 10 error entries should
include:
- **What it means** — 2–3 sentences explaining the violation
- **Common root causes** — 3–5 bullet points with concrete scenarios
- **Resolution patterns** — numbered list of fix strategies, each with a short
  Rust code snippet showing the fix (not just describing it)
- Use `// Before` / `// After` comment pairs in code snippets where helpful
- Cross-reference related errors (e.g., E0502 → mention E0499 as the mutable equivalent)

The **"Mental Model"** section at the top is critical — it should be ~20 lines
that give the reader a working understanding of Rust's ownership model before
they dive into specific errors.

**Approximate length:** 500–600 lines.

### 3.4 `skills/rust-error-handling/SKILL.md`

**Frontmatter:**

```yaml
---
name: rust-error-handling
description: "Rust error handling design patterns and best practices. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when designing error types, choosing between Result and panic, or reviewing error handling quality. Covers canonical error structs with Backtrace, thiserror for libraries, anyhow/eyre for applications, the ? operator, error kind patterns, and when to panic vs return errors. DO NOT use for non-Rust projects."
---
```

**Body structure:**

```markdown
# Rust Error Handling Patterns

## Core Principle: Result vs Panic

Rust has two error mechanisms:
- **`Result<T, E>`** — for recoverable errors (I/O failures, invalid input,
  network errors). The caller decides how to handle it.
- **`panic!`** — for unrecoverable programming bugs (violated invariants,
  impossible states). The program should stop.

### When to use `Result`
- File not found, permission denied
- Network timeout, connection refused
- Invalid user input, parse failures
- Any error the caller might want to handle differently

### When to panic
- Index out of bounds in internal logic (bug, not user error)
- Violated invariants that indicate a programming error
- `unwrap()` / `expect()` during initialization where failure means
  misconfiguration (e.g., compiling a known-good regex)

**Rule:** If a detected error is a programming bug, panic. If it's a runtime
condition that could happen in normal operation, return `Result`.

---

## Pattern 1: Application Error Handling — `anyhow` / `eyre`

For **binary crates** (applications, CLI tools, servers), use `anyhow` or `eyre`
for ergonomic error handling. These crates provide a type-erased error that can
hold any `std::error::Error` and supports context/backtrace.

```rust
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .context("Failed to read config file")?;
    let config: Config = serde_json::from_str(&content)
        .context("Failed to parse config JSON")?;
    Ok(config)
}

fn main() -> Result<()> {
    let config = load_config("config.json")?;
    run_app(config)?;
    Ok(())
}
```

**When to choose anyhow vs eyre:**
- `anyhow` — simpler, well-established, good for most applications
- `eyre` — same API but customizable error reporting (e.g., `color-eyre` for
  colorized backtraces)

---

## Pattern 2: Library Error Handling — `thiserror`

For **library crates**, define explicit error types so callers can match on
specific error variants. Use `thiserror` to derive the `std::error::Error`
implementation.

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum DataError {
    #[error("Record not found: {id}")]
    NotFound { id: String },

    #[error("Permission denied for user {user}")]
    PermissionDenied { user: String },

    #[error("Database error")]
    Database(#[from] sqlx::Error),

    #[error("Invalid input: {0}")]
    InvalidInput(String),
}
```

**Key principles:**
- Each variant has a human-readable message via `#[error("...")]`
- Use `#[from]` to auto-implement `From<SourceError>` for wrapping
- Include relevant context in variant fields (IDs, names, paths)
- Variants are the "error kind" — callers can match on them

---

## Pattern 3: Canonical Error Structs (Microsoft Guideline)

For larger libraries, go beyond enums and use **canonical error structs** with
rich context:

```rust
use std::backtrace::Backtrace;
use thiserror::Error;

#[derive(Debug, Error)]
#[error("{message}")]
pub struct AppError {
    message: String,
    kind: AppErrorKind,
    backtrace: Backtrace,
    #[source]
    cause: Option<Box<dyn std::error::Error + Send + Sync>>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AppErrorKind {
    NotFound,
    PermissionDenied,
    InvalidInput,
    Internal,
}

impl AppError {
    pub fn not_found(msg: impl Into<String>) -> Self {
        Self {
            message: msg.into(),
            kind: AppErrorKind::NotFound,
            backtrace: Backtrace::capture(),
            cause: None,
        }
    }

    pub fn kind(&self) -> AppErrorKind {
        self.kind
    }
}
```

**Benefits:**
- Backtrace captured at error creation (requires `RUST_BACKTRACE=1`)
- Error kind is a simple enum for matching, separate from the message
- Cause chain via `#[source]` for wrapping underlying errors
- Constructor helpers (`not_found(...)`) make creation ergonomic

---

## Pattern 4: The `?` Operator and Error Conversion

The `?` operator propagates errors and auto-converts via `From` implementations:

```rust
fn process(path: &str) -> Result<Data, AppError> {
    let content = std::fs::read_to_string(path)?;  // io::Error → AppError via From
    let data = parse(&content)?;                     // ParseError → AppError via From
    Ok(data)
}
```

**Make `?` work by implementing `From`:**
```rust
impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError {
            message: err.to_string(),
            kind: AppErrorKind::Internal,
            backtrace: Backtrace::capture(),
            cause: Some(Box::new(err)),
        }
    }
}
```

Or use `thiserror`'s `#[from]` attribute for automatic implementation.

---

## Anti-Patterns to Avoid

### `.unwrap()` everywhere
```rust
// BAD: panics on any error
let file = std::fs::read_to_string("config.json").unwrap();

// GOOD: propagate the error
let file = std::fs::read_to_string("config.json")?;

// ACCEPTABLE: only in tests or with guaranteed-valid values
let regex = Regex::new(r"^\d+$").unwrap();  // known-good pattern
```

### Stringly-typed errors
```rust
// BAD: caller can't programmatically match error kinds
fn load() -> Result<Data, String> {
    Err("file not found".to_string())
}

// GOOD: use typed errors
fn load() -> Result<Data, DataError> {
    Err(DataError::NotFound { id: "config".into() })
}
```

### `Box<dyn Error>` as the only error type
```rust
// BAD for libraries: erases all type information
fn process() -> Result<(), Box<dyn std::error::Error>> { ... }

// GOOD for libraries: typed errors
fn process() -> Result<(), ProcessError> { ... }

// ACCEPTABLE for applications: use anyhow instead
fn process() -> anyhow::Result<()> { ... }
```

### Swallowing errors silently
```rust
// BAD: error is discarded
let _ = write_log("event happened");

// GOOD: at minimum, log the error
if let Err(e) = write_log("event happened") {
    eprintln!("Warning: failed to write log: {e}");
}
```

---

## Quick Reference: Choosing an Error Strategy

| Context | Strategy | Crate |
|---------|----------|-------|
| Binary / CLI app | `anyhow::Result` with `.context()` | `anyhow` |
| Web server / service | `anyhow` or custom error with HTTP status mapping | `anyhow` or `thiserror` |
| Library (public API) | `thiserror` enum or canonical error struct | `thiserror` |
| Large library | Canonical error struct with Backtrace + kind enum | `thiserror` |
| Tests | `.unwrap()` or `#[test] fn x() -> Result<(), E>` | (none) |
| Prototyping | `anyhow` or `.unwrap()` | `anyhow` |
```

**Authoring guidance:** This skill has the most prescribed content already in
the plan (Patterns 1–4 + Anti-patterns + Quick Reference are all written above).
The implementer should copy the body text from this plan section nearly verbatim,
then review for completeness. Ensure:
- All code examples compile (the `anyhow`/`thiserror` examples reference types
  like `Config` and `sqlx::Error` — use comments like `// assuming sqlx is
  in [dependencies]` where needed)
- The canonical error struct pattern uses `std::backtrace::Backtrace` (stabilized
  in Rust 1.65+, which is well within any stable toolchain from 2023 onward)

**Approximate length:** 300–400 lines.

---

## 4. Agent Specification

### `agents/rust.agent.md`

```markdown
---
name: rust
description: "Expert agent for Rust development: build troubleshooting, compiler error diagnosis, borrow checker resolution, error handling design, and project configuration. Routes to specialized skills based on error type. Verifies Rust domain relevance before proceeding. Specializes in cargo build, clippy diagnostics, ownership/lifetime analysis, and idiomatic Rust patterns."
user-invokable: true
disable-model-invocation: false
---

# Rust Expert Agent

You are an expert in Rust programming and the Cargo build system. You help
developers build Rust projects, diagnose compiler errors, resolve borrow checker
issues, design error handling, and write idiomatic Rust code.

## Core Competencies
- Running and configuring Rust builds (`cargo build`, `cargo check`, `cargo test`,
  `cargo clippy`, `cargo run`)
- Analyzing Rust compiler errors (E0xxx codes) and clippy diagnostics
- Understanding Cargo project files (`Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`)
- Resolving ownership, borrowing, and lifetime errors
- Designing error handling strategies (thiserror, anyhow, Result patterns)
- Reviewing code for idiomatic Rust patterns

## Domain Relevance Check

Before activating Rust-specific knowledge, verify domain relevance using the
signals in `shared/domain-check.md`.

**Quick check (do first):**
1. Is there a `Cargo.toml` in the workspace?
2. Are there `*.rs` files?
3. Does the error output contain `E0xxx` codes or `rustc`/`cargo` references?

If **any** of these are true → proceed with Rust skills.

**If uncertain:**
- Search for `**/Cargo.toml`, `**/*.rs`
- Check for `target/` directory
- If none found → do not activate Rust skills. Inform the user this agent
  handles Rust projects.

## Triage and Routing

| User Intent | Action |
|-------------|--------|
| Build failed with E0382, E0499, E0502, E0505, E0507, E0106, E0597, E0515, E0621, E0373 | This agent + **borrow-checker-errors** skill |
| Build failed with E0308, E0277, E0425, E0432, E0433, E0004, E0384, E0596, E0599, E0658 | This agent + **common-rust-errors** skill |
| Any other `E0xxx` error | This agent + **common-rust-errors** skill (best-effort) |
| Error handling design, `.unwrap()` issues, error type review | This agent + **rust-error-handling** skill |
| Cargo dependency issues, feature conflicts | This agent (built-in knowledge) |
| Clippy warnings | This agent (built-in knowledge; clippy-diagnostics skill planned for V2) |
| Performance issues | This agent (built-in knowledge; rust-performance skill planned for V2) |
| Code review, style | This agent (built-in knowledge; rust-code-review agent planned for V2) |
| Generate tests | This agent (built-in knowledge; rust-test-gen agent planned for V2) |

## Troubleshooting Workflow

1. **Understand the error:** Read the full compiler output. Identify error codes.
2. **Consult the right skill:** Use the routing table above to load relevant knowledge.
3. **Diagnose root cause:** Trace the error to the specific code issue.
4. **Apply fix:** Make the minimal change that resolves the error correctly.
5. **Verify:** Run `cargo build` (or `cargo check` for speed) to confirm the fix.
6. **Check for cascading issues:** One fix may reveal new errors. Iterate.
7. **Polish:** After all errors are resolved, run `cargo clippy` for quality suggestions.

## Cargo Quick Reference

| Command | Purpose |
|---------|---------|
| `cargo build` | Compile the project |
| `cargo check` | Type-check without codegen (faster) |
| `cargo test` | Run all tests (unit, integration, doc) |
| `cargo clippy --all-targets -- -D warnings` | Run linter with warnings as errors |
| `cargo fmt --check` | Check formatting |
| `cargo build --release` | Compile with optimizations |
| `cargo doc --open` | Generate and open documentation |
| `rustc --explain E0xxx` | Get detailed explanation of an error code |

## Specialized Rust Skills

### Build Failure Troubleshooting
- **common-rust-errors** — Catalog of type, resolution, pattern, mutability, and
  trait errors with step-by-step fixes
- **borrow-checker-errors** — Deep ownership/borrowing/lifetime error resolution
  with refactoring strategies

### Error Handling Design
- **rust-error-handling** — Result vs panic, thiserror, anyhow, canonical error
  structs, anti-patterns
```

---

## 5. Test Case Specifications

### General Conventions

Each test case is a minimal Cargo project under `testcases/<name>/`:
- `Cargo.toml` — minimal manifest (prefer `std`-only dependencies)
- `rust-toolchain.toml` — pins stable toolchain
- `src/main.rs` or `src/lib.rs` — intentionally broken or flawed code
- `expected-output.md` — scoring rubric (10-point checklist)
- `README.md` — human documentation (excluded from eval)
- No `eval-test-prompt.txt` needed — default prompt ("Analyze the build issues...") works for build-error scenarios

> **Important — error cascading:** Rust reports errors in passes. Import resolution errors
> (E0432, E0433) fire before type-checking, so some type errors may not appear until
> imports are fixed. Similarly, earlier errors in a function may mask later ones.
> **Always run `cargo build` on each test case and reconcile the actual compiler output
> with `expected-output.md`.** Adjust the rubric if any expected errors don't appear
> because they're masked by earlier failures.

### `testcases/README.md`

Content for the test cases README:

```markdown
# Rust Skills — Test Cases

This directory contains sample Rust projects designed to test and demo each
Rust skill. Each sample intentionally contains specific issues that the
corresponding skill(s) should help diagnose and fix.

## Test Case Matrix

| Test Case | Skills Tested | Issue Type | Build Result | Eval? |
|-----------|--------------|------------|--------------|-------|
| [`borrow-errors`](borrow-errors/) | `borrow-checker-errors`, `common-rust-errors` | E0382, E0502, E0597 (ownership/borrow) | ❌ Fails | ✅ |
| [`type-errors`](type-errors/) | `common-rust-errors` | E0308, E0004 (type mismatch, non-exhaustive) | ❌ Fails | ✅ |
| [`import-resolution`](import-resolution/) | `common-rust-errors` | E0432, E0433 (unresolved imports/modules) | ❌ Fails | ✅ |
| [`poor-error-handling`](poor-error-handling/) | `rust-error-handling` | `.unwrap()` abuse, stringly-typed errors | ⚠️ Builds (but fragile) | ✅ |

## How to Use

### For Testing Skills
1. Open a test case directory in VS Code with the Rust skills plugin installed
2. Ask Copilot to analyze the project (or run the eval pipeline)
3. Compare the response against `expected-output.md`

### For Running Evaluations
The evaluation pipeline (`eng/evaluation/`) auto-discovers test cases by
finding `expected-output.md` in each subdirectory. See the
[evaluation README](../../eng/evaluation/README.md) for setup instructions.

## Conventions
- Each test case is a self-contained Cargo project
- `rust-toolchain.toml` pins the stable toolchain
- Projects use only `std` dependencies (no crates.io downloads needed)
- `expected-output.md` contains a 10-point scoring rubric
- `README.md` documents the test case for humans (excluded from eval)
- No hint-comments (`// ERROR: ...`, `// FIX: ...`) in source files
```

**Standard `rust-toolchain.toml` for all test cases:**

```toml
[toolchain]
channel = "stable"
components = ["clippy", "rustfmt"]
```

### 5.1 Test Case: `borrow-errors`

**Skills tested:** `borrow-checker-errors`, `common-rust-errors`
**Build result:** Fails

**`Cargo.toml`:**
```toml
[package]
name = "borrow-errors"
version = "0.1.0"
edition = "2021"
```

**`src/main.rs`:**
```rust
fn main() {
    // E0382: Use of moved value
    let names = vec!["Alice".to_string(), "Bob".to_string()];
    let moved_names = names;
    println!("First name: {}", names[0]);

    // E0502: Cannot borrow as immutable because also borrowed as mutable
    let mut data = vec![1, 2, 3, 4, 5];
    let first = &data[0];
    data.push(6);
    println!("First element: {}", first);

    // E0597: Value does not live long enough
    let reference;
    {
        let short_lived = String::from("temporary");
        reference = &short_lived;
    }
    println!("Reference: {}", reference);
}
```

**`expected-output.md`:**
```markdown
# Expected Findings: borrow-errors

## Problem Summary
A Rust project fails to compile due to three borrow checker violations:
use of a moved value, conflicting borrows, and a dangling reference.

## Expected Findings

### 1. E0382 — Use of moved value
- **Location:** `names` is moved to `moved_names`, then used on the next line
- **Root cause:** `Vec<String>` does not implement `Copy`; assignment moves ownership
- **Fix:** Clone the vector (`names.clone()`), borrow instead of move (`&names`),
  or restructure to use `moved_names` instead of `names` after the move

### 2. E0502 — Cannot borrow as immutable because also borrowed as mutable
- **Location:** `first` immutably borrows `data`, then `data.push(6)` mutably borrows it while `first` is still live
- **Root cause:** Immutable and mutable borrows cannot coexist
- **Fix:** Use `first` before calling `push()`, or clone the value from `first` before mutating

### 3. E0597 — Value does not live long enough
- **Location:** `short_lived` is created inside an inner block, a reference to it escapes the block
- **Root cause:** The reference outlives the data it points to
- **Fix:** Move the `String` to the outer scope, or return an owned `String` instead of a reference

## Key Concepts
- Ownership and move semantics
- Borrow rules (one mutable XOR many immutable)
- Lifetime scoping

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified E0382 (use of moved value)
- [ ] Explained that Vec does not implement Copy, so assignment is a move
- [ ] Suggested a valid fix for E0382 (clone, borrow, or restructure)
- [ ] Identified E0502 (conflicting borrows)
- [ ] Explained that immutable and mutable borrows cannot coexist
- [ ] Suggested a valid fix for E0502 (reorder usage or clone)
- [ ] Identified E0597 (value does not live long enough)
- [ ] Explained the dangling reference / lifetime scope issue
- [ ] Suggested a valid fix for E0597 (move to outer scope or own the value)
- [ ] Used correct Rust terminology (ownership, borrow, lifetime, move)

Total: __/10

## Expected Skills
- borrow-checker-errors
- common-rust-errors
```

**`README.md`:**
```markdown
# Borrow Errors Test Case

A minimal Rust project that fails to compile due to three classic borrow checker errors:
E0382 (moved value), E0502 (conflicting borrows), E0597 (dangling reference).

## How to Test
```bash
cargo build
```

## Expected: Build fails with 3 errors
```

### 5.2 Test Case: `type-errors`

**Skills tested:** `common-rust-errors`
**Build result:** Fails

**`Cargo.toml`:**
```toml
[package]
name = "type-errors"
version = "0.1.0"
edition = "2021"
```

**`src/main.rs`:**
```rust
struct Config {
    max_retries: u32,
    timeout_ms: u64,
    verbose: bool,
}

fn connect(address: &str, timeout: u64) -> Result<(), String> {
    if timeout == 0 {
        return Err("timeout must be positive");
    }
    println!("Connecting to {} with timeout {}ms", address, timeout);
    Ok(())
}

fn apply_config(config: &Config) {
    connect(config.timeout_ms, config.max_retries);
}

fn get_status_message(code: u32) -> &'static str {
    match code {
        200 => "OK",
        404 => "Not Found",
    }
}

fn main() {
    let config = Config {
        max_retries: 3,
        timeout_ms: 5000,
        verbose: true,
    };
    apply_config(&config);

    let message: String = get_status_message(200);
    println!("{}", message);
}
```

**`expected-output.md`:**
```markdown
# Expected Findings: type-errors

## Problem Summary
A Rust project fails to compile due to multiple type-related errors: mismatched
types, incorrect argument ordering, a non-exhaustive match, and a missing return
type conversion.

## Expected Findings

### 1. E0308 — Mismatched types in `connect` return
- **Location:** `return Err("timeout must be positive")` returns `&str`, but `Err` expects `String`
- **Fix:** Use `"timeout must be positive".to_string()` or change return type to `Result<(), &'static str>`

### 2. E0308 — Wrong argument types in `apply_config`
- **Location:** `connect()` is called with arguments in wrong order/type — `config.timeout_ms` (u64) as first arg where `&str` expected, and `config.max_retries` (u32) where `u64` expected
- **Fix:** Call `connect(address, config.timeout_ms)` with a proper `&str` address, and handle the Result

### 3. E0004 — Non-exhaustive match in `get_status_message`
- **Location:** `match code` only handles 200 and 404 but `u32` has many other values
- **Fix:** Add a wildcard arm: `_ => "Unknown"`

### 4. E0308 — `&'static str` vs `String` mismatch
- **Location:** `let message: String = get_status_message(200)` — function returns `&'static str` but variable expects `String`
- **Fix:** Remove the type annotation, use `.to_string()`, or change the function return type

### 5. Return value of `connect()` is unused (warning)
- **Location:** `connect(...)` returns `Result` which is not handled
- **Fix:** Add `let _ =` or handle with `?` / `match` / `if let`

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified the &str vs String mismatch in `connect`'s Err return
- [ ] Identified the argument order/type error in `apply_config`
- [ ] Identified E0004 (non-exhaustive match in `get_status_message`)
- [ ] Suggested adding a wildcard `_` arm to the match
- [ ] Identified E0308 for `&'static str` assigned to `String` variable
- [ ] Suggested `.to_string()` or removing the type annotation
- [ ] Noted that `connect()` returns a Result that should be handled
- [ ] Provided correct fixed code for `apply_config`
- [ ] All fixes preserve the intended logic of the program
- [ ] Used correct Rust terminology (type mismatch, exhaustive match, owned vs borrowed)

Total: __/10

## Expected Skills
- common-rust-errors
```

### 5.3 Test Case: `import-resolution`

**Skills tested:** `common-rust-errors`
**Build result:** Fails

**`Cargo.toml`:**
```toml
[package]
name = "import-resolution"
version = "0.1.0"
edition = "2021"
```

**`src/main.rs`:**
```rust
use std::collections::BTreeSet;
use std::io::BufWriter;
use serde::Serialize;
use utils::helpers::format_name;

mod models {
    pub struct User {
        pub name: String,
        pub age: u32,
    }
}

fn write_users(users: &[models::User]) {
    let set: BTreeSet<&str> = users.iter().map(|u| u.name.as_str()).collect();
    let mut writer = BufWriter::new(std::io::stdout());
    for name in &set {
        writeln!(writer, "{}", name);
    }
}

fn main() {
    let users = vec![
        models::User { name: "Alice".to_string(), age: 30 },
        models::User { name: "Bob".to_string(), age: 25 },
    ];
    write_users(&users);

    let serialized = serde_json::to_string(&users);
    println!("{}", format_name("test"));
}
```

**`expected-output.md`:**
```markdown
# Expected Findings: import-resolution

## Problem Summary
A Rust project fails to compile due to unresolved imports and missing dependencies.

## Expected Findings

### 1. E0432 — Unresolved import `serde`
- **Location:** `use serde::Serialize;`
- **Root cause:** `serde` is not listed in `[dependencies]` in Cargo.toml
- **Fix:** Add `serde = { version = "1", features = ["derive"] }` to `[dependencies]`

### 2. E0433 — Unresolved module `utils`
- **Location:** `use utils::helpers::format_name;`
- **Root cause:** No `utils` module or crate exists in the project
- **Fix:** Either create a `utils` module with the function, remove the import, or add `utils` as a dependency if it's an external crate

### 3. E0433 — Unresolved crate `serde_json`
- **Location:** `serde_json::to_string(&users)`
- **Root cause:** `serde_json` not in Cargo.toml dependencies
- **Fix:** Add `serde_json = "1"` to `[dependencies]`

### 4. `writeln!` macro requires `use std::io::Write`
- **Location:** `writeln!(writer, "{}", name);`
- **Root cause:** The `writeln!` macro requires the `Write` trait to be in scope
- **Fix:** Add `use std::io::Write;`

### 5. `writeln!` returns Result that must be used
- **Location:** `writeln!(writer, "{}", name);`
- **Fix:** Handle the Result or use `let _ = writeln!(...)`

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified missing `serde` dependency in Cargo.toml
- [ ] Provided correct Cargo.toml entry for serde with derive feature
- [ ] Identified missing `serde_json` dependency
- [ ] Identified unresolved `utils::helpers` module
- [ ] Suggested creating the module or removing the unused import
- [ ] Identified missing `use std::io::Write` for `writeln!` macro
- [ ] Noted that `Serialize` derive would need to be added to `User` struct
- [ ] Noted the unused Result from `writeln!`
- [ ] Understood distinction between missing crate dependency vs missing module
- [ ] Suggested running `cargo build` after fixes to verify

Total: __/10

## Expected Skills
- common-rust-errors
```

### 5.4 Test Case: `poor-error-handling`

**Skills tested:** `rust-error-handling`
**Build result:** Compiles successfully (code quality issue, not a build failure)

**`Cargo.toml`:**
```toml
[package]
name = "poor-error-handling"
version = "0.1.0"
edition = "2021"
```

**`src/main.rs`:**
```rust
use std::fs;
use std::collections::HashMap;

fn read_config(path: &str) -> HashMap<String, String> {
    let content = fs::read_to_string(path).unwrap();
    let mut config = HashMap::new();
    for line in content.lines() {
        let parts: Vec<&str> = line.split('=').collect();
        let key = parts[0].trim().to_string();
        let value = parts[1].trim().to_string();
        config.insert(key, value);
    }
    config
}

fn parse_port(config: &HashMap<String, String>) -> u16 {
    let port_str = config.get("port").unwrap();
    port_str.parse().unwrap()
}

fn connect_to_server(host: &str, port: u16) -> Result<(), String> {
    if host.is_empty() {
        return Err(format!("host is empty"));
    }
    if port == 0 {
        return Err(format!("invalid port"));
    }
    println!("Connected to {}:{}", host, port);
    Ok(())
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let config = read_config("server.conf");
    let port = parse_port(&config);
    let host = config.get("host").unwrap().clone();
    connect_to_server(&host, port).map_err(|e| e)?;
    Ok(())
}

fn main() {
    match run() {
        Ok(()) => println!("Success"),
        Err(e) => println!("Error: {}", e),
    }
}
```

**`eval-test-prompt.txt`:**
```
Review the error handling in this Rust project. Identify anti-patterns and suggest improvements following Rust best practices for error handling.
```

**`expected-output.md`:**
```markdown
# Expected Findings: poor-error-handling

## Problem Summary
A Rust application compiles but uses poor error handling patterns throughout:
`.unwrap()` calls that will panic at runtime, stringly-typed errors, and
`Box<dyn Error>` instead of typed errors.

## Expected Findings

### 1. `.unwrap()` abuse in `read_config`
- **Issue:** `fs::read_to_string(path).unwrap()` panics if the file doesn't exist
- **Fix:** Return `Result`, propagate with `?`, add context

### 2. Index-without-bounds-check in `read_config`
- **Issue:** `parts[0]` and `parts[1]` panic if line doesn't contain `=`
- **Fix:** Use `split_once('=')` and handle the `None` case

### 3. `.unwrap()` in `parse_port`
- **Issue:** `.unwrap()` on `config.get("port")` and `.parse()` — panics on missing key or invalid number
- **Fix:** Return `Result<u16, Error>` and propagate errors

### 4. Stringly-typed errors in `connect_to_server`
- **Issue:** Returns `Result<(), String>` — caller can't programmatically
  distinguish error types
- **Fix:** Define a typed error enum (e.g., `ConnectionError`) using `thiserror`

### 5. `Box<dyn Error>` in `run`
- **Issue:** For an application entry point, `Box<dyn Error>` is acceptable but
  `anyhow::Result` would provide better context and backtrace support
- **Fix:** Use `anyhow::Result` with `.context()` for meaningful error messages

### 6. `.map_err(|e| e)` is a no-op
- **Issue:** `connect_to_server(...).map_err(|e| e)?` does nothing useful
- **Fix:** Simply use `?` directly, or use `.map_err(|e| ...)` to convert to a different error type

## Key Concepts
- `Result<T, E>` with typed errors for libraries
- `anyhow::Result` for applications
- `thiserror::Error` for custom error types
- The `?` operator for error propagation
- `.context()` for adding error context

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified `.unwrap()` calls as problematic (potential runtime panics)
- [ ] Suggested returning `Result` from `read_config` and `parse_port`
- [ ] Identified the index-without-bounds-check risk (`parts[0]`, `parts[1]`)
- [ ] Suggested `split_once` or similar safe parsing
- [ ] Identified stringly-typed errors in `connect_to_server`
- [ ] Suggested a typed error enum (using `thiserror` or manual impl)
- [ ] Identified `Box<dyn Error>` as suboptimal and suggested `anyhow`
- [ ] Identified the no-op `.map_err(|e| e)`
- [ ] Provided improved code showing proper error propagation with `?`
- [ ] Overall improvement follows Rust conventions (Result, thiserror/anyhow)

Total: __/10

## Expected Skills
- rust-error-handling
```

---

## 6. Build Script

### `build.js`

The build script validates:
1. Every `SKILL.md` has YAML frontmatter with `name` and `description`
2. Every skill's description contains the domain gate phrase

```javascript
#!/usr/bin/env node

// Build entry point for the rust-skills component.
// Validates skills.
// Run: node src/rust-skills/build.js

const fs = require("node:fs");
const path = require("node:path");

const SKILLS_DIR = path.resolve(__dirname, "skills");
const DOMAIN_GATE_PATTERN = /Only activate in Rust\/Cargo build contexts/;

// ── Step 1: Validate skills ─────────────────────────────────────────

console.log("=== Validating skills ===\n");

let errors = 0;

const skillDirs = fs.readdirSync(SKILLS_DIR, { withFileTypes: true })
  .filter(d => d.isDirectory() && d.name !== "shared");

for (const dir of skillDirs) {
  const skillFile = path.join(SKILLS_DIR, dir.name, "SKILL.md");
  if (!fs.existsSync(skillFile)) continue;

  const content = fs.readFileSync(skillFile, "utf-8");

  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) {
    console.error(`❌ ${dir.name}: Missing YAML frontmatter`);
    errors++;
    continue;
  }

  const frontmatter = match[1];
  const descMatch = frontmatter.match(/description:\s*"([^"]*)"/);
  if (!descMatch) {
    console.error(`❌ ${dir.name}: Missing description in frontmatter`);
    errors++;
    continue;
  }

  const description = descMatch[1];
  if (!DOMAIN_GATE_PATTERN.test(description)) {
    console.error(`❌ ${dir.name}: Description missing domain gate. Must include 'Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals).'`);
    errors++;
  }
}

if (errors > 0) {
  console.error(`\n${errors} validation error(s) found.`);
  process.exit(1);
} else {
  console.log(`✅ All ${skillDirs.length} skills pass validation.\n`);
}

console.log("✅ Build complete.");
```

**Note:** Unlike the `msbuild-skills` build script, Phase 1 does not include knowledge bundle compilation (no copilot-extension or agentic-workflows targets yet). This can be added in V2 if a `@rust` Copilot Extension or agentic workflows are created.

---

## 7. Evaluation Pipeline Changes

### 7.1 Docker Image — Add Rust Toolchain

In the Docker image build step (from `eng/evaluation/README.md`), add after the dotnet/copilot installs:

```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustup component add clippy rustfmt
# Warm the cargo registry index
cargo search serde --limit 1 > /dev/null 2>&1
```

Update the docker build documentation in `eng/evaluation/README.md` to include this block.

### 7.2 Eval Script Compatibility

The existing `run-scenario.ps1` copies test case files to a temp directory and invokes Copilot CLI with a prompt. **No changes to `run-scenario.ps1` are strictly required** for Phase 1 because:

1. File copying is generic (copies all files except `expected-output.md`, `eval-test-prompt.txt`, `README.md`, `.gitignore`)
2. The default prompt ("Analyze the build issues...") is generic enough
3. Copilot should recognize `Cargo.toml` and `*.rs` files and use `cargo build`
4. The `poor-error-handling` test case provides a custom `eval-test-prompt.txt` since it's a code review, not a build failure

**However, for robustness**, consider this optional enhancement to `run-scenario.ps1`:

```powershell
# After copying files to temp dir, detect project type
$isRust = Test-Path (Join-Path $TempDir "Cargo.toml")
$isDotNet = Get-ChildItem $TempDir -Filter "*.csproj" -Recurse | Select-Object -First 1

# Adjust default prompt based on project type
if (-not $CustomPrompt) {
    if ($isRust) {
        $DefaultPrompt = "Analyze the build issues in this Rust project. Run 'cargo build' to see errors, diagnose root causes, and suggest fixes."
    } else {
        $DefaultPrompt = "Analyze the build issues in this .NET project."
    }
}
```

This is **recommended but not blocking** for Phase 1.

### 7.3 Scenario Discovery

The evaluation pipeline auto-discovers scenarios by finding `testcases/*/expected-output.md`. The Rust test cases follow this convention, so they will be discovered automatically when the plugin is selected for evaluation.

---

## 8. Implementation Order & Checklist

Execute in this order. Each step should be a commit-ready unit.

### Step 1: Scaffold Plugin Structure
- [ ] Create `src/rust-skills/plugin.json`
- [ ] Create `src/rust-skills/README.md`
- [ ] Create `src/rust-skills/AGENTS.md`
- [ ] Create `src/rust-skills/build.js`
- [ ] Create empty directories: `agents/`, `skills/`, `skills/shared/`, `testcases/`
- [ ] Verify: `node src/rust-skills/build.js` runs (0 skills, no errors)

### Step 2: Domain Check (shared skill)
- [ ] Create `src/rust-skills/skills/shared/domain-check.md` (full content from §3.1)
- [ ] Verify: file is well-formed markdown

### Step 3: Common Rust Errors Skill
- [ ] Create `src/rust-skills/skills/common-rust-errors/SKILL.md` (full content from §3.2)
- [ ] Cover all 10 error codes with: What it means, Common root causes, Step-by-step fix, Prevention
- [ ] Include cross-reference to `borrow-checker-errors` skill
- [ ] Include "Getting More Help" section (`rustc --explain E0xxx`)
- [ ] Verify: `node src/rust-skills/build.js` passes validation

### Step 4: Borrow Checker Errors Skill
- [ ] Create `src/rust-skills/skills/borrow-checker-errors/SKILL.md` (full content from §3.3)
- [ ] Cover all 10 borrow/lifetime error codes with resolution patterns and code examples
- [ ] Include ownership mental model section
- [ ] Include refactoring strategies section
- [ ] Verify: `node src/rust-skills/build.js` passes validation

### Step 5: Error Handling Skill
- [ ] Create `src/rust-skills/skills/rust-error-handling/SKILL.md` (full content from §3.4)
- [ ] Cover: anyhow, thiserror, canonical structs, `?` operator, anti-patterns
- [ ] Include code examples for each pattern
- [ ] Include quick-reference table
- [ ] Verify: `node src/rust-skills/build.js` passes validation

### Step 6: Rust Agent
- [ ] Create `src/rust-skills/agents/rust.agent.md` (full content from §4)
- [ ] Verify: frontmatter has `name`, `description`, `user-invokable`, `disable-model-invocation`
- [ ] Verify: routing table covers all skills

### Step 7: Test Case — `borrow-errors`
- [ ] Create directory `src/rust-skills/testcases/borrow-errors/`
- [ ] Create `Cargo.toml`, `rust-toolchain.toml`, `src/main.rs` (from §5.1)
- [ ] Create `expected-output.md` with 10-point checklist
- [ ] Create `README.md`
- [ ] Verify: `cargo build` in that directory fails with exactly E0382, E0502, E0597

### Step 8: Test Case — `type-errors`
- [ ] Create directory `src/rust-skills/testcases/type-errors/`
- [ ] Create `Cargo.toml`, `rust-toolchain.toml`, `src/main.rs` (from §5.2)
- [ ] Create `expected-output.md` with 10-point checklist
- [ ] Create `README.md`
- [ ] Verify: `cargo build` fails with E0308, E0004, and related errors

### Step 9: Test Case — `import-resolution`
- [ ] Create directory `src/rust-skills/testcases/import-resolution/`
- [ ] Create `Cargo.toml`, `rust-toolchain.toml`, `src/main.rs` (from §5.3)
- [ ] Create `expected-output.md` with 10-point checklist
- [ ] Create `README.md`
- [ ] Verify: `cargo build` fails with E0432, E0433 errors

### Step 10: Test Case — `poor-error-handling`
- [ ] Create directory `src/rust-skills/testcases/poor-error-handling/`
- [ ] Create `Cargo.toml`, `rust-toolchain.toml`, `src/main.rs` (from §5.4)
- [ ] Create `eval-test-prompt.txt` (custom prompt for code review scenario)
- [ ] Create `expected-output.md` with 10-point checklist
- [ ] Create `README.md`
- [ ] Verify: `cargo build` succeeds (this is a code quality test case, not a build failure)

### Step 11: Final Validation
- [ ] Run `node src/rust-skills/build.js` — all skills pass
- [ ] Verify `plugin.json` version is `1.0.0`
- [ ] Review all `expected-output.md` checklists total exactly 10 points each
- [ ] Ensure no hint-comments in test case source files
- [ ] Verify directory layout matches the scaffold in §2

### Step 12: Documentation Updates (optional, recommended)
- [ ] Update `eng/evaluation/README.md` Docker setup to include Rust toolchain
- [ ] Optionally enhance `run-scenario.ps1` with Cargo.toml detection for default prompt

---

## 9. V2 Roadmap Summary

After Phase 1 ships and eval results are reviewed, the following can be added incrementally (each is a minor version bump):

| Priority | Component | Version Bump |
|----------|-----------|-------------|
| **P1** | `rust-unit-testing` skill + `calculator-rust` test case | 1.1.0 |
| **P1** | `rust-style-guide` skill + `rust-antipatterns` skill | 1.2.0 |
| **P1** | `cargo-build-errors` skill + `missing-crate-dep` test case | 1.3.0 |
| **P1** | `rust-code-review.agent.md` | 1.4.0 |
| **P2** | `rust-api-design` skill + `clippy-diagnostics` skill | 1.5.0 |
| **P2** | `rust-crate-structure` skill + `rust-type-design` skill | 1.6.0 |
| **P2** | `async-rust-patterns` skill + `async-pitfalls` test case | 1.7.0 |
| **P2** | `rust-static-analysis` skill + `rust-performance` skill | 1.8.0 |
| **P3** | `rust-unsafe-guide`, `rust-documentation-standards`, `rust-structured-logging` | 1.9.0 |
| **P3** | Copilot Extension (`@rust`), agentic workflows, prompt templates | 2.0.0 |

---

## Appendix A: File Sizes & Token Budget Estimates

For context-window planning, approximate sizes of each skill:

| Skill | Estimated Lines | Estimated Chars | Estimated Tokens |
|-------|---------------:|----------------:|-----------------:|
| `common-rust-errors` | 400–500 | 15,000–20,000 | ~4,000–5,000 |
| `borrow-checker-errors` | 500–600 | 20,000–25,000 | ~5,000–6,500 |
| `rust-error-handling` | 300–400 | 12,000–16,000 | ~3,000–4,000 |
| `domain-check` | 80–100 | 3,000–4,000 | ~800–1,000 |
| **Total** | **~1,400** | **~55,000** | **~14,000** |

This is well within typical context window limits. The agent can selectively load only the relevant skill(s) per query.

## Appendix B: Exact Frontmatter Templates

Every `SKILL.md` must match this structure exactly for `build.js` validation:

```yaml
---
name: <skill-name>
description: "<description>. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). <when-to-use>. <when-not-to-use>."
---
```

Every `*.agent.md` must match:

```yaml
---
name: <agent-name>
description: "<description>"
user-invokable: true
disable-model-invocation: false
---
```

## Appendix C: Test Verification Commands

Run these commands from the repo root to verify test cases before submitting:

```powershell
# Verify borrow-errors fails to build
Push-Location src/rust-skills/testcases/borrow-errors
cargo build 2>&1 | Select-String "E0382|E0502|E0597"
Pop-Location

# Verify type-errors fails to build
Push-Location src/rust-skills/testcases/type-errors
cargo build 2>&1 | Select-String "E0308|E0004"
Pop-Location

# Verify import-resolution fails to build
Push-Location src/rust-skills/testcases/import-resolution
cargo build 2>&1 | Select-String "E0432|E0433"
Pop-Location

# Verify poor-error-handling builds successfully
Push-Location src/rust-skills/testcases/poor-error-handling
cargo build 2>&1
# Should exit 0 with no errors
Pop-Location

# Validate all skills
node src/rust-skills/build.js
```
