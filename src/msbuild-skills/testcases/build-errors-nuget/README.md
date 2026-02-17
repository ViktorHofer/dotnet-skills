# Build Errors: NuGet (NU) Errors

Sample projects demonstrating common NuGet restore failures.

## Projects

| Project | Errors Demonstrated | Skills Tested |
|---------|-------------------|---------------|
| `PackageNotFound` | NU1101 (package not found) | `common-build-errors`, `nuget-restore-failures` |
| `VersionDowngrade` | NU1605 (package downgrade) | `common-build-errors`, `nuget-restore-failures` |

## How to Test

```bash
dotnet build PackageNotFound.csproj    # Should fail with NU1101
dotnet build VersionDowngrade.csproj   # Should warn/fail with NU1605
```
