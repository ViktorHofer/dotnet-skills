# rust-lsp-usage

## Purpose
Tests whether the model can **use** LSP capabilities (find implementations,
find references, go to definition) via Copilot CLI's rust-analyzer integration
to answer code intelligence questions about a multi-file Rust project.

This is distinct from `rust-analyzer-config` which tests LSP *setup*. This
testcase tests actual LSP *usage* — ensuring the skill enables the model to
leverage code intelligence features effectively.

## Project Structure
- `src/lib.rs` — Module declarations
- `src/error.rs` — `PipelineError` enum (4 variants, Display + Error impls)
- `src/storage.rs` — `StorageBackend` trait + `MemoryStorage` and `FileStorage` impls
- `src/processor.rs` — `DataProcessor` trait + 4 implementations including `ProcessorChain`
- `src/pipeline.rs` — `Pipeline` struct that ties storage + processing together

## What the Prompt Tests
The prompt asks 6 code intelligence questions:
1. Find implementations of `StorageBackend` trait
2. Find implementations of `DataProcessor` trait
3. Trace the `Pipeline::process_key` call chain
4. Find all references to `PipelineError`
5. Show the `StorageBackend` trait definition
6. Find callers of `ProcessorChain::processors()`

## Prerequisites
This testcase requires:
- **Rust toolchain** installed (rustup with stable channel)
- **rust-analyzer** on PATH
- **Copilot CLI LSP configured** (lsp-config.json with rust entry)

Without these, the model falls back to file reads/greps and may still answer
correctly, but the evaluation specifically checks whether LSP tools were used.

## Expected Scoring
- **Vanilla (no LSP)**: 4-6/10 — Can answer by reading files, but won't use LSP tools
- **Skilled (with LSP configured)**: 7-10/10 — Uses LSP for find-implementations, find-references, etc.
