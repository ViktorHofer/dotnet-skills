# Performance: Analyzer Overhead

Project with many Roslyn analyzers to demonstrate how to diagnose analyzer overhead.

## Setup

This project includes 5 popular analyzer packages. When built with `/bl`, the binlog reveals analyzer execution times.

## Skills Tested

- `build-perf-diagnostics` — Diagnosing expensive analyzers
- `build-caching` — VBCSCompiler and analyzer caching

## How to Test

```bash
# Build with binlog to capture analyzer timing
dotnet build /bl:analyzer-perf.binlog

# Then analyze:
# get_expensive_analyzers(top_number=10) to see which analyzers are slowest
# Compare with: dotnet build /p:RunAnalyzers=false /bl:no-analyzers.binlog
```

## Expected Finding

The AI should identify analyzer overhead and suggest:
- `<RunAnalyzers>false</RunAnalyzers>` for dev inner loop
- Removing the most expensive analyzer if not critical
- `<EnforceCodeStyleInBuild>false</EnforceCodeStyleInBuild>` for faster local builds
