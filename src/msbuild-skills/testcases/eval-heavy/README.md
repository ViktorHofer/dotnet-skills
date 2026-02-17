# Evaluation Performance — Heavy Evaluation

A project with evaluation performance anti-patterns.

## Issues Present

1. **Deep import chain**: 3 levels of .props imports (level1→level2→level3)
2. **Overly broad glob**: `**\*.*` scans the entire directory tree
3. **File I/O during evaluation**: `File.ReadAllText` in a property function

## Skills Tested

- `eval-performance` — Evaluation phases, expensive globs, import chain analysis

## How to Test

```bash
# Preprocess to see full evaluation:
dotnet msbuild -pp:full.xml EvalHeavy.csproj
# Check the size of full.xml — it shows all imports inlined

# Build with binlog:
dotnet build /bl:eval.binlog
# Analyze evaluation time vs build time
```
