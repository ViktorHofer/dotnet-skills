# Expected Findings: perf-analyzers

## Problem Summary
A .NET project with 5 Roslyn analyzer packages (2 global via `GlobalPackageReference` in `Directory.Build.props`, 3 project-specific) and `EnforceCodeStyleInBuild=true` set at the repo level, causing slow build times due to analyzer overhead. The correct solution requires understanding MSBuild build hierarchy and conditional property configuration.

## Expected Findings

### 1. Excessive Analyzer Overhead
- **Issue**: 5 total analyzer packages — 2 applied globally via `GlobalPackageReference` in `Directory.Build.props` (Microsoft.CodeAnalysis.NetAnalyzers, StyleCop.Analyzers) and 3 added per-project (Roslynator.Analyzers, SonarAnalyzer.CSharp, Meziantou.Analyzer). Combined, they significantly increase Csc compilation time.
- **Evidence**: Analyzer execution time visible in binlog as a large portion of the Csc task duration. Can be measured with `get_expensive_analyzers` MCP tool.
- **Solution**: Conditionally disable analyzers during development inner loop.

### 2. No Conditional Analyzer Configuration
- **Issue**: Analyzers run unconditionally on every build — both local development and CI. `EnforceCodeStyleInBuild` is set to `true` in `Directory.Build.props` without any condition, forcing code-style analysis even during rapid development iteration.
- **Solution**: Use `<RunAnalyzers Condition="'$(ContinuousIntegrationBuild)' != 'true'">false</RunAnalyzers>` or `<RunAnalyzers Condition="'$(Configuration)' == 'Debug'">false</RunAnalyzers>` in Directory.Build.props to disable in dev. Conditionally set `<EnforceCodeStyleInBuild>` only for CI builds.

### 3. GlobalPackageReference Applies to All Projects
- **Issue**: `GlobalPackageReference` in `Directory.Build.props` applies analyzers to **every project** in the repo, including test projects where some analyzers may not be useful. This increases build time across the entire solution needlessly.
- **Solution**: Either accept the overhead for consistency, or use per-project PackageReferences for analyzers that aren't needed everywhere.

## Key Concepts That Should Be Mentioned
- Roslyn analyzer performance impact on Csc task duration
- `RunAnalyzers` property to disable all analyzers
- `EnforceCodeStyleInBuild` property for code-style analyzers specifically
- Conditional property based on `ContinuousIntegrationBuild` or `Configuration`
- Using binlog to measure per-analyzer cost (`get_expensive_analyzers` MCP tool)
- Separating CI enforcement from dev inner loop
- `GlobalPackageReference` applying analyzers repo-wide
- MSBuild property XML for conditional analyzer configuration

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified all 5 analyzer packages including the 2 from GlobalPackageReference in Directory.Build.props
- [ ] Named at least 3 of the specific analyzer packages
- [ ] Explained that analyzers significantly increase Csc compilation time
- [ ] Identified `RunAnalyzers` property as the key solution for disabling in dev
- [ ] Provided conditional MSBuild property XML (e.g., `Condition="'$(ContinuousIntegrationBuild)' != 'true'"` or Configuration-based)
- [ ] Identified `EnforceCodeStyleInBuild` should be conditional on CI, not always true
- [ ] Suggested separating CI enforcement from dev inner loop builds
- [ ] Mentioned binlog analysis or `get_expensive_analyzers` for measuring per-analyzer time
- [ ] Identified that GlobalPackageReference analyzers apply to all projects in the repo
- [ ] Solution preserves full analyzer enforcement in CI pipelines while speeding dev builds

Total: __/10

## Expected Skills
- build-perf-diagnostics
