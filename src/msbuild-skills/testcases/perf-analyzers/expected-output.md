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

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified excessive number of analyzer packages (5 analyzers)
- [ ] Named at least 3 of the specific analyzer packages
- [ ] Explained that analyzers significantly increase compilation time
- [ ] Mentioned RunAnalyzers property as a solution
- [ ] Mentioned EnforceCodeStyleInBuild property as a solution
- [ ] Suggested separating CI enforcement from dev inner loop
- [ ] Mentioned binlog analysis for measuring analyzer time
- [ ] Explained Csc task duration impact from analyzers
- [ ] Provided specific MSBuild property XML for the fix
- [ ] Solution correctly preserves analyzer enforcement in CI

Total: __/10

## Expected Skills
- build-perf-diagnostics
