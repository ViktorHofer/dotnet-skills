# Expected Findings: perf-analyzers

## Problem Summary
A .NET project with 5 Roslyn analyzer packages causing slow build times due to analyzer overhead.

## Expected Findings

### 1. Excessive Analyzer Overhead
- **Issue**: Project includes 5 analyzer packages (Microsoft.CodeAnalysis.NetAnalyzers, StyleCop.Analyzers, Roslynator.Analyzers, SonarAnalyzer.CSharp, Meziantou.Analyzer) which significantly increase compilation time
- **Evidence**: Analyzer execution time visible in binlog as a large portion of the Csc task duration
- **Solution**: Disable analyzers during development inner loop with `<RunAnalyzers>false</RunAnalyzers>` or `<EnforceCodeStyleInBuild>false</EnforceCodeStyleInBuild>`

## Key Concepts That Should Be Mentioned
- Roslyn analyzer performance impact on build time
- RunAnalyzers property to disable analyzers
- EnforceCodeStyleInBuild property
- Using binlog to measure analyzer time (get_expensive_analyzers)
- Separating CI enforcement from dev inner loop
