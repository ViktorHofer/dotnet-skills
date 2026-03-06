struct Config {
    max_retries: u32,
    timeout_ms: u64,
    verbose: bool,
}

fn connect(address: &str, timeout: u64) -> Result<(), String> {
    if timeout == 0 {
        return Err("timeout must be positive");
    }
    println!("Connecting to {} with timeout {}ms", address, timeout);
    Ok(())
}

fn apply_config(config: &Config) {
    connect(config.timeout_ms, config.max_retries);
}

fn get_status_message(code: u32) -> &'static str {
    match code {
        200 => "OK",
        404 => "Not Found",
    }
}

fn main() {
    let config = Config {
        max_retries: 3,
        timeout_ms: 5000,
        verbose: true,
    };
    apply_config(&config);

    let message: String = get_status_message(200);
    println!("{}", message);
}
