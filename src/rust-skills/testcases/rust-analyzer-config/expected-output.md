# Expected Findings: rust-analyzer-config

## Problem Summary
A Rust project has a misconfigured Copilot CLI LSP integration. The
`copilot-lsp-config.json` has several errors (wrong server key name, wrong
command name, wrong language ID, trailing comma making it invalid JSON), the
`rust-toolchain.toml` is missing the `rust-analyzer` component, and the
`rust-analyzer.toml` has suboptimal settings.

## Expected Findings

### 1. Fix the Copilot CLI LSP config file (lsp-config.json)
- **Issue:** The `copilot-lsp-config.json` has multiple problems:
  - Server key should be `"rust"`, not `"rust-lang"`
  - Command should be `"rust-analyzer"`, not `"rust-analyzer-server"`
  - The `--stdio` arg is unnecessary (rust-analyzer uses stdio by default)
  - Language ID in `fileExtensions` should be `"rust"`, not `"rust-lang"`
  - Trailing comma after the server object makes it invalid JSON
- **Fix:** Provide the correct `~/.copilot/lsp-config.json` content with proper
  server key, command name, and language ID

### 2. Correct location for lsp-config.json
- **Issue:** The config file should be at `~/.copilot/lsp-config.json`, not in
  the project root
- **Fix:** Explain that `copilot-lsp-config.json` must be placed at
  `~/.copilot/lsp-config.json` (user's home directory)

### 3. Install rust-analyzer component
- **Issue:** `rust-toolchain.toml` lists `clippy` and `rustfmt` but not
  `rust-analyzer`
- **Fix:** Add `"rust-analyzer"` to the components list, or run
  `rustup component add rust-analyzer`

### 4. Verification commands
- **Issue:** User needs to know how to verify the setup
- **Fix:** Explain `/lsp show` and `/lsp test rust` commands in Copilot CLI

### 5. Describe capabilities gained
- **Issue:** User wants to know what LSP integration enables
- **Fix:** List key capabilities: find implementations, go to definition, find
  references, symbol search, type information, hover documentation

### 6. Improve rust-analyzer.toml settings
- **Issue:** `features = []` means no features are enabled (feature-gated code
  will show errors). `check.command = "check"` is the default and misses clippy
  diagnostics. Missing `procMacro.enable`.
- **Fix:** Suggest `features = "all"`, `check.command = "clippy"`, and enabling
  proc macros

## Key Concepts
- Copilot CLI LSP integration via `~/.copilot/lsp-config.json`
- rust-analyzer installation via `rustup component add rust-analyzer`
- LSP capabilities for code intelligence (find impls, go-to-def, references)
- rust-analyzer workspace configuration via `rust-analyzer.toml`
- Verification workflow: `/lsp show` and `/lsp test rust`

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified the wrong command name (`rust-analyzer-server` → `rust-analyzer`)
- [ ] Identified the wrong server key or language ID (`rust-lang` → `rust`)
- [ ] Identified the trailing comma / invalid JSON issue
- [ ] Provided the correct `lsp-config.json` content with proper structure
- [ ] Mentioned the config file location (`~/.copilot/lsp-config.json`)
- [ ] Identified missing `rust-analyzer` component in `rust-toolchain.toml`
- [ ] Mentioned `rustup component add rust-analyzer` or equivalent installation
- [ ] Suggested `/lsp show` or `/lsp test rust` for verification
- [ ] Listed code intelligence capabilities (find implementations, go-to-def, references, etc.)
- [ ] Suggested improvements to `rust-analyzer.toml` (clippy as check command, features = "all", proc-macros)

Total: __/10

## Expected Skills
- rust-analyzer-setup
