# Expected Findings: build-errors-nuget

## Problem Summary
Two .NET projects fail during NuGet restore due to package resolution errors.

## Expected Findings

### 1. PackageNotFound.csproj — Nonexistent Package
- **Issue**: Project references a package `Nonexistent.Package.That.Does.Not.Exist` which does not exist on any configured NuGet feed
- **Error code**: NU1101 (package not found)
- **Solution**: Remove or replace the nonexistent package reference with a valid package

### 2. VersionDowngrade.csproj — Package Downgrade
- **Issue**: Project references `Microsoft.Extensions.Logging` 8.0.0 which depends on `Microsoft.Extensions.DependencyInjection.Abstractions` >= 8.0.0, but a direct reference pins it to 6.0.0
- **Error code**: NU1605 (package downgrade detected)
- **Solution**: Upgrade the direct PackageReference for `Microsoft.Extensions.DependencyInjection.Abstractions` to 8.0.0 or higher to match the transitive dependency requirement

## Key Concepts That Should Be Mentioned
- NU1101 and NuGet feed configuration
- NU1605 package downgrade / diamond dependency resolution
- Transitive vs direct package references
- NuGet version resolution (nearest-wins rule)
