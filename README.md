# .NET Skills for AI Assistants

[![Dashboard](https://github.com/ViktorHofer/dotnet-skills/actions/workflows/pages/pages-build-deployment/badge.svg)](https://viktorhofer.github.io/dotnet-skills/dev/bench/)

This repository provides comprehensive .NET development expertise for AI assistants including [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli), [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview), and [GitHub Agentic Workflows](https://github.com/github/gh-aw).

## What's Included

### 🔧 Skills (Knowledge Base)

Skills are AI-readable reference documents that provide deep expertise on specific topics.

#### Build Failure Troubleshooting
| Skill | Description |
|-------|-------------|
| `common-build-errors` | Catalog of CS, MSB, NU, NETSDK errors with root causes and step-by-step fixes |
| `nuget-restore-failures` | NuGet restore diagnosis: feed auth, version conflicts, source mapping, lock files |
| `sdk-workload-resolution` | SDK and workload resolution: global.json, roll-forward policies, workload management |
| `multitarget-tfm-issues` | TFM compatibility, multi-targeting setup, conditional compilation, RID issues |
| `sourcegen-analyzer-failures` | Source generator crashes (CS8785), analyzer exceptions (AD0001), debugging techniques |
| `binlog-failure-analysis` | Binary log analysis for deep build failure diagnosis |
| `binlog-generation` | Binary log generation conventions |

#### Build Performance Optimization
| Skill | Description |
|-------|-------------|
| `build-perf-baseline` | Performance baseline methodology: cold/warm/no-op measurement, MSBuild Server, graph builds, artifacts output |
| `build-perf-diagnostics` | Performance bottleneck identification using binlog analysis |
| `incremental-build` | Incremental build optimization: Inputs/Outputs, FileWrites, up-to-date checks |
| `build-parallelism` | Parallelism tuning: /maxcpucount, graph build, project dependency optimization |
| `build-caching` | Build caching: NuGet cache, VBCSCompiler, deterministic builds, CI/CD strategies |
| `eval-performance` | Evaluation performance: glob optimization, import chain analysis |

#### Code Quality & Modernization
| Skill | Description |
|-------|-------------|
| `msbuild-style-guide` | Best practices for idiomatic MSBuild: naming, conditions, targets, property functions |
| `msbuild-antipatterns` | Anti-pattern catalog: 20 numbered smells with detection rules, severity, and BAD→GOOD fixes |
| `msbuild-modernization` | Legacy to SDK-style project migration with before/after examples |
| `directory-build-organization` | Directory.Build.props/targets/rsp organization and central package management |
| `check-bin-obj-clash` | Output path conflict detection for multi-targeting and multi-project builds |
| `including-generated-files` | Including build-generated files in MSBuild's build process |

#### Other
| Skill | Description |
|-------|-------------|
| `multithreaded-task-migration` | Thread-safe MSBuild task migration guide |

### 🤖 Custom Agents

Agents are autonomous AI personas that orchestrate multi-step workflows.

| Agent | Description |
|-------|-------------|
| `msbuild` | General MSBuild expert — triages problems and routes to specialized skills/agents |
| `build-perf` | Build performance analyst — runs builds, analyzes binlogs, suggests optimizations |
| `msbuild-code-review` | Project file reviewer — scans .csproj/.props/.targets for anti-patterns and improvements |

### 📦 Distribution Templates

Ready-to-use templates for different distribution channels:

| Template | Location | Description |
|----------|----------|-------------|
| Agent Instructions | `src/msbuild-skills/templates/AGENTS.md` | Copy to repo root as `AGENTS.md` for cross-agent MSBuild guidance |
| Prompt Files | `src/msbuild-skills/templates/prompts/` | Copy to `.github/prompts/` for VS Code Copilot Chat workflows |
| Agentic Workflows | `src/msbuild-skills/templates/agentic-workflows/` | Copy to `.github/workflows/` for CI-integrated MSBuild automation |
| Copilot Extension | `src/copilot-extension/` | Deployable `@msbuild` Copilot Extension for GitHub.com, VS Code, and Visual Studio |

### 🧪 Unit Test Generation

| Skill | Description |
|-------|-------------|
| `dotnet-unittest` | Comprehensive C# unit test generation guidance for MSTest, NUnit, and xUnit — framework detection, edge-case analysis, mocking rules, best practices |

### 🌐 Polyglot Test Agent

An AI-powered multi-agent pipeline that generates comprehensive unit tests for any programming language.

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

| Skill | Description |
|-------|-------------|
| `polyglot-test-generation` | Generates unit tests for any language using a multi-agent pipeline (C#, TypeScript, Python, Go, Rust, Java, etc.) |

## Installation

### Copilot CLI / Claude Code

1. Launch Copilot CLI or Claude Code
2. Add the marketplace:
   ```
   /plugin marketplace add ViktorHofer/dotnet-skills
   ```
3. Install the plugin(s) you need:
   - **msbuild-skills** — MSBuild development skills:
     ```
     /plugin install msbuild-skills@dotnet-skills
     ```
   - **polyglot-test-agent** — Polyglot test generation agent:
     ```
     /plugin install polyglot-test-agent@dotnet-skills
     ```
   - **unittest** — .NET unit test generation guidance:
     ```
     /plugin install unittest@dotnet-skills
     ```
4. Restart to load the new skills
5. View available skills:
   ```
   /skills
   ```

### Agent Instructions (Zero Install)

Copy `src/msbuild-skills/templates/AGENTS.md` to your repository root:
```bash
cp src/msbuild-skills/templates/AGENTS.md AGENTS.md
```
This provides MSBuild awareness in Copilot, Claude Code, and other agents that support the `AGENTS.md` standard.

### VS Code Prompt Files (Zero Install)

Copy the prompt templates to your repository:
```bash
mkdir -p .github/prompts
cp src/msbuild-skills/templates/prompts/*.prompt.md .github/prompts/
```
Use them in Copilot Chat with `#prompt` references.

### Agentic Workflows

Copy the workflow templates and compile with `gh aw`:
```bash
cp -r src/msbuild-skills/templates/agentic-workflows/ .github/workflows/
gh aw compile
git add .github/workflows/
```

## Updating

```
/plugin update msbuild-skills@dotnet-skills
/plugin update polyglot-test-agent@dotnet-skills
/plugin update unittest@dotnet-skills
```

## Contributing

See [CONTRIBUTING](docs/CONTRIBUTING.md) for guidelines on adding skills, agents, prompt files, agentic workflows, samples, and more.

## License

See [LICENSE](LICENSE) for details.
