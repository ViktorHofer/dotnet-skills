# Build Errors: NuGet (NU) Errors

Sample projects demonstrating NuGet restore failures that require understanding of NuGet configuration and dependency resolution.

## Projects

| Project | Errors Demonstrated | Skills Tested |
|---------|-------------------|---------------|
| `PackageNotFound` | NU1100 (source mapping blocks resolution) | `nuget-restore-failures` |
| `VersionDowngrade` | NU1605 (package downgrade) | `nuget-restore-failures` |

## Key Challenge

The `PackageNotFound` project references `Newtonsoft.Json` which exists on nuget.org, but a `nuget.config` with `<packageSourceMapping>` only maps `Microsoft.*` and `System.*` patterns. This creates a NU1100 error that looks like a missing package but is actually a source mapping configuration issue.

The `VersionDowngrade` project tests understanding of NuGet's nearest-wins resolution rule and transitive dependency chains.

## Surface-level vs Skill-specific

| Category | Surface-level (any model) | Skill-specific |
|----------|--------------------------|----------------|
| PackageNotFound | "Package can't be found" | Recognize `<packageSourceMapping>` as root cause, explain NU1100 vs NU1101 difference |
| VersionDowngrade | "Version conflict, upgrade it" | Nearest-wins rule, CPM recommendation, `--verbosity detailed` diagnostics |

## How to Test

```bash
dotnet build PackageNotFound.csproj    # Should fail with NU1100 (source mapping)
dotnet build VersionDowngrade.csproj   # Should fail with NU1605 (version downgrade)
```
