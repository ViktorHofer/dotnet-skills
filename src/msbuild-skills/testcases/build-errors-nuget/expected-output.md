# Expected Findings: build-errors-nuget

## Problem Summary
Two .NET projects fail during NuGet restore. One fails because `<packageSourceMapping>` in nuget.config restricts which sources can provide which packages, and Newtonsoft.Json has no matching pattern. The other fails because a transitive dependency requires a higher version than the directly-pinned reference.

## Expected Findings

### 1. PackageNotFound.csproj — Source Mapping Blocks Package Resolution
- **Issue**: Project references `Newtonsoft.Json` 13.0.3 which exists on nuget.org, but the local `nuget.config` uses `<packageSourceMapping>` that only maps `Microsoft.*` and `System.*` patterns to nuget.org. Since `Newtonsoft.*` has no matching pattern, NuGet cannot resolve it from any source.
- **Error code**: NU1100 (unable to resolve package)
- **Root cause**: `<packageSourceMapping>` in nuget.config — NOT that the package doesn't exist
- **Solution**: Add `<package pattern="Newtonsoft.*" />` (or a wildcard `*` pattern) to the nuget.org source mapping in nuget.config

### 2. VersionDowngrade.csproj — Transitive Dependency Downgrade
- **Issue**: `Microsoft.Extensions.Logging` 8.0.0 transitively requires `Microsoft.Extensions.DependencyInjection.Abstractions` >= 8.0.0, but a direct PackageReference pins it to 6.0.0
- **Error code**: NU1605 (package downgrade detected)
- **Root cause**: NuGet's nearest-wins rule means the direct 6.0.0 reference takes priority over the transitive 8.0.0 requirement, creating a version conflict
- **Solution**: Upgrade the direct PackageReference for `DI.Abstractions` to 8.0.0 or higher

## Key Differentiators (Surface-level vs Skill-specific)

### Surface-level (any competent model should identify)
- That PackageNotFound.csproj has a restore failure for Newtonsoft.Json
- That VersionDowngrade.csproj has a version conflict for DI.Abstractions
- Basic fixes (add mapping or upgrade version)

### Subtle / Skill-specific
- **Recognizing `<packageSourceMapping>` as root cause**: The error message says "unable to resolve" but the real cause is source mapping configuration, NOT a missing package. The skill specifically covers "Debugging NU1100 with Source Mapping" and teaches to use `dotnet restore --verbosity detailed` to see source mapping decisions.
- **Nearest-wins rule**: The skill explicitly names this NuGet resolution behavior that causes NU1605.
- **Central Package Management (CPM)**: The skill recommends `Directory.Packages.props` with `<ManagePackageVersions>true</ManagePackageVersions>` as a prevention strategy for version conflicts across multi-project solutions.
- **Diagnostic depth**: Using `dotnet restore --verbosity detailed` to trace source mapping decisions and dependency resolution.

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] 1. Identified that Newtonsoft.Json fails to restore (NU1100 or similar restore error)
- [ ] 2. Recognized `<packageSourceMapping>` in nuget.config as the root cause (not "package doesn't exist")
- [ ] 3. Suggested adding a pattern for `Newtonsoft.*` (or wildcard `*`) to the source mapping
- [ ] 4. Identified NU1605 package downgrade error for DI.Abstractions
- [ ] 5. Explained the transitive dependency chain (Logging 8.0.0 → DI.Abstractions >= 8.0.0)
- [ ] 6. Identified that direct reference pins DI.Abstractions to 6.0.0
- [ ] 7. Suggested upgrading DI.Abstractions to 8.0.0 or higher
- [ ] 8. Mentioned nearest-wins rule or equivalent NuGet resolution concept
- [ ] 9. Recommended Central Package Management (CPM / Directory.Packages.props) OR `dotnet restore --verbosity detailed` as a diagnostic/prevention strategy
- [ ] 10. Explained why the error message is misleading (NU1100 says "unable to resolve" but Newtonsoft.Json exists on nuget.org — source mapping is the real blocker)

Total: __/10

## Expected Skills
- nuget-restore-failures

