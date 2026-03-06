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

### Tooling & IDE Integration

| Skill | Description |
|-------|-------------|
| [`rust-analyzer-setup`](skills/rust-analyzer-setup/) | rust-analyzer installation, Copilot CLI LSP integration, workspace configuration |

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
| [`rust-analyzer-config`](testcases/rust-analyzer-config/) | rust-analyzer-setup | Misconfigured Copilot CLI LSP integration and rust-analyzer settings |
| [`rust-lsp-usage`](testcases/rust-lsp-usage/) | rust-analyzer-setup | Uses LSP capabilities (find impls, references, go-to-def) to answer code intelligence questions |
