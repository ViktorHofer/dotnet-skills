use std::fs;
use std::collections::HashMap;

fn read_config(path: &str) -> HashMap<String, String> {
    let content = fs::read_to_string(path).unwrap();
    let mut config = HashMap::new();
    for line in content.lines() {
        let parts: Vec<&str> = line.split('=').collect();
        let key = parts[0].trim().to_string();
        let value = parts[1].trim().to_string();
        config.insert(key, value);
    }
    config
}

fn parse_port(config: &HashMap<String, String>) -> u16 {
    let port_str = config.get("port").unwrap();
    port_str.parse().unwrap()
}

fn connect_to_server(host: &str, port: u16) -> Result<(), String> {
    if host.is_empty() {
        return Err(format!("host is empty"));
    }
    if port == 0 {
        return Err(format!("invalid port"));
    }
    println!("Connected to {}:{}", host, port);
    Ok(())
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let config = read_config("server.conf");
    let port = parse_port(&config);
    let host = config.get("host").unwrap().clone();
    connect_to_server(&host, port).map_err(|e| e)?;
    Ok(())
}

fn main() {
    match run() {
        Ok(()) => println!("Success"),
        Err(e) => println!("Error: {}", e),
    }
}
