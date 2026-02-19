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
