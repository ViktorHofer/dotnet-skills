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
