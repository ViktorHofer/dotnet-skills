# Build Errors: C# Compiler (CS) Errors

Sample projects that intentionally produce common C# compiler errors.

## Projects

| Project | Errors Demonstrated | Skills Tested |
|---------|-------------------|---------------|
| `MissingReference` | CS0246 (type not found) | `common-build-errors` |
| `TypeMismatch` | CS0029 (type conversion), CS8600 (nullable) | `common-build-errors` |

## How to Test

```bash
# Each project should fail with specific CS errors
dotnet build MissingReference.csproj
dotnet build TypeMismatch.csproj
```

## Expected Behavior

When the AI encounters these build failures, it should:
1. Recognize the CS error codes
2. Consult the `common-build-errors` skill
3. Suggest the correct fix (add PackageReference, fix type conversion, etc.)
