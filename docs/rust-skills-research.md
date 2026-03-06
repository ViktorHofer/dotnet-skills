# Rust Skills & Test Cases — Research Document

> **Purpose:** Brainstorm and catalog potential Rust skills and evaluation test cases for the `rust-skills` plugin.
> This is a research-only document — no implementation decisions are finalized here.
> **Date:** 2026-02-19

---

## Important Note on Guideline IDs

This research document references `M-XXX` IDs (e.g., M-ERRORS-CANONICAL-STRUCTS) from Microsoft's internal Rust Guidelines and `C-XXX` IDs (e.g., C-COMMON-TRAITS) from the official Rust API Guidelines. **These IDs are used here only for traceability back to source material** — so we know where each guideline originated during planning and implementation.

**These IDs must NOT appear in the actual skill text.** The `M-` IDs are internal anchors in a single Microsoft document and are not recognized by the broader Rust community. The `C-` IDs from the Rust API Guidelines have slightly more recognition but are still niche. In final skills, guideline content should be rewritten in plain language. Links to the source documents can appear under "Further Reading" sections, but skills should never assume readers know these ID schemes.

---

## Table of Contents

1. [Existing Workspace Patterns](#1-existing-workspace-patterns)
2. [Source Material: Microsoft Rust Guidelines](#2-source-material-microsoft-rust-guidelines)
3. [Source Material: Rust Ecosystem](#3-source-material-rust-ecosystem)
4. [Proposed Skills Catalog](#4-proposed-skills-catalog)
5. [Proposed Agents](#5-proposed-agents)
6. [Proposed Test Cases](#6-proposed-test-cases)
7. [Evaluation Pipeline — Rust Toolchain Requirements](#7-evaluation-pipeline--rust-toolchain-requirements)
8. [Open Questions](#8-open-questions)

---

## 1. Existing Workspace Patterns

### Plugin Structure
Each plugin lives under `src/<plugin-name>/` and has:
- `plugin.json` — name, version (semver), description, paths to skills/agents
- `skills/<skill-name>/SKILL.md` — skill definition with YAML frontmatter (`name`, `description`) and markdown body
- `agents/<name>.agent.md` — agent definition with YAML frontmatter and routing/triage logic
- `testcases/<name>/` — evaluation scenarios with project files + `expected-output.md` + optional `eval-test-prompt.txt`
- Optional: `prompts/`, `agentic-workflows/`, `build.js`, `AGENTS.md`, `README.md`

### Skill Anatomy (from `msbuild-skills`)
- Frontmatter: `name`, `description` (includes when to/not to use, domain signals)
- Body: knowledge base organized by error codes / categories, step-by-step fixes, prevention tips
- Skills are self-contained reference material, not procedural agents

### Agent Anatomy (from `msbuild-skills`)
- Frontmatter: `name`, `description`, `user-invokable`, `disable-model-invocation`
- Body: persona, core competencies, domain relevance check, triage & routing table, documentation references
- Agents route to specific skills based on user intent

### Test Case Anatomy
- A directory of project files that exhibit a specific problem
- `expected-output.md` — grading rubric with problem summary, expected findings, key concepts, evaluation checklist (scored /10)
- `eval-test-prompt.txt` (optional) — custom prompt; default is "Analyze the build issues..."
- `README.md` — human documentation, excluded from eval
- Files are copied to a temp dir; `expected-output.md`, `eval-test-prompt.txt`, `README.md`, `.gitignore` are excluded from the copy

### Evaluation Pipeline
- Runs each scenario twice: vanilla (no plugin) vs skilled (with plugin)
- LLM-as-judge scores both against rubric on Accuracy, Completeness, Actionability, Clarity (0–10)
- Discovery: auto-finds `testcases/*/expected-output.md`
- Uses PowerShell scripts in `eng/evaluation/`

---

## 2. Source Material: Microsoft Rust Guidelines

**Source:** https://microsoft.github.io/rust-guidelines/agents/all.txt

This is an extraordinarily rich source for crafting skills. The guidelines are organized into these sections:

### 2.1 AI Guidelines
- **M-DESIGN-FOR-AI** — Design with AI use in mind (idiomatic patterns, good docs, testability)
- Directly relevant as a "meta-skill" for Rust code review

### 2.2 Application Guidelines
- **M-APP-ERROR** — Applications may use anyhow/eyre for error handling
- **M-MIMALLOC-APPS** — Use mimalloc as global allocator for performance

### 2.3 Documentation Guidelines
- **M-CANONICAL-DOCS** — Documentation has canonical sections (Summary, Examples, Errors, Panics, Safety, Abort)
- **M-DOC-INLINE** — Mark `pub use` items with `#[doc(inline)]`
- **M-FIRST-DOC-SENTENCE** — First sentence is one line, ~15 words
- **M-MODULE-DOCS** — Comprehensive module documentation

### 2.4 FFI Guidelines
- **M-ISOLATE-DLL-STATE** — Isolate DLL state between FFI libraries

### 2.5 Performance Guidelines
- **M-HOTPATH** — Identify, profile, optimize the hot path early
- **M-THROUGHPUT** — Optimize for throughput, avoid empty cycles
- **M-YIELD-POINTS** — Long-running tasks should have yield points

### 2.6 Safety Guidelines
- **M-UNSAFE-IMPLIES-UB** — `unsafe` implies undefined behavior risk
- **M-UNSAFE** — Unsafe needs reason, should be avoided
- **M-UNSOUND** — All code must be sound

### 2.7 Universal Guidelines
- **M-CONCISE-NAMES** — Names free of weasel words (Service, Manager, Factory)
- **M-DOCUMENTED-MAGIC** — Magic values are documented
- **M-LINT-OVERRIDE-EXPECT** — Lint overrides should use `#[expect]` not `#[allow]`
- **M-LOG-STRUCTURED** — Use structured logging with message templates
- **M-PANIC-IS-STOP** — Panic means stop the program
- **M-PANIC-ON-BUG** — Detected programming bugs are panics, not errors
- **M-PUBLIC-DEBUG** — Public types implement Debug
- **M-PUBLIC-DISPLAY** — Public types meant to be read implement Display
- **M-REGULAR-FN** — Prefer regular over associated functions
- **M-SMALLER-CRATES** — If in doubt, split the crate
- **M-STATIC-VERIFICATION** — Use static verification (compiler lints, clippy, rustfmt, cargo-audit, cargo-hack, cargo-udeps, miri)
- **M-UPSTREAM-GUIDELINES** — Follow the upstream Rust API guidelines

### 2.8 Library / Building Guidelines
- **M-FEATURES-ADDITIVE** — Features are additive
- **M-OOBE** — Libraries work out of the box
- **M-SYS-CRATES** — Native `-sys` crates compile without dependencies

### 2.9 Library / Interoperability
- **M-DONT-LEAK-TYPES** — Don't leak external types
- **M-ESCAPE-HATCHES** — Native escape hatches for FFI types
- **M-TYPES-SEND** — Types are Send

### 2.10 Library / Resilience
- **M-AVOID-STATICS** — Avoid statics (secret duplication issues)
- **M-MOCKABLE-SYSCALLS** — I/O and system calls are mockable
- **M-NO-GLOB-REEXPORTS** — Don't glob re-export items
- **M-STRONG-TYPES** — Use the proper type family (PathBuf not String for paths)
- **M-TEST-UTIL** — Test utilities are feature gated

### 2.11 Library / UX
- **M-AVOID-WRAPPERS** — Avoid smart pointers and wrappers in APIs
- **M-DI-HIERARCHY** — Prefer types over generics, generics over dyn traits
- **M-ERRORS-CANONICAL-STRUCTS** — Errors are canonical structs (with Backtrace, cause, helpers)
- **M-ESSENTIAL-FN-INHERENT** — Essential functionality should be inherent
- **M-IMPL-ASREF** — Accept `impl AsRef<>` where feasible
- **M-IMPL-IO** — Accept `impl Read/Write` (sans-io pattern)
- **M-IMPL-RANGEBOUNDS** — Accept `impl RangeBounds<>` where feasible
- **M-INIT-BUILDER** — Complex type construction has builders
- **M-INIT-CASCADED** — Complex type initialization is cascaded
- **M-SERVICES-CLONE** — Services are Clone (`Arc<Inner>` pattern)
- **M-SIMPLE-ABSTRACTIONS** — Abstractions don't visibly nest

---

## 3. Source Material: Rust Ecosystem

### 3.1 Rust API Guidelines (official)
Source: https://rust-lang.github.io/api-guidelines/checklist.html

Organized into: Naming, Interoperability, Macros, Documentation, Predictability, Flexibility, Type Safety, Dependability, Debuggability, Future Proofing, Necessities. Each with specific C-XXX items.

### 3.2 Common Rust Compiler Errors
Source: https://doc.rust-lang.org/error_codes/error-index.html — 500+ error codes (E0001–E0805)

**Most frequently encountered (high-value for a skill):**

| Error | Category | Description |
|-------|----------|-------------|
| E0308 | Type system | Mismatched types |
| E0382 | Ownership | Use of moved value |
| E0502 | Borrowing | Cannot borrow as mutable because also borrowed as immutable |
| E0499 | Borrowing | Cannot borrow as mutable more than once at a time |
| E0505 | Borrowing | Cannot move out of borrowed content |
| E0507 | Ownership | Cannot move out of borrowed content |
| E0106 | Lifetimes | Missing lifetime specifier |
| E0597 | Lifetimes | Value does not live long enough |
| E0277 | Traits | Trait bound not satisfied |
| E0425 | Resolution | Cannot find value/function in this scope |
| E0433 | Resolution | Failed to resolve: use of undeclared crate or module |
| E0432 | Imports | Unresolved import |
| E0599 | Methods | No method named X found for type Y |
| E0004 | Patterns | Non-exhaustive patterns |
| E0515 | Lifetimes | Cannot return reference to local variable |
| E0373 | Closures | Closure may outlive current function, must use `move` |
| E0384 | Mutability | Cannot assign twice to immutable variable |
| E0596 | Mutability | Cannot borrow as mutable |
| E0621 | Lifetimes | Explicit lifetime required |
| E0658 | Features | Feature is not stable |

### 3.3 Clippy Lint Categories
Source: https://github.com/rust-lang/rust-clippy — 800+ lints

| Category | Default Level | Purpose |
|----------|--------------|---------|
| `clippy::correctness` | deny | Outright wrong or useless code |
| `clippy::suspicious` | warn | Most likely wrong or useless |
| `clippy::style` | warn | Non-idiomatic code |
| `clippy::complexity` | warn | Unnecessarily complex |
| `clippy::perf` | warn | Can be written faster |
| `clippy::pedantic` | allow | Strict, occasional false positives |
| `clippy::restriction` | allow | Prevent specific language/library features |
| `clippy::nursery` | allow | Under development |
| `clippy::cargo` | allow | Cargo manifest issues |

### 3.4 Rust Testing Ecosystem
- **Built-in:** `#[test]`, `#[cfg(test)]`, `cargo test`
- **Frameworks:** Built-in test harness, `rstest` (fixtures + parametrized), `proptest` / `quickcheck` (property-based), `criterion` / `divan` (benchmarks)
- **Mocking:** `mockall`, `mockito` (HTTP), `wiremock`
- **Async testing:** `tokio::test`, `async-std::test`
- **Doc tests:** `cargo test` runs examples in doc comments
- **Integration tests:** `tests/` directory convention

### 3.5 Cargo / Build System Topics
- Workspace organization (`Cargo.toml` workspace members)
- Feature flags and conditional compilation
- Build scripts (`build.rs`)
- Dependency management and version resolution
- `rust-toolchain.toml` for pinning toolchain versions
- Cross-compilation and target triples
- Cargo profiles (dev, release, bench, custom)

### 3.6 Idiomatic Rust Resources (from mre/idiomatic-rust)
- Error handling (thiserror, anyhow, eyre)
- Iterator patterns
- Builder pattern
- Newtype pattern
- State machine pattern
- String handling (`&str` vs `String` vs `Cow`)
- Lifetime patterns
- Async/await patterns

---

## 4. Proposed Skills Catalog

Below are candidate skills, grouped by domain. Each maps to a possible `skills/<name>/SKILL.md`.

### Category A: Build & Compilation Errors

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **common-rust-errors** | Knowledge base of common Rust compiler errors (E0xxx) with root causes and fixes. Focus on top-20 most frequent errors. | Rust error index, practical experience |
| **borrow-checker-errors** | Deep-dive into ownership, borrowing, and lifetime errors (E0382, E0499, E0502, E0505, E0507, E0597, E0515). Step-by-step resolution patterns. | Rust reference, error codes |
| **cargo-build-errors** | Cargo-level build failures: dependency resolution, feature conflicts, build script failures, linker errors, missing system libs. | Cargo docs |
| **cargo-dependency-issues** | Resolving dependency conflicts, version mismatches, yanked crates, MSRV issues, `cargo update` vs `cargo upgrade` strategies. | Cargo docs, M-OOBE |

### Category B: Code Quality & Style

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-style-guide** | Idiomatic Rust style: naming conventions (C-CASE, C-CONV, C-GETTER), code organization, module structure, re-exports. | MS Guidelines, Rust API Guidelines |
| **rust-antipatterns** | Common Rust antipatterns: primitive obsession, stringly-typed APIs, unnecessary clones, `.unwrap()` abuse, error swallowing, `Arc<Mutex<>>` overuse. | MS Guidelines (M-CONCISE-NAMES, M-STRONG-TYPES, M-AVOID-WRAPPERS) |
| **clippy-diagnostics** | Guide to understanding and resolving clippy lint warnings. Covers all major categories with examples and fix patterns. | Clippy, M-STATIC-VERIFICATION |
| **rust-documentation-standards** | Writing idiomatic Rust documentation: canonical sections, doc examples, module docs, `#[doc(inline)]`. | M-CANONICAL-DOCS, M-MODULE-DOCS, M-FIRST-DOC-SENTENCE, M-DOC-INLINE |

### Category C: Error Handling

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-error-handling** | Error design patterns: canonical error structs with Backtrace, `thiserror` for libs, `anyhow`/`eyre` for apps, `Result` vs panic, error kind patterns. | M-ERRORS-CANONICAL-STRUCTS, M-APP-ERROR, M-PANIC-IS-STOP, M-PANIC-ON-BUG |

### Category D: API Design & Library Patterns

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-api-design** | API design best practices: `impl AsRef<>`, `impl Read/Write`, `RangeBounds`, builder pattern, cascaded init, `Send`/`Sync`, common trait impls. | M-IMPL-ASREF, M-IMPL-IO, M-INIT-BUILDER, M-TYPES-SEND, C-COMMON-TRAITS, M-ESSENTIAL-FN-INHERENT |
| **rust-crate-structure** | Crate organization: workspace layout, crate splitting, feature flags, additive features, `-sys` crates, re-exports. | M-SMALLER-CRATES, M-FEATURES-ADDITIVE, M-OOBE, M-SYS-CRATES, M-NO-GLOB-REEXPORTS |
| **rust-type-design** | Type design: newtypes, strong types, public Debug/Display, services-clone pattern, avoiding wrappers. | M-STRONG-TYPES, M-PUBLIC-DEBUG, M-PUBLIC-DISPLAY, M-SERVICES-CLONE, M-AVOID-WRAPPERS, M-DI-HIERARCHY |

### Category E: Safety & Unsafe

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-unsafe-guide** | When and how to use `unsafe`: valid reasons, required documentation, soundness, Miri testing, FFI patterns. | M-UNSAFE, M-UNSAFE-IMPLIES-UB, M-UNSOUND, M-ISOLATE-DLL-STATE, M-ESCAPE-HATCHES |

### Category F: Performance

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-performance** | Performance optimization: hot path identification, allocator choice, throughput optimization, yield points, profiling setup, benchmark configuration. | M-HOTPATH, M-THROUGHPUT, M-YIELD-POINTS, M-MIMALLOC-APPS |

### Category G: Testing

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-unit-testing** | Rust unit test generation: `#[test]`, `#[cfg(test)]`, test organization, assertions, test-util features, mocking patterns, async tests, doc tests. | M-TEST-UTIL, M-MOCKABLE-SYSCALLS, Rust test ecosystem |

### Category H: Static Analysis & CI

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-static-analysis** | Static analysis setup and configuration: compiler lints, clippy lints (recommended config from MS guidelines), rustfmt, cargo-audit, cargo-hack, cargo-udeps, Miri. | M-STATIC-VERIFICATION |

### Category I: Structured Logging & Observability

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-structured-logging** | Structured logging with `tracing`: message templates, named events, OTel semantic conventions, sensitive data redaction. | M-LOG-STRUCTURED |

### Category J: Domain Check (shared)

| Skill Name | Description | Source Material |
|-----------|-------------|----------------|
| **rust-domain-check** | Determines if the workspace is a Rust project. Signals: `Cargo.toml`, `*.rs` files, `rust-toolchain.toml`, `target/` directory, Rust error codes (E0xxx). | Analogous to msbuild-skills shared/domain-check |

### Summary: Priority Ranking

| Priority | Skills | Rationale |
|----------|--------|-----------|
| **P0 — Must have** | common-rust-errors, borrow-checker-errors, rust-error-handling, rust-unit-testing, rust-domain-check | Core value: diagnosing the hardest problems (borrow checker) and generating tests |
| **P1 — High value** | rust-style-guide, rust-antipatterns, rust-api-design, cargo-build-errors | Code quality + build troubleshooting |
| **P2 — Nice to have** | clippy-diagnostics, rust-crate-structure, rust-type-design, rust-static-analysis, rust-performance | Deeper expertise areas |
| **P3 — Future** | rust-unsafe-guide, rust-structured-logging, rust-documentation-standards, cargo-dependency-issues | Specialist topics |

---

## 5. Proposed Agents

### 5.1 `rust.agent.md` — Main Rust Expert Agent
**Role:** Top-level triage and routing agent for Rust development.

**Core competencies:**
- Running and configuring Rust builds (`cargo build`, `cargo test`, `cargo clippy`, `cargo run`)
- Analyzing compiler errors and clippy diagnostics
- Understanding Cargo project files (`Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`)
- Resolving borrow checker, lifetime, and type errors
- Optimizing build performance and dependency management

**Routing table:**

| User Intent | Route To |
|-------------|----------|
| Build failed, compiler errors | This agent + `common-rust-errors` / `borrow-checker-errors` |
| Cargo / dependency issues | This agent + `cargo-build-errors` / `cargo-dependency-issues` |
| Error handling design | This agent + `rust-error-handling` |
| Generate unit tests | `rust-test-gen` agent (if created) + `rust-unit-testing` |
| Review code quality | `rust-code-review` agent |
| Performance issues | This agent + `rust-performance` |
| Unsafe code review | This agent + `rust-unsafe-guide` |

### 5.2 `rust-code-review.agent.md` — Rust Code Review Agent
**Role:** Reviews Rust code for style, antipatterns, API design issues, and MS Rust Guidelines compliance.

**Skills used:** rust-style-guide, rust-antipatterns, rust-api-design, rust-type-design, rust-documentation-standards, clippy-diagnostics

### 5.3 `rust-test-gen.agent.md` — Rust Test Generation Agent (optional)
**Role:** Generates comprehensive Rust unit tests following best practices.

**Skills used:** rust-unit-testing

---

## 6. Proposed Test Cases

Test cases should follow the existing pattern: a Cargo project with intentional issues, an `expected-output.md` rubric, and an optional prompt override.

### Category: Build Errors

| Test Case | Skills Tested | Issue | Build Result |
|-----------|--------------|-------|-------------|
| `borrow-errors` | borrow-checker-errors, common-rust-errors | E0382 (moved value), E0502 (immutable+mutable borrow), E0597 (lifetime) | Fails |
| `type-errors` | common-rust-errors | E0308 (type mismatch), E0277 (trait bound not satisfied) | Fails |
| `lifetime-errors` | borrow-checker-errors, common-rust-errors | E0106 (missing lifetime), E0621 (explicit lifetime needed) | Fails |
| `import-resolution` | common-rust-errors, cargo-build-errors | E0432 (unresolved import), E0433 (unresolved module), missing dependency in Cargo.toml | Fails |
| `missing-crate-dep` | cargo-build-errors | Missing `[dependencies]` entries, version conflicts | Fails |

### Category: Code Quality

| Test Case | Skills Tested | Issue | Build Result |
|-----------|--------------|-------|-------------|
| `antipatterns` | rust-antipatterns, rust-style-guide | `.unwrap()` abuse, `String` where `PathBuf` needed, unnecessary clones, stringly-typed API | Builds (with issues) |
| `clippy-warnings` | clippy-diagnostics | Multiple clippy categories triggered (style, complexity, perf) | Builds (with warnings) |
| `bad-api-design` | rust-api-design, rust-type-design | `Arc<Mutex<>>` in public API, missing common traits, no builder pattern for complex init | Builds (but poor API) |
| `poor-error-handling` | rust-error-handling | `unwrap()` everywhere, stringly-typed errors, no `Error` impl, mixed error types | Builds (but fragile) |
| `documentation-gaps` | rust-documentation-standards | Missing doc comments, no module docs, no examples, long first sentences | Builds (but undocumented) |

### Category: Testing

| Test Case | Skills Tested | Issue | Build Result |
|-----------|--------------|-------|-------------|
| `calculator-rust` | rust-unit-testing | Simple library with math functions — generate tests | Builds |
| `service-with-deps` | rust-unit-testing | Service with dependencies requiring mocking — generate tests | Builds |
| `async-service` | rust-unit-testing | Async service with tokio — generate async tests | Builds |

### Category: Crate Organization

| Test Case | Skills Tested | Issue | Build Result |
|-----------|--------------|-------|-------------|
| `monolith-crate` | rust-crate-structure | Single crate that should be split, non-additive features, glob re-exports | Builds |
| `feature-conflicts` | rust-crate-structure, cargo-build-errors | Mutually exclusive features, missing feature combinations | Builds only with specific features |

### Category: Domain Check

| Test Case | Skills Tested | Issue |
|-----------|--------------|-------|
| `mixed-languages` | rust-domain-check | Directory with both Rust and non-Rust projects |

---

## 7. Evaluation Pipeline — Rust Toolchain Requirements

### 7.1 Required Tools in CI Environment

The evaluation pipeline currently runs in Docker (Ubuntu) and executes `dotnet build` for MSBuild scenarios. For Rust scenarios, the following must be available:

| Tool | Purpose | Installation |
|------|---------|-------------|
| **rustup** | Rust toolchain manager | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh -s -- -y` |
| **rustc** (stable) | Rust compiler | Installed via `rustup` |
| **cargo** | Build system & package manager | Installed via `rustup` |
| **clippy** | Linting | `rustup component add clippy` |
| **rustfmt** | Formatting | `rustup component add rustfmt` |
| **cargo-audit** (optional) | Security vulnerability detection | `cargo install cargo-audit` |
| **cargo-hack** (optional) | Feature combination testing | `cargo install cargo-hack` |

### 7.2 Docker Image Changes

The existing Docker setup script (in `eng/evaluation/README.md`) installs pwsh, dotnet, and copilot. It needs to be extended:

```bash
# Inside Docker container setup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustup component add clippy rustfmt
```

### 7.3 `rust-toolchain.toml` for Test Cases

Each Rust test case should include a `rust-toolchain.toml` to pin the toolchain:

```toml
[toolchain]
channel = "stable"
components = ["clippy", "rustfmt"]
```

This ensures reproducible builds regardless of what's installed in the CI environment.

### 7.4 Build Commands for Eval Scenarios

The evaluation scripts currently assume `dotnet build`. For Rust scenarios, the equivalent commands are:

| DotNet Equivalent | Rust Command | Purpose |
|-------------------|-------------|---------|
| `dotnet build` | `cargo build 2>&1` | Compile and show errors |
| `dotnet test` | `cargo test 2>&1` | Run tests |
| N/A | `cargo clippy --all-targets -- -D warnings 2>&1` | Lint analysis |
| N/A | `cargo fmt --check 2>&1` | Format check |

### 7.5 Eval Script Adaptation

The `run-scenario.ps1` may need to be adapted to detect the project type (Rust vs .NET) and use the correct build command. Possible approaches:
- **Per-testcase signal:** Presence of `Cargo.toml` in testcase root = Rust project
- **Prompt-override approach:** Each Rust testcase provides `eval-test-prompt.txt` that includes "Run `cargo build` and analyze..."
- **Generic approach:** The eval prompt is broad enough ("Analyze the build issues...") that the AI should figure out the build system

### 7.6 Platform Considerations

- Rust toolchain works on Linux, macOS, and Windows (all Tier 1)
- Cargo downloads and compiles dependencies on first build (internet access needed in CI, or use `cargo vendor`)
- Compilation can be slow for first build; use `cargo check` for faster type-checking-only scenarios
- Consider caching `~/.cargo/registry` and `target/` between runs for performance

### 7.7 Minimal vs Full Pipeline

| Level | Tools | Use Case |
|-------|-------|----------|
| **Minimal** | rustup + stable toolchain + clippy | Sufficient for 90% of scenarios |
| **Extended** | + rustfmt + cargo-audit + cargo-hack | Full static analysis scenarios |
| **Full** | + miri + cargo-udeps + nightly toolchain | Safety and advanced analysis scenarios |

Recommendation: Start with **Minimal** tier and add tools as specific test cases require them.

---

## 8. Open Questions (with Suggested Approaches)

### Skills Design

1. **Granularity:** Should borrow-checker errors be a separate skill or part of `common-rust-errors`?
   > **Suggestion: Keep them separate.** Borrow checker errors are Rust's single biggest pain point for developers and the area where AI struggles most. A dedicated, deep skill gives better routing precision and lets the agent load heavyweight context only when needed. `common-rust-errors` then stays focused on the more "normal" compiler errors (type mismatches, unresolved imports, etc.) and doesn't balloon to an unmanageable size.

2. **Microsoft Guidelines as skills vs references:** Should we create one mega-skill from all MS Rust Guidelines or decompose into per-topic skills?
   > **Suggestion: Decompose into per-topic skills (as proposed).** A single mega-skill would be too large to include in context for every query, and most of the content would be irrelevant to any given question. Per-topic skills let the agent selectively load only what's needed. The MS Guidelines content should be absorbed and rewritten — not copy-pasted — since the original prose is structured as a specification, not as AI-assisting reference material.

3. **Overlap with polyglot-unittest-skills:** The existing polyglot plugin already generates tests for any language. Should `rust-unit-testing` be in rust-skills or extend polyglot?
   > **Suggestion: Own skill inside rust-skills.** Rust testing has unique idioms that a polyglot skill can't cover deeply: `#[cfg(test)]` module conventions, doc tests that double as examples, the `tests/` integration test directory pattern, `#[should_panic]`, `rstest` fixtures, `mockall` for trait mocking, `tokio::test` for async, and the `test-util` feature-gate pattern from the MS guidelines. A Rust-specific skill will measurably outperform the generic one. The polyglot skill remains useful as a fallback.

4. **Shared skills:** Some skills (domain-check, error-handling patterns) could be shared across plugins. Worth creating a shared references mechanism?
   > **Suggestion: No, keep skills self-contained per plugin.** Each plugin is independently versioned and deployed. Sharing across plugins creates coupling and versioning headaches. If two plugins need similar domain-check logic, each gets its own copy (they're small files). This matches the existing pattern — `msbuild-skills` has its own `shared/domain-check.md`.

### Test Cases

5. **Complexity level:** How complex should test case Cargo projects be?
   > **Suggestion: Mix of complexities, but lean simple.** Start with single-file `main.rs` / `lib.rs` projects for build-error scenarios (easy to author, fast to compile, clear signal). Use multi-module `lib.rs` + `mod` structure for code-quality scenarios (antipatterns need enough code for patterns to emerge). Save workspace-with-multiple-crates complexity for one or two crate-structure scenarios. Simpler projects = faster eval runs and clearer rubric grading.

6. **Dependency management:** Should test cases vendor their dependencies or rely on `crates.io` access during eval?
   > **Suggestion: Minimize external dependencies entirely.** Design test cases using only `std` where possible. For the few scenarios that need external crates (e.g., `serde`, `tokio` for async tests), accept the `crates.io` download — it's the realistic user experience. Do NOT vendor dependencies; it bloats the repo massively. If offline CI becomes a requirement later, cargo registry caching is the right solution, not per-testcase vendoring.

7. **Clippy vs compiler errors:** Should test cases that trigger clippy warnings be separate from those with compiler errors?
   > **Suggestion: Yes, keep them separate.** Compiler errors and clippy warnings are different workflows: one is "my code doesn't build" and the other is "my code builds but has quality issues." Separate test cases let us measure skill impact on each independently and keep rubrics clean. A compiler-error testcase shouldn't be muddied by also checking whether the AI suggests clippy improvements.

### Pipeline

8. **Custom build detection:** Does the eval pipeline need explicit Rust support or can we rely on prompt engineering?
   > **Suggestion: Add proper Rust support to the eval environment and pipeline.** The eval environment should have Rust ready to go — just like a real developer environment where these skills will actually be used. This means: (a) install `rustup` + stable + clippy in the Docker image alongside dotnet, and (b) add simple `Cargo.toml` detection in `run-scenario.ps1` to use `cargo build` instead of `dotnet build`. This is straightforward — a `Test-Path Cargo.toml` check — and avoids every Rust testcase needing a boilerplate `eval-test-prompt.txt` that hand-holds the AI into running cargo. The environment should just work.

9. **Parallel execution:** Rust builds can be CPU-heavy. Any concern about resource limits in CI for parallel scenarios?
   > **Suggestion: Not a concern for our use case.** The test projects are tiny (single-file or small multi-file). Compilation of `std`-only code takes under 2 seconds. Even scenarios with one or two external deps will compile in under 30 seconds. The real bottleneck is the Copilot LLM call, not the build. If we ever hit resource issues, `cargo check` (type-checking only, no codegen) is ~2x faster than `cargo build`.

10. **Toolchain caching:** Should we pre-build common dependencies or use a cargo registry mirror?
    > **Suggestion: Cache `~/.cargo/registry` in the Docker image, nothing more.** Pre-building deps is fragile (tied to exact Cargo.lock). A registry mirror is overkill for a handful of small test cases. Simply ensuring the Docker image has a warm cargo registry index (run `cargo search serde` once during image build) cuts first-build time. The `rust-toolchain.toml` in each testcase handles toolchain version pinning.

### Scope

11. **Phase 1 scope:** What's the minimum viable set of skills + test cases for an initial PR?
    > **Suggestion: 4 skills + 4 test cases + 1 agent.**
    > - Skills: `common-rust-errors`, `borrow-checker-errors`, `rust-error-handling`, `rust-domain-check`
    > - Test cases: `borrow-errors`, `type-errors`, `import-resolution`, `poor-error-handling`
    > - Agent: `rust.agent.md` (main triage/routing)
    > - Infrastructure: `plugin.json`, `README.md`, Docker image update for rustup
    >
    > This gives us the end-to-end pipeline working for Rust, covers the highest-value problem domain (compiler errors / borrow checker), and is small enough to ship and iterate on.

12. **Edition handling:** Should skills cover Rust edition differences (2015, 2018, 2021, 2024)?
    > **Suggestion: Target edition 2021 as the baseline, mention 2024 where relevant, ignore older editions.** Edition 2021 is the current default for `cargo init` and the vast majority of active projects. Edition 2024 introduced some changes (lifetime capture rules, `gen` keyword reservation). Editions 2015 and 2018 are legacy — if someone is on those editions, the advice is "upgrade your edition" and Rust has `cargo fix --edition` for that. Skills shouldn't try to be a comprehensive edition migration guide.

13. **Async Rust:** Async patterns (tokio, async-std) are a major pain point. Worth a dedicated skill?
    > **Suggestion: Not in Phase 1, but yes eventually as a P2 skill.** Async Rust errors (`Future is not Send`, `async fn in trait`, lifetime issues in futures) are genuinely confusing and a prime area for AI assistance. However, async scenarios require tokio/async-std as dependencies, making test cases heavier. Better to nail the fundamentals (sync borrow checker, error handling) first, then add an `async-rust-patterns` skill in Phase 2 that covers `Send`/`Sync` bounds on futures, `tokio::test`, pin/unpin, and cancellation safety.

---

## 9. V2 Roadmap — Additional Skills & Ideas

Phase 1 (Section 8, Q11) establishes the foundation: compiler error diagnosis, borrow checker help, error handling, and the eval pipeline. V2 builds on that foundation with deeper and broader coverage.

### V2 Skills

| Skill | Priority | Description | Why V2, not V1 |
|-------|----------|-------------|-----------------|
| **async-rust-patterns** | P2 | Async/await pitfalls: `Future is not Send`, lifetime issues in futures, `pin`/`Unpin`, cancellation safety, `tokio::test`, `async fn in trait` (RPITIT). | Requires tokio dependency in test cases; async errors are confusing but less common than sync borrow-checker issues |
| **rust-unit-testing** | P1 | Full test generation skill: `#[test]`, `#[cfg(test)]` conventions, `rstest` fixtures, `proptest` property-based testing, `mockall` trait mocking, doc tests, integration tests in `tests/`, `test-util` feature-gate pattern. | Needs more test case variety (simple lib, service with deps, async service) |
| **rust-style-guide** | P1 | Idiomatic style: naming conventions, module organization, re-exports, `use` ordering, `impl` block structure, `match` vs `if let` choices. | Significant content to write; less urgency than "my code doesn't compile" |
| **rust-antipatterns** | P1 | Common antipatterns with fixes: `.unwrap()` abuse, unnecessary `.clone()`, `String` where `&str` or `PathBuf` needed, stringly-typed APIs, `Arc<Mutex<>>` overuse, `Box<dyn Error>` as the only error type. | Code quality, not compilation-blocking |
| **rust-api-design** | P2 | API design: `impl AsRef<>`, `impl Read/Write`, builder pattern, cascaded init, `Send`/`Sync`, common trait impls, sans-io pattern. | Library-authoring audience (narrower than general Rust dev) |
| **clippy-diagnostics** | P2 | Understanding and fixing clippy warnings across all categories. Recommended project-wide clippy config. | Useful but clippy messages are already quite good on their own |
| **cargo-build-errors** | P1 | Cargo-level failures: dependency resolution, feature conflicts, build script (`build.rs`) errors, linker errors, missing system libraries, MSRV issues. | Complements compiler-error skills with build-system-level diagnosis |
| **rust-crate-structure** | P2 | Workspace layout, crate splitting, feature flags, additive features, `-sys` crate patterns, conditional compilation. | Architecture-level guidance; slower-changing |
| **rust-type-design** | P2 | Newtypes, strong types, public Debug/Display, Services-Clone pattern, avoiding wrappers in APIs. | Design-level, not debugging-level |
| **rust-unsafe-guide** | P3 | When/how to use `unsafe`: valid reasons, soundness, safety documentation, Miri testing, FFI patterns. | Niche audience within Rust |
| **rust-static-analysis** | P2 | Setting up full static analysis: compiler lints, clippy config, rustfmt, cargo-audit, cargo-hack, cargo-udeps, Miri. | Project setup guidance, one-time activity |
| **rust-documentation-standards** | P3 | Writing idiomatic docs: canonical sections, doc examples, module docs, `#[doc(inline)]`. | Important but rarely the reason someone invokes AI help |
| **rust-structured-logging** | P3 | Structured logging with `tracing`: message templates, named events, OTel conventions, redaction. | Narrow topic |
| **rust-performance** | P2 | Hot path profiling, allocator choices (mimalloc), throughput optimization, yield points, benchmark setup with criterion/divan. | Performance tuning is specialized |
| **cargo-dependency-issues** | P2 | Version conflicts, yanked crates, MSRV mismatch, `cargo update` vs `cargo upgrade`, audit failures. | Overlaps somewhat with cargo-build-errors |

### V2 Agents

| Agent | Description |
|-------|-------------|
| **rust-code-review.agent.md** | Reviews Rust code for style, antipatterns, API design, and documentation quality. Routes to: rust-style-guide, rust-antipatterns, rust-api-design, rust-type-design, clippy-diagnostics, rust-documentation-standards. |
| **rust-test-gen.agent.md** | Generates comprehensive Rust unit tests. Routes to: rust-unit-testing. Analogous to the dotnet-unittest-skills agent. |

### V2 Test Cases

| Test Case | Skills Tested | Description |
|-----------|--------------|-------------|
| `calculator-rust` | rust-unit-testing | Simple math library — generate tests (mirrors dotnet calculator-xunit) |
| `service-with-deps` | rust-unit-testing | Service with trait-based deps — generate tests using mockall |
| `async-service` | rust-unit-testing, async-rust-patterns | Async service with tokio — generate async tests |
| `antipatterns` | rust-antipatterns, rust-style-guide | Code that builds but has many antipatterns — review and suggest improvements |
| `clippy-warnings` | clippy-diagnostics | Code triggering multiple clippy categories |
| `bad-api-design` | rust-api-design, rust-type-design | Public API with wrapper exposure, missing traits, no builder pattern |
| `monolith-crate` | rust-crate-structure | Single oversized crate that should be split |
| `feature-conflicts` | rust-crate-structure, cargo-build-errors | Non-additive feature flags causing build failures |
| `async-pitfalls` | async-rust-patterns | Futures that aren't Send, lifetime issues in async, missing yield points |
| `unsafe-review` | rust-unsafe-guide | Code with unnecessary or unsound unsafe blocks |

### V2 Ideas Beyond Skills

1. **Agentic workflows (like msbuild-skills has):**
   - `rust-pr-review.md` — automated PR review workflow that runs clippy, checks style, reviews error handling, and API design in one pass
   - `rust-project-audit.md` — full project health check: dependencies, MSRV, clippy config, test coverage, documentation gaps
   - `cargo-migration.md` — guide edition upgrades, dependency major-version migrations

2. **Prompt templates:**
   - `fix-borrow-error.prompt.md` — "I have a borrow checker error, help me fix it" with structured context gathering
   - `modernize-rust.prompt.md` — upgrade Rust edition, replace deprecated patterns, adopt current idioms
   - `optimize-build.prompt.md` — speed up `cargo build` times (workspace structure, feature pruning, incremental compilation tips)

3. **Copilot extension (like msbuild-skills has):**
   - `@rust` Copilot Chat extension that routes queries to the Rust agent
   - Could integrate `cargo build` / `cargo clippy` output parsing directly

4. **Cross-language skills:**
   - `rust-ffi-c-interop` — helping with C/Rust FFI boundary (bindgen, cbindgen, safety wrappers)
   - `rust-wasm` — Rust to WebAssembly compilation issues (wasm-pack, wasm-bindgen)

5. **Eval dashboard enhancements:**
   - Side-by-side comparison of vanilla vs skilled responses for Rust scenarios on the existing dashboard
   - Rust-specific metrics: "did the AI suggest the correct lifetime annotation?" / "did it fix the borrow correctly?"

6. **Skill composition patterns:**
   - Skills that reference other skills (e.g., `rust-api-design` referencing `rust-type-design` for newtypes, or `common-rust-errors` suggesting the user also look at `borrow-checker-errors` for ownership issues)
   - Shared reference snippets (e.g., a `references/cargo-toml-basics.md` that multiple skills can point to)

---

## Appendix A: Microsoft Rust Guidelines — Complete Guideline IDs

For reference, all guideline IDs found in the Microsoft Rust Guidelines document:

**AI:** M-DESIGN-FOR-AI

**Application:** M-APP-ERROR, M-MIMALLOC-APPS

**Documentation:** M-CANONICAL-DOCS, M-DOC-INLINE, M-FIRST-DOC-SENTENCE, M-MODULE-DOCS

**FFI:** M-ISOLATE-DLL-STATE

**Performance:** M-HOTPATH, M-THROUGHPUT, M-YIELD-POINTS

**Safety:** M-UNSAFE-IMPLIES-UB, M-UNSAFE, M-UNSOUND

**Universal:** M-CONCISE-NAMES, M-DOCUMENTED-MAGIC, M-LINT-OVERRIDE-EXPECT, M-LOG-STRUCTURED, M-PANIC-IS-STOP, M-PANIC-ON-BUG, M-PUBLIC-DEBUG, M-PUBLIC-DISPLAY, M-REGULAR-FN, M-SMALLER-CRATES, M-STATIC-VERIFICATION, M-UPSTREAM-GUIDELINES

**Library / Building:** M-FEATURES-ADDITIVE, M-OOBE, M-SYS-CRATES

**Library / Interoperability:** M-DONT-LEAK-TYPES, M-ESCAPE-HATCHES, M-TYPES-SEND

**Library / Resilience:** M-AVOID-STATICS, M-MOCKABLE-SYSCALLS, M-NO-GLOB-REEXPORTS, M-STRONG-TYPES, M-TEST-UTIL

**Library / UX:** M-AVOID-WRAPPERS, M-DI-HIERARCHY, M-ERRORS-CANONICAL-STRUCTS, M-ESSENTIAL-FN-INHERENT, M-IMPL-ASREF, M-IMPL-IO, M-IMPL-RANGEBOUNDS, M-INIT-BUILDER, M-INIT-CASCADED, M-SERVICES-CLONE, M-SIMPLE-ABSTRACTIONS

---

## Appendix B: Rust API Guidelines — Checklist Items

**Naming:** C-CASE, C-CONV, C-GETTER, C-ITER, C-ITER-TY, C-FEATURE, C-WORD-ORDER

**Interoperability:** C-COMMON-TRAITS, C-CONV-TRAITS, C-COLLECT, C-SERDE, C-SEND-SYNC, C-GOOD-ERR, C-NUM-FMT, C-RW-VALUE

**Macros:** C-EVOCATIVE, C-MACRO-ATTR, C-ANYWHERE, C-MACRO-VIS, C-MACRO-TY

**Documentation:** C-CRATE-DOC, C-EXAMPLE, C-QUESTION-MARK, C-FAILURE, C-LINK, C-METADATA, C-RELNOTES, C-HIDDEN

**Predictability:** C-SMART-PTR, C-CONV-SPECIFIC, C-METHOD, C-NO-OUT, C-OVERLOAD, C-DEREF, C-CTOR

**Flexibility:** C-INTERMEDIATE, C-CALLER-CONTROL, C-GENERIC, C-OBJECT

**Type Safety:** C-NEWTYPE, C-CUSTOM-TYPE, C-BITFLAG, C-BUILDER

**Dependability:** C-VALIDATE, C-DTOR-FAIL, C-DTOR-BLOCK

**Debuggability:** C-DEBUG, C-DEBUG-NONEMPTY

**Future Proofing:** C-SEALED, C-STRUCT-PRIVATE, C-NEWTYPE-HIDE, C-STRUCT-BOUNDS

**Necessities:** C-STABLE, C-PERMISSIVE

---

## Appendix C: Key Crates for Skill References

| Category | Crates | Notes |
|----------|--------|-------|
| Error handling | `thiserror`, `anyhow`, `eyre` | thiserror for libs, anyhow/eyre for apps |
| Serialization | `serde`, `serde_json`, `serde_yaml` | Ubiquitous |
| Async runtime | `tokio`, `async-std`, `smol` | tokio is dominant |
| HTTP | `reqwest`, `hyper`, `axum`, `actix-web` | Common web stack |
| Testing | `rstest`, `proptest`, `quickcheck`, `mockall`, `wiremock`, `criterion`, `divan` | Test ecosystem |
| Logging | `tracing`, `log`, `env_logger` | tracing recommended by MS guidelines |
| CLI | `clap`, `argh` | CLI argument parsing |
| Allocator | `mimalloc` | Recommended by M-MIMALLOC-APPS |
| Build tools | `cc`, `bindgen`, `libloading` | For `-sys` crates |
| Linting | `clippy` (component), `cargo-audit`, `cargo-hack`, `cargo-udeps` | Static analysis |
| Safety | `miri` (component) | Unsafe code validation |
