# Borrow Errors Test Case

A minimal Rust project that fails to compile due to three classic borrow checker errors:
E0382 (moved value), E0502 (conflicting borrows), E0597 (dangling reference).

## How to Test
```bash
cargo build
```

## Expected: Build fails with 3 errors
