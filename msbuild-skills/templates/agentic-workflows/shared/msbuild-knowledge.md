---
---

<!-- Shared: Core MSBuild Knowledge -->
<!-- Import this to give the agentic workflow MSBuild expertise -->

## MSBuild Error Code Reference

When you encounter build errors, classify by prefix:
- **CS####**: C# compiler errors (missing types, syntax, type mismatches)
- **MSB####**: MSBuild engine errors (missing imports, SDK issues, conflicts)
- **NU####**: NuGet errors (package resolution, feed issues, version conflicts)
- **NETSDK####**: .NET SDK errors (missing SDK, TFM issues, workload requirements)

## Common Root Causes and Fixes

### "Package not found" (NU1101)
- Check NuGet source configuration: `dotnet nuget list source`
- Verify package name spelling and feed availability
- For private feeds: check authentication

### "Imported project not found" (MSB4019)
- Usually missing SDK: run `dotnet --list-sdks`
- Check `global.json` for SDK version constraints
- Install required SDK or adjust `rollForward` policy

### "Reference assemblies not found" (MSB3644)
- Missing targeting pack for the target framework
- Install the required .NET SDK that includes the targeting pack

### "Package downgrade detected" (NU1605)
- Version conflict in dependency graph
- Fix: explicitly set the higher version in the project

### "Assets file not found" (NETSDK1004)
- NuGet restore hasn't been run: `dotnet restore`

## Build Performance Quick Checks
- Is `-m` (maxcpucount) being used for parallel builds?
- Are analyzers causing excessive build time?
- Is restore being run unnecessarily on every build?
- Are incremental builds working (second build should be fast)?
