# Expected Findings: build-errors-sdk

## Problem Summary
A .NET project fails to build due to SDK resolution errors caused by global.json pinning and an invalid target framework.

## Expected Findings

### 1. global.json — SDK Version Pinning Failure
- **Issue**: `global.json` pins SDK version `99.0.100` with `rollForward: "disable"`, which prevents any SDK roll-forward. This SDK version does not exist.
- **Error code**: NETSDK1141 (the specified .NET SDK version could not be found)
- **Solution**: Either install the pinned SDK, remove `global.json`, or change `rollForward` to a more permissive policy (e.g., `"latestFeature"`)

### 2. SdkMismatch.csproj — Invalid Target Framework
- **Issue**: Even if global.json is fixed, the project targets `net99.0` which is not a valid/supported TFM
- **Error code**: NETSDK1045 (the current .NET SDK does not support targeting this framework)
- **Solution**: Change `TargetFramework` to a valid, installed TFM (e.g., `net8.0`)

## Key Concepts That Should Be Mentioned
- global.json SDK resolution and rollForward policies
- NETSDK1141 vs NETSDK1045 error distinction
- SDK feature bands and version matching
- Two-layer failure: global.json blocks SDK resolution, then TFM is invalid even after fixing

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified global.json pins SDK version 99.0.100
- [ ] Identified rollForward: "disable" prevents any SDK roll-forward
- [ ] Mentioned NETSDK1141 error code
- [ ] Suggested fixing global.json (remove, update SDK version, or change rollForward)
- [ ] Identified net99.0 as an invalid target framework
- [ ] Mentioned NETSDK1045 error code
- [ ] Suggested changing TargetFramework to a valid TFM
- [ ] Explained the two-layer failure (global.json blocks SDK, then TFM invalid)
- [ ] Mentioned rollForward policy options (latestFeature, latestMajor, etc.)
- [ ] Explained SDK feature bands and version matching

Total: __/10

## Expected Skills
- sdk-workload-resolution
