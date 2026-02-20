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
