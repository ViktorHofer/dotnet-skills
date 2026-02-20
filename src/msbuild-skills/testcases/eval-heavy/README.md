# Evaluation Performance — Heavy Evaluation

A project with evaluation performance anti-patterns.

## Issues Present

### Surface-Level (any LLM should find)
1. **Deep import chain**: 3 levels of .props imports (level1→level2→level3)
2. **Overly broad glob**: `**\*.*` scans the entire directory tree
3. **File I/O during evaluation**: `File.ReadAllText` in a property function

### Subtle (requires specialized knowledge)
4. **`DefaultItemExcludes` not used**: The glob excludes bin/obj but not .git, node_modules, etc.
5. **UsingTask with RoslynCodeTaskFactory**: Task registration during evaluation phase adds overhead
6. **Multiple evaluation passes**: Property functions and globs fire on every IDE design-time evaluation
7. **`ReadLinesFromFile` as alternative**: The correct execution-phase replacement for `File.ReadAllText`

## Skills Tested

- `eval-performance` — Evaluation phases, expensive globs, import chain analysis, `/pp` preprocessing

## How to Test

```bash
# Preprocess to see full evaluation:
dotnet msbuild -pp:full.xml EvalHeavy.csproj
# Check the size of full.xml — it shows all imports inlined

# Build with binlog:
dotnet build /bl:eval.binlog
# Analyze evaluation time vs build time
```
