---
name: buildcheck-analysis
description: "Knowledge about MSBuild BuildCheck - experimental feature for analyzing build scripts for quality issues. It can detecting common problems like shared output paths, double writes, undefined properties, and more. Use /check flag or configure via .editorconfig."
---

# Running MSBuild BuildCheck (MSBuild Analyzers)

## Overview

BuildCheck is MSBuild's built-in analysis feature that helps improve the quality of your build scripts by detecting common issues. It runs analyzers (called "checks") during the build that report violations as warnings or errors.

BuildCheck can detect issues like:
- **Shared output paths** between projects (BC0101)
- **Double writes** - multiple tasks writing the same file (BC0102)
- **Environment variable usage** that can cause non-deterministic builds (BC0103)
- **Undefined property usage** (BC0201)
- **Properties declared after use** (BC0202)
- And many more...

## When to Use This Skill

**Invoke BuildCheck when:**
- Setting up a new project and want to ensure build script quality
- Experiencing intermittent or non-deterministic build failures
- Migrating or modernizing an existing codebase
- Auditing a project for best practices
- Investigating shared output or double-write issues

## Running BuildCheck

### Live Build with `/check` Flag

Add the `/check` flag to any MSBuild-based command to enable BuildCheck analysis:

```bash
# With dotnet CLI
dotnet build /check /bl:N.binlog

# With MSBuild directly
msbuild /check /bl:N.binlog

# For test, pack, publish, etc.
dotnet test /check /bl:N.binlog
dotnet pack /check /bl:N.binlog
dotnet publish /check /bl:N.binlog
```

**IMPORTANT:** Always combine `/check` with `/bl:N.binlog` to generate a binary log for deeper analysis if needed. Follow the [binlog-generation skill](../binlog-generation/SKILL.md) naming conventions.

### Binlog Replay Mode

You can also run BuildCheck on an existing binary log:

```bash
# Run BuildCheck on a previously captured binlog
dotnet build msbuild.binlog /check
```

This is useful for:
- Running additional checks that weren't enabled during the original build
- Re-analyzing a build with different check configurations
- Analyzing builds from CI/CD without rebuilding locally

## Understanding BuildCheck Output

BuildCheck reports use codes prefixed with `BC` (BuildCheck). The codes are organized into categories:
- **BC01xx** - Build output and file handling checks
- **BC02xx** - Property usage checks
- **BC03xx** - Security and best practice checks

### Complete List of BuildCheck Codes

| Code | Default Severity | Default Scope | Available From | Description |
|------|-----------------|---------------|----------------|-------------|
| **BC0101** | Warning | N/A | SDK 9.0.100 | **Shared output path** - Two projects should not share their OutputPath nor IntermediateOutputPath locations |
| **BC0102** | Warning | N/A | SDK 9.0.100 | **Double writes** - Two tasks should not write the same file |
| **BC0103** | Suggestion | Project | SDK 9.0.100 | **Used environment variable** - Environment variables should not be used as a value source for properties |
| **BC0104** | Warning | N/A | SDK 9.0.200 | **ProjectReference preferred** - A project should not be referenced via 'Reference' to its output, but rather via 'ProjectReference' |
| **BC0105** | Warning | N/A | SDK 9.0.200 | **EmbeddedResource Culture** - EmbeddedResource should specify explicit 'Culture' metadata or 'WithCulture=false' |
| **BC0106** | Warning | N/A | SDK 9.0.200 | **CopyToOutputDirectory='Always'** - Avoid 'Always'; use 'PreserveNewest' or 'IfDifferent' instead |
| **BC0107** | Warning | N/A | SDK 9.0.200 | **TargetFramework vs TargetFrameworks** - Both properties should not be specified at the same time |
| **BC0108** | Warning | N/A | SDK 9.0.300 | **TargetFramework in non-SDK project** - TargetFramework(s) properties are not respected in SDK-less projects |
| **BC0201** | Warning | Project | SDK 9.0.100 | **Undefined property usage** - A property that is accessed should be declared first |
| **BC0202** | Warning | Project | SDK 9.0.100 | **Property declared after use** - A property should be declared before it is first used |
| **BC0203** | None | Project | SDK 9.0.100 | **Unused property** - A property that is not used should not be declared |
| **BC0301** | None | Project | SDK 9.0.300 | **Downloads folder** - Downloads folder is untrusted for building projects |
| **BC0302** | Warning | N/A | SDK 9.0.300 | **Exec task for builds** - The 'Exec' task should not be used to build projects; use MSBuild task instead |

**Notes:**
- **Scope "N/A"** means the check analyzes build execution data where scoping is not applicable - the entire build is always checked.
- **Scope "Project"** means the check uses evaluation-time data and can be configured to check only the project file, work tree imports, or all imports.
- Checks with **"None" severity** are disabled by default and must be explicitly enabled via `.editorconfig`.

### Example Output

```
warning BC0101: Two projects should not share their OutputPath nor IntermediateOutputPath locations
warning BC0201: A property that is accessed should be declared first. Property: 'MyUndefinedProp'
```

## Configuring BuildCheck via .editorconfig

BuildCheck is configured using `.editorconfig` files, providing a familiar experience consistent with Roslyn analyzers.

### Configuration Location

Place `.editorconfig` files:
- In the project directory (applies to that project)
- In parent directories (applies to all projects in subdirectories)
- At the repository root (applies to all projects)

### Configuring Severity

```ini
# .editorconfig

# Apply to all .csproj files
[*.csproj]

# Enable a check as error
build_check.BC0101.severity=error

# Disable a check completely
build_check.BC0103.severity=none

# Set as warning (default for most checks)
build_check.BC0102.severity=warning

# Set as informational message
build_check.BC0201.severity=suggestion
```

### Severity Levels

| Level | Description |
|-------|-------------|
| `error` | Fails the build |
| `warning` | Reports as warning, doesn't fail build |
| `suggestion` | Reports as low-priority message |
| `none` | Disables the check completely |
| `default` | Uses the check's built-in default severity |

### Configuring Scope

Some checks support scope configuration to limit analysis to specific files:

```ini
[*.csproj]
# Only check the project file itself, not imports
build_check.BC0201.scope=project_file

# Check project file and local imports (not SDK/NuGet)
build_check.BC0201.scope=work_tree_imports

# Check everything including SDK and NuGet imports
build_check.BC0201.scope=all
```

### Check-Specific Configuration

Some checks have additional configuration options:

```ini
[*.csproj]
# BC0201/BC0202: Control whether uninitialized properties in conditions are allowed
build_check.BC0201.AllowUninitializedPropertiesInConditions=false
build_check.BC0202.AllowUninitializedPropertiesInConditions=false
```

## Disabling BuildCheck Entirely

If you need to disable BuildCheck completely (e.g., for faster inner-loop builds):

```bash
# Via command line property
dotnet build /p:RunMSBuildChecks=false
```

Or in your project/props file:

```xml
<PropertyGroup>
  <RunMSBuildChecks>false</RunMSBuildChecks>
</PropertyGroup>
```

## Troubleshooting BuildCheck Issues

### BC0101 - Shared Output Path

**Problem:** Multiple projects write to the same `OutputPath` or `IntermediateOutputPath`.

**Solutions:**
1. Use [Artifacts output layout](https://learn.microsoft.com/en-us/dotnet/core/sdk/artifacts-output)
2. Ensure each project has a unique output path
3. For multi-targeting, verify `AppendTargetFrameworkToOutputPath` is not disabled

See also: [check-bin-obj-clash skill](../check-bin-obj-clash/SKILL.md) for detailed diagnosis.

### BC0102 - Double Writes

**Problem:** Multiple tasks attempt to write the same file.

**Solutions:**
1. Give intermediate outputs distinct names
2. Review your build pipeline for redundant copy operations
3. Check for overlapping glob patterns in item groups

### BC0103 - Environment Variable Usage

**Problem:** Build depends on environment variables, causing non-deterministic builds.

**Solutions:**
1. Pass values explicitly via `/p:PropertyName=Value`
2. Define properties in project files or Directory.Build.props
3. If environment variables are intentional, suppress with `.editorconfig`

### BC0104 - Reference Instead of ProjectReference

**Problem:** A project uses `<Reference>` to an output DLL instead of `<ProjectReference>`.

**Solutions:**
1. Change `<Reference Include="path/to/Project.dll">` to `<ProjectReference Include="path/to/Project.csproj">`
2. This ensures proper build ordering and dependency tracking

### BC0201/BC0202 - Property Usage Issues

**Problem:** Properties are used before being defined or used without definition.

**Solutions:**
1. Define properties before use
2. Check for typos in property names
3. Use conditions when accessing optional properties: `'$(Prop)' != ''`

## Best Practices

1. **Start with defaults** - Run `/check` without configuration to see what issues exist
2. **Enable incrementally** - Don't turn everything to `error` at once
3. **Use .editorconfig hierarchy** - Set defaults at repo root, override per-project as needed
4. **Combine with binlog** - Always generate a binary log for deeper investigation
5. **CI/CD integration** - Run BuildCheck in CI to catch regressions

## References

- [BuildCheck Design Spec](https://github.com/dotnet/msbuild/blob/main/documentation/specs/BuildCheck/BuildCheck.md)
- [BuildCheck Codes Reference](https://github.com/dotnet/msbuild/blob/main/documentation/specs/BuildCheck/Codes.md)
