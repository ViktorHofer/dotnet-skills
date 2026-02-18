# Polyglot Unit Test Skills

Generates comprehensive unit tests for any programming language using a multi-agent pipeline (C#, TypeScript, Python, Go, Rust, Java, etc.).

## Skills

| Skill | Description |
|-------|-------------|
| `polyglot-test-generation` | Orchestrates multi-agent test generation for any language |

## Agents

| Agent | Description |
|-------|-------------|
| `test-generator` | Pipeline orchestrator — coordinates the full Research→Plan→Implement workflow |
| `researcher` | Analyzes codebase structure, testing patterns, and testability |
| `planner` | Creates phased test implementation plans |
| `implementer` | Writes test files and verifies they compile and pass |
| `builder` | Runs build/compile commands and reports results |
| `tester` | Runs test commands and reports pass/fail |
| `fixer` | Fixes compilation errors |
| `linter` | Runs code formatting/linting |
