# Performance: Analyzer Overhead

Project with build infrastructure (Directory.Build.props) applying global analyzers and `EnforceCodeStyleInBuild=true`, plus additional per-project analyzers. Tests whether the AI can diagnose analyzer overhead and provide the correct conditional configuration.

## Setup

- **Directory.Build.props** applies 2 analyzers globally via `GlobalPackageReference` and sets `EnforceCodeStyleInBuild=true`
- **AnalyzerHeavy.csproj** adds 3 more project-specific analyzers (5 total)
- When built with `/bl`, the binlog reveals analyzer execution times

## Skills Tested

- `build-perf-diagnostics` — Diagnosing expensive analyzers, `RunAnalyzers`/`EnforceCodeStyleInBuild` properties
- `build-caching` — VBCSCompiler and analyzer caching

## Expected Finding

The AI should:
1. Identify all 5 analyzers (including 2 from `GlobalPackageReference`)
2. Use `RunAnalyzers` property with a condition (CI vs dev) — not just "remove analyzers"
3. Identify `EnforceCodeStyleInBuild` should be conditional on CI
4. Explain `GlobalPackageReference` applies to all projects in the repo
5. Provide specific MSBuild property XML for the conditional configuration
6. Preserve analyzer enforcement in CI pipelines
