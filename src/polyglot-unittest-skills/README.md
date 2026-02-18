# Polyglot Unit Test Skills

Generates comprehensive unit tests for any programming language using a multi-agent pipeline (C#, TypeScript, Python, Go, Rust, Java, etc.).

## 🔧 Skills

| Skill | Description |
|-------|-------------|
| [`polyglot-test-generation`](skills/polyglot-test-generation/) | Orchestrates multi-agent test generation for any language |

## 🤖 Agents

| Agent | Description |
|-------|-------------|
| [`test-generator`](agents/test-generator.agent.md) | Pipeline orchestrator — coordinates the full Research→Plan→Implement workflow |
| [`researcher`](agents/researcher.agent.md) | Analyzes codebase structure, testing patterns, and testability |
| [`planner`](agents/planner.agent.md) | Creates phased test implementation plans |
| [`implementer`](agents/implementer.agent.md) | Writes test files and verifies they compile and pass |
| [`builder`](agents/builder.agent.md) | Runs build/compile commands and reports results |
| [`tester`](agents/tester.agent.md) | Runs test commands and reports pass/fail |
| [`fixer`](agents/fixer.agent.md) | Fixes compilation errors |
| [`linter`](agents/linter.agent.md) | Runs code formatting/linting |
