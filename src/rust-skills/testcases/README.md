# Rust Skills — Test Cases

This directory contains sample Rust projects designed to test and demo each
Rust skill. Each sample intentionally contains specific issues that the
corresponding skill(s) should help diagnose and fix.

## Test Case Matrix

| Test Case | Skills Tested | Issue Type | Build Result | Eval? |
|-----------|--------------|------------|--------------|-------|
| [`borrow-errors`](borrow-errors/) | `borrow-checker-errors`, `common-rust-errors` | E0382, E0502, E0597 (ownership/borrow) | :x: Fails | :white_check_mark: |
| [`type-errors`](type-errors/) | `common-rust-errors` | E0308, E0004 (type mismatch, non-exhaustive) | :x: Fails | :white_check_mark: |
| [`import-resolution`](import-resolution/) | `common-rust-errors` | E0432, E0433 (unresolved imports/modules) | :x: Fails | :white_check_mark: |
| [`poor-error-handling`](poor-error-handling/) | `rust-error-handling` | `.unwrap()` abuse, stringly-typed errors | :warning: Builds (but fragile) | :white_check_mark: |

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
