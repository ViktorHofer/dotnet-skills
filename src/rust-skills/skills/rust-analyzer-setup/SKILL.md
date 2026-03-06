---
name: rust-analyzer-setup
description: "Guide for setting up and configuring rust-analyzer for Rust development tooling and IDE integration. Only activate in Rust/Cargo build contexts (see shared/domain-check.md for signals). Use when setting up rust-analyzer, configuring GitHub Copilot CLI LSP integration for Rust, troubleshooting rust-analyzer issues, or configuring workspace settings. Covers installation via rustup, Copilot CLI lsp-config.json setup, editor integration, workspace configuration, and common troubleshooting patterns. DO NOT use for non-Rust IDE/tooling setup."
---

# rust-analyzer Setup and Configuration

rust-analyzer is the official language server for Rust. It provides code
intelligence features (go-to-definition, find references, find implementations,
completions, inline diagnostics) to any editor or tool that speaks the Language
Server Protocol (LSP).

---

## Installation

### Via rustup (recommended)

```bash
rustup component add rust-analyzer
```

This installs rust-analyzer as a rustup proxy that delegates to the version
matching your active toolchain. It is the simplest and most reliable method.

**Requirements:**
- Rust toolchain 1.64+ (component available since stable 1.64)
- For Microsoft internal toolchains: 1.92+ have the rust-analyzer component

To verify installation:

```bash
rust-analyzer --version
```

### Via standalone binary

Download from https://github.com/rust-lang/rust-analyzer/releases. Place the
binary on your `PATH`. Use this method when you want a specific version or when
rustup is not available.

### Pinning in rust-toolchain.toml

To ensure all team members have rust-analyzer available:

```toml
[toolchain]
channel = "stable"
components = ["clippy", "rustfmt", "rust-analyzer"]
```

This automatically installs the component when anyone runs `cargo` or `rustc`
in the project directory.

---

## GitHub Copilot CLI — LSP Integration

Copilot CLI can communicate with language servers to provide code intelligence
during conversations. By default it supports TypeScript and Python. To enable
Rust support, you must configure rust-analyzer as an LSP server.

### Step 1: Create the LSP configuration file

Create or edit `~/.copilot/lsp-config.json`:

```json
{
    "lspServers": {
        "rust": {
            "command": "rust-analyzer",
            "args": [],
            "fileExtensions": {
                ".rs": "rust"
            }
        }
    }
}
```

**Key fields:**
- `"command"` — The executable name. Must be exactly `"rust-analyzer"` (not
  `"rust-analyzer-server"` or any other variant). If installed via rustup,
  it installs a proxy on your PATH. Use the full path if installed standalone.
- `"args"` — Command-line arguments. Must be `[]` (empty). rust-analyzer uses
  stdio by default; do **not** pass `["--stdio"]`.
- The server key (e.g., `"rust"`) — Must match the language identifier. Use
  `"rust"`, not `"rust-lang"` or `"rustlang"`.
- `"fileExtensions"` — Maps file extensions to language IDs. The value must
  be `"rust"` (not `"rust-lang"`).

**Location of the config file (CRITICAL):**

The file **must** be placed in the Copilot CLI configuration directory. By
default this is `~/.copilot/`, but it can be overridden:

| Method | Example |
|--------|---------|
| Default | `~/.copilot/lsp-config.json` |
| `--config-dir` flag | `copilot --config-dir /path/to/dir` → reads `/path/to/dir/lsp-config.json` |
| `XDG_CONFIG_HOME` env var | `export XDG_CONFIG_HOME=/path/to/dir` → reads `/path/to/dir/lsp-config.json` |

Platform-specific default paths:

| OS | Default Path |
|----|------|
| Linux / macOS | `~/.copilot/lsp-config.json` |
| Windows | `%USERPROFILE%\.copilot\lsp-config.json` |

The config is **not** read from the project root. If a user has placed it in
the project, tell them to move it to the config directory above.

Create the directory if it doesn't exist:

```bash
# Linux / macOS
mkdir -p ~/.copilot

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.copilot"
```

### Automated setup

Instead of manually creating the config file, you can run the setup script
bundled with this skill:

```bash
# From the skill directory (or wherever the script is accessible)
bash setup-rust-lsp.sh

# On Windows (PowerShell)
pwsh setup-rust-lsp.ps1
```

These scripts will:
1. Create `~/.copilot/` if it doesn't exist
2. Write a correct `lsp-config.json` (or merge into an existing one)
3. Verify rust-analyzer is on PATH

**Note:** The plugin format does not support bundling LSP configs directly.
The `lsp-config.json` must be placed in the user's config directory (manually
or via the setup scripts above). There is no `lsp` field in `plugin.json`.

### Common mistakes in lsp-config.json

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Wrong command: `"rust-analyzer-server"` | Server fails to start | Use `"rust-analyzer"` |
| Wrong server key: `"rust-lang"` | Server not matched to .rs files | Use `"rust"` |
| Wrong language ID: `"rust-lang"` in fileExtensions | LSP features not activated | Use `"rust"` |
| Unnecessary args: `["--stdio"]` | May cause startup issues | Use `[]` |
| Trailing comma in JSON | Parse error, config silently ignored | Remove all trailing commas |
| Config in project root | Copilot CLI doesn't find it | Move to `~/.copilot/lsp-config.json` |

### Step 2: Ensure rust-analyzer is installed

```bash
rustup component add rust-analyzer
rust-analyzer --version
```

### Step 3: Verify the configuration

Inside Copilot CLI, use two built-in commands to verify:

**`/lsp show`** — Lists all configured LSP servers from your `lsp-config.json`.
This confirms the config file was found and parsed. You should see the `rust`
server listed with its command and file extensions.

```
/lsp show
```

**`/lsp test rust`** — Attempts to actually start the rust-analyzer process
and perform a handshake. This verifies the binary exists on PATH, can start,
and responds to LSP initialize requests.

```
/lsp test rust
```

If `/lsp show` works but `/lsp test rust` fails, the issue is with
rust-analyzer installation (not the config file).

### Step 4: Use it

Navigate to your Rust project directory and start Copilot CLI. Ask code
intelligence questions:

```
❯ find all implementations of MyTrait
❯ what types implement the Error trait in this crate?
❯ show me all references to process_request
❯ go to definition of ServiceConfig
```

### Capabilities enabled by LSP integration

| Capability | Example Query |
|------------|---------------|
| Find implementations | "find all implementations of ServiceError" |
| Go to definition | "go to the definition of process_request" |
| Find references | "show me all references to Config" |
| Symbol search | "find all public functions in this crate" |
| Type information | "what is the type of this variable?" |
| Hover documentation | "show the doc comment for this function" |

### Adding multiple languages

The `lsp-config.json` can configure multiple language servers simultaneously:

```json
{
    "lspServers": {
        "rust": {
            "command": "rust-analyzer",
            "args": [],
            "fileExtensions": {
                ".rs": "rust"
            }
        },
        "go": {
            "command": "gopls",
            "args": [],
            "fileExtensions": {
                ".go": "go"
            }
        }
    }
}
```

---

## Workspace Configuration — rust-analyzer.toml

rust-analyzer reads project-level settings from `rust-analyzer.toml` (or
`.rust-analyzer.toml`) placed at the workspace root. This file configures
how rust-analyzer analyzes your code.

### Common settings

```toml
# Enable all features for analysis (important for feature-gated code)
[cargo]
features = "all"

# Enable proc-macro expansion (required for derive macros like serde)
[procMacro]
enable = true

# Run clippy instead of cargo check for on-save diagnostics
[check]
command = "clippy"
extraArgs = ["--all-targets", "--", "-D", "warnings"]
```

### Feature-gated code

If your project uses Cargo features, rust-analyzer may show false errors
for code behind feature gates. Fix this with:

```toml
[cargo]
features = "all"
```

Or specify specific features:

```toml
[cargo]
features = ["feature-a", "feature-b"]
```

### Workspace and multi-crate projects

For workspaces with many crates, you can limit analysis scope:

```toml
[cargo]
# Only analyze specific members
buildScripts.enable = true

[workspace]
# Exclude heavy crates from analysis
members.exclude = ["crate-with-heavy-build-script"]
```

---

## Editor Integration

### VS Code

Install the **rust-analyzer** extension from the VS Code marketplace.
It automatically finds `rust-analyzer` on your PATH or downloads it.

Settings can be configured via VS Code's `settings.json`:

```json
{
    "rust-analyzer.check.command": "clippy",
    "rust-analyzer.cargo.features": "all",
    "rust-analyzer.procMacro.enable": true
}
```

### Neovim (with nvim-lspconfig)

```lua
require('lspconfig').rust_analyzer.setup {
    settings = {
        ['rust-analyzer'] = {
            check = { command = "clippy" },
            cargo = { features = "all" },
            procMacro = { enable = true },
        },
    },
}
```

### Other editors

Any editor supporting LSP can use rust-analyzer. The server is started with:

```bash
rust-analyzer
```

It communicates via stdin/stdout using the LSP JSON-RPC protocol.

---

## Troubleshooting

### rust-analyzer not found

**Symptoms:** "command not found" or Copilot CLI `/lsp test rust` fails.

**Fix:**
1. Verify installation: `rustup component list --installed | grep rust-analyzer`
2. If not installed: `rustup component add rust-analyzer`
3. Check PATH includes `~/.cargo/bin` (or `%USERPROFILE%\.cargo\bin` on Windows)
4. Restart terminal after rustup changes

### Stale or incorrect analysis

**Symptoms:** rust-analyzer shows errors that `cargo check` does not, or misses
errors that `cargo check` finds.

**Fix:**
1. Restart rust-analyzer (VS Code: `Ctrl+Shift+P` → "rust-analyzer: Restart Server")
2. Run `cargo clean` to clear build artifacts
3. Check that `rust-toolchain.toml` matches the toolchain rust-analyzer is using
4. Ensure `Cargo.lock` is up to date (`cargo update`)

### Proc-macro errors or derive macro not expanding

**Symptoms:** "unresolved import" or "cannot find derive macro" for `serde`,
`thiserror`, `clap`, etc.

**Fix:**
1. Enable proc-macros in config:
   ```toml
   [procMacro]
   enable = true
   ```
2. Rebuild proc-macro crates: `cargo clean -p <crate-name>` then `cargo check`
3. Check that the derive feature is enabled (e.g., `serde = { version = "1", features = ["derive"] }`)

### Slow performance on large workspaces

**Symptoms:** High CPU, slow completions, rust-analyzer taking minutes to index.

**Fix:**
1. Use workspace members wisely — split into smaller crates
2. Exclude heavy build scripts: set `[cargo] buildScripts.overrideCommand` to skip them
3. Limit parallel checking:
   ```toml
   [cargo]
   targetDir = "target/rust-analyzer"
   ```
   This gives rust-analyzer its own target directory so it doesn't contend
   with `cargo build`.
4. On very large workspaces, consider `[cargo] sysroot = "discover"` to avoid
   re-analyzing the standard library

### Copilot CLI /lsp test fails

**Symptoms:** `/lsp test rust` returns an error even though `rust-analyzer --version` works.

**Fix:**
1. Verify `~/.copilot/lsp-config.json` exists and is valid JSON
2. Check `"command"` field — must be the exact executable name on your PATH
3. On Windows, the command may need to be `"rust-analyzer.exe"` or the full path
4. Ensure no trailing commas in the JSON (invalid JSON syntax)
5. Restart Copilot CLI after editing lsp-config.json

### Wrong toolchain version

**Symptoms:** rust-analyzer uses a different Rust version than your project expects.

**Fix:**
1. Set `rust-toolchain.toml` in the project root to pin the version
2. Verify: `rustup show` in the project directory
3. rust-analyzer (when installed via rustup) automatically uses the toolchain
   specified in `rust-toolchain.toml`

---

## Quick Reference

| Task | Command / Location |
|------|-------------------|
| Install rust-analyzer | `rustup component add rust-analyzer` |
| Verify installation | `rust-analyzer --version` |
| Copilot CLI config | `~/.copilot/lsp-config.json` |
| Project config | `rust-analyzer.toml` at workspace root |
| Test Copilot LSP | `/lsp show` then `/lsp test rust` |
| Restart in VS Code | `Ctrl+Shift+P` → "rust-analyzer: Restart Server" |
| Explain setting | `rust-analyzer --print-config-schema` |
