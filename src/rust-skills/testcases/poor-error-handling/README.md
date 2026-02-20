# Poor Error Handling Test Case

A Rust application that compiles successfully but uses anti-pattern error handling:
`.unwrap()` calls, stringly-typed errors, `Box<dyn Error>`, and no-op `.map_err`.

## How to Test
```bash
cargo build
```

## Expected: Build succeeds (this is a code quality test case, not a build failure)
