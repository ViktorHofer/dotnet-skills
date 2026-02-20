use std::collections::BTreeSet;
use std::io::BufWriter;
use serde::Serialize;
use utils::helpers::format_name;

mod models {
    pub struct User {
        pub name: String,
        pub age: u32,
    }
}

fn write_users(users: &[models::User]) {
    let set: BTreeSet<&str> = users.iter().map(|u| u.name.as_str()).collect();
    let mut writer = BufWriter::new(std::io::stdout());
    for name in &set {
        writeln!(writer, "{}", name);
    }
}

fn main() {
    let users = vec![
        models::User { name: "Alice".to_string(), age: 30 },
        models::User { name: "Bob".to_string(), age: 25 },
    ];
    write_users(&users);

    let serialized = serde_json::to_string(&users);
    println!("{}", format_name("test"));
}
