fn main() {
    // E0382: Use of moved value
    let names = vec!["Alice".to_string(), "Bob".to_string()];
    let moved_names = names;
    println!("First name: {}", names[0]);

    // E0502: Cannot borrow as immutable because also borrowed as mutable
    let mut data = vec![1, 2, 3, 4, 5];
    let first = &data[0];
    data.push(6);
    println!("First element: {}", first);

    // E0597: Value does not live long enough
    let reference;
    {
        let short_lived = String::from("temporary");
        reference = &short_lived;
    }
    println!("Reference: {}", reference);
}
