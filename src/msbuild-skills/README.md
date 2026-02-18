# MSBuild Skills

Comprehensive MSBuild and .NET build skills: failure diagnosis, performance optimization, code quality, and modernization.

## Skills

### Build Failure Troubleshooting

| Skill | Description |
|-------|-------------|
| `common-build-errors` | Catalog of CS, MSB, NU, NETSDK errors with root causes and step-by-step fixes |
| `nuget-restore-failures` | NuGet restore diagnosis: feed auth, version conflicts, source mapping, lock files |
| `sdk-workload-resolution` | SDK and workload resolution: global.json, roll-forward policies, workload management |
| `multitarget-tfm-issues` | TFM compatibility, multi-targeting setup, conditional compilation, RID issues |
| `sourcegen-analyzer-failures` | Source generator crashes (CS8785), analyzer exceptions (AD0001), debugging techniques |
| `binlog-failure-analysis` | Binary log analysis for deep build failure diagnosis |
| `binlog-generation` | Binary log generation conventions |

### Build Performance Optimization

| Skill | Description |
|-------|-------------|
| `build-perf-baseline` | Performance baseline methodology: cold/warm/no-op measurement, MSBuild Server, graph builds, artifacts output |
| `build-perf-diagnostics` | Performance bottleneck identification using binlog analysis |
| `incremental-build` | Incremental build optimization: Inputs/Outputs, FileWrites, up-to-date checks |
| `build-parallelism` | Parallelism tuning: /maxcpucount, graph build, project dependency optimization |
| `build-caching` | Build caching: NuGet cache, VBCSCompiler, deterministic builds, CI/CD strategies |
| `eval-performance` | Evaluation performance: glob optimization, import chain analysis |

### Code Quality & Modernization

| Skill | Description |
|-------|-------------|
| `msbuild-style-guide` | Best practices for idiomatic MSBuild: naming, conditions, targets, property functions |
| `msbuild-antipatterns` | Anti-pattern catalog with detection rules, severity, and BAD→GOOD fixes |
| `msbuild-modernization` | Legacy to SDK-style project migration with before/after examples |
| `directory-build-organization` | Directory.Build.props/targets/rsp organization and central package management |
| `check-bin-obj-clash` | Output path conflict detection for multi-targeting and multi-project builds |
| `including-generated-files` | Including build-generated files in MSBuild's build process |

### Other

| Skill | Description |
|-------|-------------|
| `multithreaded-task-migration` | Thread-safe MSBuild task migration guide |

## Agents

| Agent | Description |
|-------|-------------|
| `msbuild` | General MSBuild expert — triages problems and routes to specialized skills/agents |
| `build-perf` | Build performance analyst — runs builds, analyzes binlogs, suggests optimizations |
| `msbuild-code-review` | Project file reviewer — scans .csproj/.props/.targets for anti-patterns and improvements |

## Distribution Templates

Ready-to-use templates for different distribution channels:

| Template | Location | Description |
|----------|----------|-------------|
| Agent Instructions | `templates/AGENTS.md` | Copy to repo root as `AGENTS.md` for cross-agent MSBuild guidance |
| Prompt Files | `templates/prompts/` | Copy to `.github/prompts/` for VS Code Copilot Chat workflows |
| Agentic Workflows | `templates/agentic-workflows/` | Copy to `.github/workflows/` for CI-integrated MSBuild automation |
