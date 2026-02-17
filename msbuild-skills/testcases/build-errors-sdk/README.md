# Build Errors: SDK/Workload (NETSDK) Errors

Sample projects demonstrating SDK resolution failures.

## Projects

| Project | Errors Demonstrated | Skills Tested |
|---------|-------------------|---------------|
| `SdkMismatch` | NETSDK1045 (SDK too old for TFM) | `common-build-errors`, `sdk-workload-resolution` |
| `global.json` | NETSDK1141 (SDK version not found) | `sdk-workload-resolution` |

## How to Test

```bash
# Build with the restrictive global.json — should fail with NETSDK1141
dotnet build SdkMismatch.csproj

# Delete global.json, then build — should fail with NETSDK1045 (net99.0 doesn't exist)
# Remove global.json
dotnet build SdkMismatch.csproj
```

## Expected Behavior

The AI should:
1. Recognize NETSDK error codes
2. Check global.json for SDK pinning
3. Suggest rollForward policy adjustment or SDK installation
