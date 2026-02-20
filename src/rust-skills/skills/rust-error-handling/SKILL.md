---
name: rust-error-handling
description: "Rust error handling design patterns and best practices. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when designing error types, choosing between Result and panic, or reviewing error handling quality. Covers canonical error structs with Backtrace, thiserror for libraries, anyhow/eyre for applications, the ? operator, error kind patterns, and when to panic vs return errors. DO NOT use for non-Rust projects."
---

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
    Database(#[from] sqlx::Error),  // assuming sqlx is in [dependencies]

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
fn process() -> Result<(), Box<dyn std::error::Error>> {
    // ...
    Ok(())
}

// GOOD for libraries: typed errors
fn process() -> Result<(), ProcessError> {
    // ...
    Ok(())
}

// ACCEPTABLE for applications: use anyhow instead
fn process() -> anyhow::Result<()> {
    // ...
    Ok(())
}
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

---

## Getting More Help

- [`thiserror` documentation](https://docs.rs/thiserror)
- [`anyhow` documentation](https://docs.rs/anyhow)
- [`eyre` documentation](https://docs.rs/eyre)
- [Rust Error Handling Working Group](https://blog.rust-lang.org/inside-rust/2020/11/23/What-the-error-handling-project-group-is-working-on.html)
- [The Rust Book — Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
