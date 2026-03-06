---
name: borrow-checker-errors
description: "Deep-dive guide to Rust ownership, borrowing, and lifetime errors. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when encountering borrow checker errors: E0382 (use of moved value), E0499 (multiple mutable borrows), E0502 (conflicting borrows), E0505 (move out of borrow), E0507 (move out of borrowed content), E0106 (missing lifetime), E0597 (value does not live long enough), E0515 (cannot return reference to local), E0621 (explicit lifetime required), E0373 (closure outlives function). Provides ownership mental model, resolution patterns, and refactoring strategies. DO NOT use for non-Rust errors."
---

# Rust Borrow Checker Errors

The borrow checker is Rust's core safety mechanism. It enforces three rules:
1. Each value has exactly one owner at a time
2. You can have either ONE mutable reference OR any number of immutable references (not both)
3. References must not outlive the data they point to

When these rules are violated, the compiler produces errors in the E0382–E0621 range.
This skill covers every major borrow checker error with concrete fix patterns.

---

## Mental Model: Ownership Flow

Before diving into specific errors, understand how Rust tracks ownership:

- **Move:** Assigning a non-Copy value transfers ownership. The original binding
  becomes invalid. Types like `String`, `Vec<T>`, `Box<T>`, and `HashMap` are moved.
- **Copy:** Types implementing `Copy` (integers, floats, bools, `char`, tuples of
  Copy types) are duplicated on assignment — the original stays valid.
- **Borrow (`&T`):** An immutable reference lets you read but not modify. Multiple
  immutable borrows can coexist.
- **Mutable borrow (`&mut T`):** A mutable reference lets you modify. Only one
  mutable borrow can exist at a time, and no immutable borrows can coexist with it.
- **Lifetime:** Every reference has a lifetime — the scope for which it is valid.
  The compiler infers lifetimes where possible (lifetime elision rules). When it
  can't infer, you must annotate with `'a`, `'b`, etc.

**Key insight:** The borrow checker works at compile time by tracking when each
borrow starts (creation of the reference) and ends (last use of the reference,
called the "non-lexical lifetime" or NLL). Two borrows conflict only if their
active ranges overlap.

---

## Ownership Errors

### E0382: Use of moved value

**What it means:** A value was used after its ownership was transferred (moved)
to another variable or function. Once moved, the original binding is invalidated.

**Common root causes:**
- Assigning a `String`, `Vec`, `Box`, or other non-Copy type to a new variable
  and then using the original
- Passing a non-Copy value to a function (transfers ownership) and then using
  the original
- Moving a value into a closure with `move` and then using the original
- Moving a value out of a loop iteration and then looping again

**Resolution patterns:**

1. **Clone if cheap:** If the type implements Clone and copying is acceptable:
   ```rust
   let s1 = String::from("hello");
   let s2 = s1.clone();  // s1 is still valid
   println!("{}", s1);    // OK — s1 was cloned, not moved
   ```

2. **Borrow instead of move:** Pass a reference:
   ```rust
   fn process(s: &str) { /* ... */ }
   let s = String::from("hello");
   process(&s);  // s is still valid — only a reference was passed
   ```

3. **Restructure to avoid double use:** Move the use of the original before
   the move, or restructure so only one path uses the value.

4. **Use `Rc<T>` or `Arc<T>` for shared ownership:** When multiple owners
   genuinely need the same data:
   ```rust
   use std::rc::Rc;
   let s = Rc::new(String::from("hello"));
   let s2 = Rc::clone(&s);  // both s and s2 own the data
   ```

5. **Derive `Copy`** if the type is small and stack-only (all fields are Copy):
   ```rust
   #[derive(Copy, Clone)]
   struct Point { x: i32, y: i32 }
   ```

---

### E0499: Cannot borrow as mutable more than once at a time

**What it means:** You're trying to create a second `&mut` reference to data
that already has an active `&mut` reference. Rust forbids aliased mutable
references to prevent data races and iterator invalidation.

**Common root causes:**
- Calling two methods that both take `&mut self` on the same object in
  overlapping scopes
- Storing a `&mut` reference in a variable and then trying to mutably borrow
  the same data again
- Passing `&mut self` to a helper method while another `&mut` borrow is active
- Mutably borrowing two fields of the same struct through the same `&mut self`
  (the compiler can't always see they're disjoint)

**Resolution patterns:**

1. **Narrow the borrow scope:** Ensure the first `&mut` is no longer used before
   creating the second:
   ```rust
   // Before — overlapping mutable borrows
   let r1 = &mut data;
   let r2 = &mut data;  // ERROR: r1 is still active
   *r1 += 1;

   // After — sequential borrows
   let r1 = &mut data;
   *r1 += 1;
   // r1 is no longer used — borrow ends here (NLL)
   let r2 = &mut data;  // OK
   ```

2. **Split struct borrows:** Borrow individual fields instead of the whole struct:
   ```rust
   // Before — can't borrow struct mutably twice
   fn update(s: &mut MyStruct) {
       helper(&mut s.field_a, &mut s.field_b);  // OK: disjoint fields
   }
   ```

3. **Use `Cell<T>` / `RefCell<T>`** for interior mutability:
   ```rust
   use std::cell::RefCell;
   let data = RefCell::new(vec![1, 2, 3]);
   let mut r1 = data.borrow_mut();
   // Now borrow checking happens at runtime, not compile time
   ```

---

### E0502: Cannot borrow as immutable because it is also borrowed as mutable

**What it means:** You have an active `&mut` reference to some data, and you're
trying to also create an immutable `&` reference to the same data (or vice versa).
Mutable and immutable borrows cannot coexist.

**Common root causes:**
- Holding a `&mut` reference and then reading from the same data
- Pushing to a `Vec` while holding a reference to one of its elements
- Calling a `&self` method on an object while a `&mut self` borrow is active
- Iterating over a collection and trying to modify it during iteration

**Resolution patterns:**

1. **Reorder operations:** Use the immutable reference before the mutable one:
   ```rust
   // Before
   let mut v = vec![1, 2, 3];
   let first = &v[0];    // immutable borrow
   v.push(4);            // mutable borrow — ERROR
   println!("{}", first);

   // After — use immutable borrow before mutation
   let mut v = vec![1, 2, 3];
   let first = v[0];     // copy the value (i32 is Copy)
   v.push(4);            // OK — no active borrow
   println!("{}", first);
   ```

2. **Clone the borrowed value** to release the borrow early:
   ```rust
   let first = v[0].clone();  // clone releases the borrow on v
   v.push(4);                 // OK
   ```

3. **Collect before mutating:** When iterating and modifying:
   ```rust
   let indices: Vec<usize> = data.iter()
       .enumerate()
       .filter(|(_, v)| **v > 10)
       .map(|(i, _)| i)
       .collect();  // borrow ends here
   for i in indices {
       data[i] = 0;  // OK — no active borrow
   }
   ```

**Related:** E0499 is the mutable-mutable equivalent of this error.

---

### E0505: Cannot move out of value because it is borrowed

**What it means:** You're trying to move (transfer ownership of) a value while
there's still an active reference borrowing it. Moving would invalidate the
reference, violating Rust's safety guarantee.

**Common root causes:**
- Creating a reference to a value, then trying to pass the value to a function
  that takes ownership
- Returning a value from a function while a reference to it is still held
- Moving a value into a closure while it's still borrowed elsewhere

**Resolution patterns:**

1. **Drop the borrow before moving:**
   ```rust
   let mut s = String::from("hello");
   let r = &s;
   println!("{}", r);  // last use of r — borrow ends
   drop_string(s);     // OK — no active borrows
   ```

2. **Clone the value** if you need both the borrow and the move:
   ```rust
   let s = String::from("hello");
   let r = &s;
   let owned = s.clone();  // clone so we can move the clone
   println!("{}", r);
   drop_string(owned);
   ```

3. **Restructure** to avoid needing both a borrow and a move simultaneously.

---

### E0507: Cannot move out of behind a shared/mutable reference

**What it means:** You're trying to move a value out of a reference (`&T` or
`&mut T`). References are borrows — they don't grant ownership, so you can't
take the value out.

**Common root causes:**
- Dereferencing a `&String` or `&Vec` and trying to use the inner value by move
- Pattern matching on a reference and binding by value instead of by reference
- Indexing into a `&Vec<String>` and trying to return the element by value
- Trying to move a field out of a `&self` method

**Resolution patterns:**

1. **Clone the value:**
   ```rust
   fn get_name(user: &User) -> String {
       user.name.clone()  // clone instead of move
   }
   ```

2. **Return a reference** instead of an owned value:
   ```rust
   fn get_name(user: &User) -> &str {
       &user.name  // borrow instead of move
   }
   ```

3. **Use `std::mem::replace` or `Option::take`** for `&mut` references:
   ```rust
   fn take_name(user: &mut User) -> String {
       std::mem::replace(&mut user.name, String::new())
   }
   // Or for Option<T>:
   fn take_data(opt: &mut Option<Data>) -> Option<Data> {
       opt.take()
   }
   ```

4. **Match by reference:** Use `ref` keyword or `&` in patterns:
   ```rust
   match &some_vec[0] {
       s => println!("{}", s),  // s is &String, not String
   }
   ```

---

## Lifetime Errors

### E0106: Missing lifetime specifier

**What it means:** A function signature has references in the return type, but
the compiler cannot figure out which input lifetime they relate to. You need to
add explicit lifetime annotations.

**Common root causes:**
- Returning a reference from a function that takes multiple reference parameters
- Struct definitions with reference fields missing lifetime annotations
- Trait implementations where lifetime elision doesn't apply
- Static methods returning references to struct fields

**Resolution patterns:**

1. **Add lifetime annotations** to connect input and output lifetimes:
   ```rust
   // Before — compiler can't infer which input lifetime applies to output
   fn longest(a: &str, b: &str) -> &str { ... }

   // After — explicit lifetime connects output to both inputs
   fn longest<'a>(a: &'a str, b: &'a str) -> &'a str { ... }
   ```

2. **For structs with references:** Add lifetime parameter to the struct:
   ```rust
   struct Excerpt<'a> {
       text: &'a str,
   }
   ```

3. **Return an owned type** to avoid lifetime annotations entirely:
   ```rust
   fn longest(a: &str, b: &str) -> String {
       if a.len() > b.len() { a.to_string() } else { b.to_string() }
   }
   ```

**Lifetime elision rules** (when you DON'T need annotations):
1. Each reference parameter gets its own lifetime
2. If there's exactly one input lifetime, it's assigned to all output lifetimes
3. If the first parameter is `&self` or `&mut self`, its lifetime is assigned to
   all output lifetimes

---

### E0597: Value does not live long enough

**What it means:** A reference outlives the data it points to. The borrowed value
is dropped (destroyed) before the reference's last use.

**Common root causes:**
- Creating a reference to a local variable and returning it from a function
- Borrowing a value created inside an inner scope `{ ... }` and using it outside
- Storing a reference to a temporary value
- Lifetime mismatch between struct fields and the data they reference

**Resolution patterns:**

1. **Move the data to the outer scope:**
   ```rust
   // Before — short_lived dies at }, but reference escapes
   let r;
   {
       let short_lived = String::from("temp");
       r = &short_lived;  // ERROR: short_lived doesn't live long enough
   }

   // After — move data to outer scope
   let long_lived = String::from("temp");
   let r = &long_lived;  // OK — same scope
   ```

2. **Return an owned value** instead of a reference:
   ```rust
   fn create_greeting(name: &str) -> String {  // return String, not &str
       format!("Hello, {}!", name)
   }
   ```

3. **Use `'static` lifetime** for compile-time constants:
   ```rust
   fn get_greeting() -> &'static str {
       "Hello, world!"  // string literals have 'static lifetime
   }
   ```

---

### E0515: Cannot return reference to local variable

**What it means:** A function creates a local value and tries to return a
reference to it. When the function returns, all local variables are dropped,
so the reference would be dangling.

**Common root causes:**
- Creating a `String` and returning `&str` referring to it
- Building a `Vec` and returning `&[T]`
- Creating any owned value and trying to return a borrow of it

**Resolution patterns:**

1. **Return an owned type:**
   ```rust
   // Before — ERROR: returns reference to local
   fn make_greeting() -> &str {
       let s = format!("Hello");
       &s  // s is dropped here — dangling reference!
   }

   // After — return owned String
   fn make_greeting() -> String {
       format!("Hello")
   }
   ```

2. **Accept a buffer parameter** and write into it:
   ```rust
   fn make_greeting(buf: &mut String) {
       buf.clear();
       buf.push_str("Hello");
   }
   ```

3. **Use `Cow<str>`** for flexibility (sometimes returns borrowed, sometimes owned):
   ```rust
   use std::borrow::Cow;
   fn get_name(input: &str) -> Cow<str> {
       if input.is_empty() {
           Cow::Owned(String::from("default"))
       } else {
           Cow::Borrowed(input)
       }
   }
   ```

---

### E0621: Explicit lifetime required in the type of ...

**What it means:** A function's lifetime annotations are insufficient. The
compiler needs a more specific lifetime to prove the reference is valid.
Typically seen with trait implementations and generic code.

**Common root causes:**
- Implementing an iterator that yields references
- Generic functions where lifetime relationships between parameters aren't clear
- Trait objects (`dyn Trait`) that need lifetime bounds
- Functions using references in both parameters and return types without linking
  their lifetimes

**Resolution patterns:**

1. **Add the requested lifetime annotation:**
   ```rust
   // Before
   fn first_word(s: &str) -> &str { ... }  // works due to elision
   // But in more complex cases:
   impl<'a> Iterator for Words<'a> {
       type Item = &'a str;
       fn next(&mut self) -> Option<&'a str> { ... }
   }
   ```

2. **Add lifetime bounds to trait objects:**
   ```rust
   fn process(handler: &dyn Handler + 'static) { ... }
   // or
   fn process<'a>(handler: &'a dyn Handler) { ... }
   ```

3. **Connect lifetimes** in struct and method definitions:
   ```rust
   struct Parser<'input> {
       text: &'input str,
   }

   impl<'input> Parser<'input> {
       fn next_token(&mut self) -> Token<'input> { ... }
   }
   ```

---

### E0373: Closure may outlive the current function

**What it means:** A closure captures a reference to a local variable, but the
closure might be used after the function returns (e.g., passed to `thread::spawn`
or stored in a struct). This would create a dangling reference.

**Common root causes:**
- Passing a closure to `std::thread::spawn` that references local variables
- Storing a closure in a struct where the closure captures references
- Using `async` blocks or `tokio::spawn` with references to local variables
- Returning a closure that captures references to local values

**Resolution patterns:**

1. **Use `move` to transfer ownership** into the closure:
   ```rust
   let name = String::from("Alice");
   std::thread::spawn(move || {
       println!("Hello, {}", name);  // name is moved into the closure
   });
   // name is no longer available here
   ```

2. **Clone before moving** if you still need the value:
   ```rust
   let name = String::from("Alice");
   let name_clone = name.clone();
   std::thread::spawn(move || {
       println!("Hello, {}", name_clone);
   });
   println!("Original: {}", name);  // OK — name wasn't moved
   ```

3. **Use `Arc<T>` for shared ownership** across threads:
   ```rust
   use std::sync::Arc;
   let data = Arc::new(vec![1, 2, 3]);
   let data_clone = Arc::clone(&data);
   std::thread::spawn(move || {
       println!("{:?}", data_clone);
   });
   ```

---

## Common Refactoring Strategies

### Strategy: Extract to owned type
When lifetime errors become complex, consider returning owned types (`String`
instead of `&str`, `Vec<T>` instead of `&[T]`). This trades a small allocation
for simpler code. It's usually the right call unless you're in a hot loop.

### Strategy: Scope narrowing
Limit the scope of borrows by introducing inner blocks `{ ... }`. The borrow
ends at the closing brace, freeing the value for other uses:
```rust
let mut data = vec![1, 2, 3];
{
    let first = &data[0];  // immutable borrow starts
    println!("{}", first);  // immutable borrow ends (NLL)
}
data.push(4);  // OK — no active borrow
```

### Strategy: Split struct into borrowed and owned parts
If a struct holds references and is causing lifetime headaches, consider
splitting it into a "builder" (owned) and a "view" (borrowed). The builder owns
all data; the view borrows from the builder with clear lifetime relationships.

### Strategy: Use interior mutability
`RefCell<T>` (single-thread) or `Mutex<T>` / `RwLock<T>` (multi-thread)
move borrow checking to runtime when the static rules are too restrictive:
```rust
use std::cell::RefCell;
let data = RefCell::new(vec![1, 2, 3]);
// Multiple parts of code can borrow mutably (checked at runtime)
data.borrow_mut().push(4);
```

**Warning:** Interior mutability should be a last resort — it trades compile-time
safety for runtime panics on borrow violations. Prefer restructuring code first.

---

## Getting More Help

Run `rustc --explain E0xxx` for the official explanation of any error code.
You can also browse all error codes at https://doc.rust-lang.org/error_codes/.
