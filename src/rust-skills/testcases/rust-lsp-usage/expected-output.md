# Expected Findings: rust-lsp-usage

## Problem Summary
A multi-file Rust project with traits, implementations, and cross-file
references. The user asks code intelligence questions that benefit from LSP
capabilities (find implementations, find references, go to definition).

This testcase evaluates whether the model **uses LSP tools** (not just file
reads) to answer the questions, and whether the answers are correct.

## Expected Findings

### 1. StorageBackend implementations
- **MemoryStorage** in `src/storage.rs` — in-memory HashMap-based storage
- **FileStorage** in `src/storage.rs` — file-system-based storage
- Complete list (exactly 2 implementations)

### 2. DataProcessor implementations
- **UppercaseProcessor** in `src/processor.rs`
- **RleProcessor** in `src/processor.rs`
- **Utf8Validator** in `src/processor.rs`
- **ProcessorChain** in `src/processor.rs` (itself implements DataProcessor)
- Complete list (exactly 4 implementations)

### 3. Pipeline::process_key call chain
- `self.storage.get(key)` — StorageBackend::get
- `self.processor.process(&record.value)` — DataProcessor::process
- `self.storage.put(&output_key, &output)` — StorageBackend::put
- Should trace through to the trait definitions in storage.rs / processor.rs

### 4. PipelineError references
- Defined in `src/error.rs`
- Used in `src/storage.rs` (return types of all StorageBackend methods, From impl)
- Used in `src/processor.rs` (return type of DataProcessor::process, used in ProcessorChain)
- Used in `src/pipeline.rs` (return types, process_key error handling)
- At least 3 files besides error.rs

### 5. StorageBackend trait definition
- Should show the trait with all 4 methods: `put`, `get`, `delete`, `list_keys`
- Should mention the `Send + Sync` bounds
- Located in `src/storage.rs`

### 6. ProcessorChain::processors() references
- Defined in `src/processor.rs`
- Currently not called anywhere in the codebase outside of tests
- Should accurately report that it has no external callers

## Key Concepts
- LSP find-implementations queries
- LSP find-references queries
- LSP go-to-definition for call chain tracing
- Cross-file code intelligence in multi-module Rust projects

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Used LSP tools (find implementations, find references, go to definition — not just file reads/greps)
- [ ] Correctly identified both StorageBackend implementations (MemoryStorage, FileStorage)
- [ ] Correctly identified all 4 DataProcessor implementations (UppercaseProcessor, RleProcessor, Utf8Validator, ProcessorChain)
- [ ] Traced Pipeline::process_key call chain through storage.get, processor.process, storage.put
- [ ] Found PipelineError usage across all files (error.rs, storage.rs, processor.rs, pipeline.rs)
- [ ] Showed the StorageBackend trait definition with all 4 methods
- [ ] Mentioned Send + Sync bounds on StorageBackend
- [ ] Correctly reported ProcessorChain::processors() has no callers outside tests
- [ ] Answers are specific with file names and line context (not vague)
- [ ] Used LSP capabilities for at least 3 of the 6 questions (not just reading files)

Total: __/10

## Expected Skills
- rust-analyzer-setup

## Prerequisites
- **Rust toolchain must be installed** (rustup with stable channel)
- **rust-analyzer must be on PATH** (installed via `rustup component add rust-analyzer`)
- **Copilot CLI LSP must be configured** (`~/.copilot/lsp-config.json` with rust server entry)
- Run `cargo check` once in the project to generate build artifacts before testing
