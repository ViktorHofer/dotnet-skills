# MSBuild Skills — Test Samples

This directory contains sample .NET projects designed to test and demo each MSBuild skill. Each sample intentionally contains specific issues that the corresponding skill(s) should help diagnose and fix.

## Sample Matrix

| Sample | Skills Tested | Issue Type | Build Result |
|--------|--------------|------------|--------------|
| [`build-errors-cs`](build-errors-cs/) | `common-build-errors` | CS0246 (missing ref), CS0029 (type mismatch) | ❌ Fails |
| [`build-errors-nuget`](build-errors-nuget/) | `common-build-errors`, `nuget-restore-failures` | NU1101 (package not found), NU1605 (downgrade) | ❌ Fails |
| [`build-errors-sdk`](build-errors-sdk/) | `common-build-errors`, `sdk-workload-resolution` | NETSDK1141 (SDK not found), NETSDK1045 (TFM unsupported) | ❌ Fails |
| [`multitarget`](multitarget/) | `multitarget-tfm-issues` | TFM-specific API missing on netstandard2.0/net472 | ❌ Fails (some TFMs) |
| [`legacy-project`](legacy-project/) | `msbuild-modernization`, `msbuild-style-guide` | Non-SDK-style project, verbose boilerplate | ⚠️ Builds (but needs modernization) |
| [`style-issues`](style-issues/) | `msbuild-style-guide`, `directory-build-organization` | Duplicated props, hardcoded paths, anti-patterns | ⚠️ Builds (but has issues) |
| [`perf-analyzers`](perf-analyzers/) | `build-perf-diagnostics`, `build-caching` | Excessive Roslyn analyzer overhead | ✅ Builds (slowly) |
| [`incremental-broken`](incremental-broken/) | `incremental-build` | Custom target always rebuilds (missing Inputs/Outputs) | ✅ Builds (but never incremental) |
| [`parallel-bottleneck`](parallel-bottleneck/) | `build-parallelism` | Serial dependency chain preventing parallelism | ✅ Builds (but not parallel) |
| [`eval-heavy`](eval-heavy/) | `eval-performance` | Expensive globs, deep import chain, file I/O in eval | ✅ Builds (slow evaluation) |
| [`generated-files`](generated-files/) | `including-generated-files` | Generated .cs file not added to Compile items | ❌ Fails (CS0103) |
| [`bin-obj-clash`](bin-obj-clash/) | `check-bin-obj-clash` | Shared output/intermediate paths causing file conflicts | ⚠️ Builds (but has clashes) |

## How to Use These Samples

### For Testing Skills

1. Open a sample directory in Copilot CLI / Claude Code with the msbuild-skills plugin installed
2. Ask the AI to build the project: `dotnet build`
3. Observe whether the AI correctly:
   - Identifies the error/issue category
   - Invokes the right skill(s)
   - Suggests the correct fix
   - Applies the fix and verifies

### For Demos

Each sample has a README with:
- **Issues Present**: What's wrong and why
- **Skills Tested**: Which skills should activate
- **How to Test**: Commands and prompts to use
- **Expected Behavior**: What the AI should do

### Demo Script (Quick)

```bash
# 1. Build failure diagnosis
cd samples/build-errors-cs && dotnet build MissingReference.csproj
# AI should identify CS0246, suggest adding PackageReference

# 2. NuGet issues
cd ../build-errors-nuget && dotnet build PackageNotFound.csproj
# AI should identify NU1101, suggest checking package sources

# 3. Code review
cd ../style-issues
# Ask: "Review these project files for best practices"
# AI should find duplicated props, hardcoded paths, suggest Directory.Build.props

# 4. Modernization
cd ../legacy-project
# Ask: "Modernize this project to SDK-style"
# AI should transform 60-line csproj to ~6 lines

# 5. Performance
cd ../perf-analyzers && dotnet build /bl:perf.binlog
# Ask: "Analyze this build's performance"
# AI should identify analyzer overhead
```

## Notes

- Some samples require .NET 8.0 SDK or later
- The `build-errors-sdk` sample intentionally uses a global.json pinning a nonexistent SDK
- The `legacy-project` sample uses legacy project format and may not build on all platforms
- Samples that "Build" are testing code quality / performance issues, not compilation errors
