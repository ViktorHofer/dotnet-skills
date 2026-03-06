---
name: common-rust-errors
description: "Knowledge base of common Rust compiler errors (E0xxx) with root causes and solutions. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when encountering E0xxx error codes during cargo build, cargo check, or cargo test. Covers type errors (E0308), import/resolution errors (E0425, E0432, E0433), pattern errors (E0004), mutability errors (E0384, E0596), trait errors (E0277, E0599), and feature gate errors (E0658). For ownership/borrowing/lifetime errors (E0382, E0499, E0502, E0505, E0507, E0106, E0597, E0515, E0621, E0373), defer to the borrow-checker-errors skill which provides deeper analysis. DO NOT use for non-Rust build errors (.NET, npm, Gradle, CMake, etc.)."
---

# Common Rust Compiler Errors

This skill covers the most frequently encountered Rust compiler errors outside
the borrow checker family. Each entry provides the error code, explanation,
common causes, a step-by-step fix, and prevention guidance.

---

## Type Errors

### E0308: Mismatched types

**What it means:** The compiler expected one type but found a different one. This
is the most common Rust error — it fires whenever a value's type doesn't match
what the surrounding context requires.

**Common root causes:**
- Function argument type doesn't match the parameter type in the signature
- Return value type doesn't match the declared return type
- Variable assignment with incompatible type
- Integer type mismatch (e.g., `u32` vs `i32`, or `usize` vs `u64`)
- Missing `.as_str()`, `.to_string()`, or other conversion method
- `if` / `match` arms returning different types
- Forgetting `&` or `*` for reference/dereference

**Step-by-step fix:**
1. Read the full error message — Rust shows "expected `X`, found `Y`" with exact types.
2. Check if a simple conversion exists: `.into()`, `.as_ref()`, `.to_string()`,
   `as u32`, etc.
3. For `&str` vs `String`: use `.to_string()` to go from `&str` → `String`,
   or `&s` / `.as_str()` to go from `String` → `&str`.
4. For integer types: use `as` cast (e.g., `x as u64`) or `.try_into().unwrap()`
   for fallible conversion.
5. For `if`/`match` arms: ensure all arms return the same concrete type; use
   `Box<dyn Trait>` or an enum if they're genuinely different types.
6. For option/result mismatches: use `.unwrap()`, `?`, `.ok()`, `.map()` as appropriate.

**Prevention:**
- Let the compiler infer types where possible; add explicit annotations when
  inference fails.
- Use `clippy::cast_possible_truncation` to catch lossy integer casts.

---

### E0277: Trait bound not satisfied

**What it means:** A type was used in a context that requires it to implement a
specific trait, but the type does not implement that trait.

**Common root causes:**
- Passing a type to a generic function with a trait bound it doesn't satisfy
  (e.g., passing a struct to a function requiring `Display` when the struct
  doesn't implement `Display`)
- Using a type in a collection or API that requires `Clone`, `Debug`, `Hash`,
  `Eq`, `Send`, `Sync`, `Serialize`, etc.
- Missing `#[derive(...)]` on a struct or enum
- Implementing a trait for the wrong type or with wrong generic parameters
- Trying to use `?` in a function whose error type doesn't implement `From<E>`

**Step-by-step fix:**
1. Read the error — it says "the trait `X` is not implemented for `Y`".
2. If it's a standard trait (`Debug`, `Clone`, `PartialEq`, etc.), add
   `#[derive(Debug, Clone, PartialEq)]` to your type definition.
3. If it's a third-party trait (`Serialize`, `Deserialize`), add the derive
   attribute and ensure the crate is in `[dependencies]` with the `derive` feature.
4. If it's a custom trait, implement it manually with `impl MyTrait for MyType`.
5. If the error is about `From<E>` for the `?` operator, add a `From` impl or
   use `.map_err(...)` to convert.

**Prevention:**
- Derive common traits proactively: `#[derive(Debug, Clone, PartialEq, Eq, Hash)]`.
- Check trait bounds in function signatures before calling them.

---

## Method Resolution Errors

### E0599: No method named X found for type Y

**What it means:** You called a method on a type that doesn't have that method.
The compiler cannot find the method in the type's inherent `impl` blocks or in
any trait implementations that are in scope.

**Common root causes:**
- Typo in the method name
- Method exists on a different type (e.g., calling `.len()` on an iterator
  instead of a collection)
- Method is defined in a trait that isn't imported (`use` statement missing)
- Method exists but is private (not `pub`)
- Calling a method on a reference when it's defined on the owned type, or vice versa
- The type is generic and the method requires a trait bound that isn't specified

**Step-by-step fix:**
1. Check spelling of the method name.
2. Verify the receiver type — the error message shows the exact type. Is it
   `&str`, `String`, `&[T]`, `Vec<T>`, etc.?
3. If the method is from a trait, add `use TraitName;` to bring it into scope.
   Common examples: `use std::io::Write;`, `use std::fmt::Display;`.
4. If the method is private, check if there's a public alternative or if you
   need to change visibility.
5. For generic types, add the required trait bound to the generic parameter.

**Prevention:**
- Use IDE autocompletion to discover available methods.
- Import traits at the top of the file when using their methods.

---

## Name Resolution Errors

### E0425: Cannot find value or function in this scope

**What it means:** The compiler cannot find a variable, function, or constant
with the given name in the current scope.

**Common root causes:**
- Typo in the variable or function name
- Variable defined in a different scope (e.g., inside an `if` block, used outside)
- Function defined in a different module and not imported
- Using a function before it's defined (Rust allows this within a module, but
  not across modules without `use`)
- Forgetting `self.` for struct methods

**Step-by-step fix:**
1. Check spelling — Rust is case-sensitive.
2. Check scope — was the variable defined in an inner block (`{ ... }`) that
   has ended?
3. For functions in other modules: add `use crate::module::function_name;` or
   call with full path `module::function_name()`.
4. For struct fields/methods: use `self.field` or `Self::method()`.
5. For constants: ensure they're `pub` if accessed from another module.

**Prevention:**
- Use consistent naming conventions (snake_case for functions/variables,
  CamelCase for types).
- Keep functions in logically organized modules with clear `pub` visibility.

---

### E0432: Unresolved import

**What it means:** A `use` statement references a path that doesn't exist. The
module, crate, or item at that path cannot be found.

**Common root causes:**
- Missing crate in `[dependencies]` in `Cargo.toml`
- Typo in the module/item path
- The item is private (not `pub`) in the source module
- Wrong path — e.g., `use crate::foo` when the module is `crate::bar::foo`
- Using `use super::...` incorrectly in nested modules
- Crate name uses hyphens in `Cargo.toml` but underscores in Rust code
  (e.g., `serde-json` in TOML → `serde_json` in Rust)

**Step-by-step fix:**
1. If the import is from an external crate, check `Cargo.toml` — is the crate
   listed in `[dependencies]`?
2. If the crate name has hyphens, replace with underscores in the `use` statement.
3. Check the item's visibility — is it `pub`?
4. Verify the full path: use `cargo doc --open` to browse module structure.
5. For `use crate::...` paths, trace from the crate root (`lib.rs` or `main.rs`).

**Prevention:**
- Run `cargo check` frequently during development to catch import errors early.
- Use `cargo add <crate>` to add dependencies (auto-updates `Cargo.toml`).

---

### E0433: Failed to resolve: use of undeclared crate or module

**What it means:** A path in an expression (not just a `use` statement) references
a crate or module that doesn't exist. This is similar to E0432 but occurs in
expression context rather than import context.

**Common root causes:**
- Using a crate in code (e.g., `serde_json::to_string(...)`) without adding it
  to `Cargo.toml`
- Referencing a module that hasn't been declared with `mod module_name;`
- Using fully-qualified paths with typos
- Forgetting to declare a module in `lib.rs` or `main.rs`

**Step-by-step fix:**
1. If it's an external crate: add to `[dependencies]` in `Cargo.toml`.
2. If it's a local module: add `mod module_name;` in the parent module file.
3. Check for typos in the crate/module name.
4. Verify the module file exists at the expected path (`src/module_name.rs` or
   `src/module_name/mod.rs`).

**Prevention:**
- Declare all modules at the crate root.
- Keep a clean module hierarchy — use `cargo doc` to visualize.

---

## Pattern Matching Errors

### E0004: Non-exhaustive patterns

**What it means:** A `match` expression doesn't cover all possible values of the
matched type. Rust requires that every possible value is handled.

**Common root causes:**
- Matching on an enum without covering all variants
- Matching on an integer type without a wildcard (`_`) arm
- Matching on a `bool` with only one arm
- Adding a new variant to an enum without updating all `match` expressions
- Matching on a `#[non_exhaustive]` type from another crate without a wildcard

**Step-by-step fix:**
1. Add the missing patterns. The error message lists which patterns are not covered.
2. For types with many values (integers, strings): add a wildcard arm `_ => ...`.
3. For enums: add the missing variants, or add `_ => ...` as a catch-all.
4. For `#[non_exhaustive]` types: always include a `_ =>` arm since new variants
   may be added in future versions.

**Prevention:**
- Always include a `_ => ...` wildcard when matching on types you don't control.
- Use `#[deny(non_exhaustive_omitted_patterns)]` on matches of your own enums
  to get notified when new variants are added.

---

## Mutability Errors

### E0384: Cannot assign twice to immutable variable

**What it means:** A variable that was not declared as `mut` is being assigned a
new value. In Rust, variables are immutable by default.

**Common root causes:**
- Forgetting to add `mut` when declaring a variable that will be reassigned
- Reassigning a loop variable that should be shadowed instead
- Trying to modify a function parameter (parameters are immutable by default)

**Step-by-step fix:**
1. If the variable needs to be reassigned: add `mut` to the declaration:
   `let mut x = 5;`
2. If you want a new value with the same name: use shadowing:
   `let x = x + 1;` (no `mut` needed, this creates a new binding)
3. For function parameters: add `mut` to the parameter: `fn foo(mut x: i32)`.

**Prevention:**
- Default to immutable variables. Only add `mut` when genuinely needed.
- Prefer shadowing over mutation when the variable's purpose changes.

---

### E0596: Cannot borrow as mutable

**What it means:** You're trying to get a mutable reference (`&mut`) to something
that isn't declared mutable, or you're trying to mutably borrow through an
immutable reference.

**Common root causes:**
- Variable not declared `mut` but you're calling a `&mut self` method on it
- Iterating with `for item in &collection` and trying to modify `item`
  (need `for item in &mut collection`)
- Trying to mutably borrow a field through an immutable reference
- Using `.iter()` instead of `.iter_mut()` when modification is needed

**Step-by-step fix:**
1. Declare the variable as mutable: `let mut x = ...`.
2. For iteration: use `&mut collection` or `.iter_mut()`.
3. For struct fields: ensure the struct instance is `mut`.
4. Check the entire chain — you need mutability at every level from the
   root variable to the field being modified.

**Prevention:**
- When designing APIs, check if methods need `&self` or `&mut self`.
- Use `iter_mut()` when you know you'll modify elements during iteration.

---

## Feature Gate Errors

### E0658: Use of unstable feature

**What it means:** You're using a Rust feature that is only available on the
nightly compiler, or that requires an explicit feature gate.

**Common root causes:**
- Using syntax or APIs that are still in nightly (e.g., `#![feature(generators)]`)
- Using a recently stabilized feature with a toolchain that predates stabilization
- Copying code from nightly Rust documentation or blog posts
- Using `#![feature(...)]` in a project that targets stable Rust

**Step-by-step fix:**
1. Check if the feature has been stabilized — search the Rust release notes.
2. If stabilized: update your Rust toolchain (`rustup update stable`).
3. If not stabilized: find a stable alternative. Most nightly features have
   stable workarounds or crate-based alternatives.
4. If you must use nightly: add `#![feature(feature_name)]` to your crate root
   and switch to nightly (`rustup default nightly`).

**Prevention:**
- Pin your toolchain in `rust-toolchain.toml` to avoid accidental nightly usage.
- Check the [Rust Unstable Book](https://doc.rust-lang.org/unstable-book/) for
  feature status before using nightly APIs.

---

## Cross-Reference

For ownership, borrowing, and lifetime errors (E0382, E0499, E0502, E0505,
E0507, E0106, E0597, E0515, E0621, E0373), see the **`borrow-checker-errors`** skill.
These errors involve Rust's ownership system and require different analysis
strategies than the type/resolution/pattern errors covered here.

## Getting More Help

For any Rust compiler error code, run:

```bash
rustc --explain E0xxx
```

This prints the official explanation with examples directly in your terminal.
You can also browse all error codes at https://doc.rust-lang.org/error_codes/.
