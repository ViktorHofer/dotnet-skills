# Test Case: rust-analyzer-config

## Purpose
Tests the `rust-analyzer-setup` skill by presenting a Rust project with a
misconfigured Copilot CLI LSP integration and suboptimal rust-analyzer settings.

## What's Wrong
1. `copilot-lsp-config.json` has wrong command name, wrong server/language IDs,
   unnecessary args, and a trailing comma (invalid JSON)
2. `rust-toolchain.toml` is missing the `rust-analyzer` component
3. `rust-analyzer.toml` has empty features list and uses `check` instead of `clippy`

## Expected Behavior
The AI should:
- Fix all issues in the Copilot CLI LSP config
- Explain the correct file location (`~/.copilot/lsp-config.json`)
- Identify the missing rust-analyzer toolchain component
- Explain verification commands (`/lsp show`, `/lsp test rust`)
- Describe the code intelligence capabilities gained
- Suggest improvements to rust-analyzer.toml

## Skills Tested
- `rust-analyzer-setup`

## Build Result
Project builds successfully — this is a configuration/setup test, not a build error test.
