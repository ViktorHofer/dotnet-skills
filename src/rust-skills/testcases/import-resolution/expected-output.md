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
