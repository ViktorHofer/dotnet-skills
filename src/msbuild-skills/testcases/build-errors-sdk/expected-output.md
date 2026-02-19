# Expected Findings: build-errors-sdk

## Problem Summary
A .NET project fails to build due to a two-layer SDK resolution failure: first, `global.json` pins a nonexistent SDK with `rollForward: "disable"`, and second, the project targets a nonexistent TFM (`net99.0`).

## Expected Findings

### Finding 1: global.json — SDK Version Pinning Failure (NETSDK1141)
- `global.json` pins SDK version `99.0.100` with `rollForward: "disable"`
- `disable` means exact match only — no rolling forward allowed
- Since SDK 99.0.100 doesn't exist, resolution fails immediately

### Finding 2: Invalid Target Framework (NETSDK1045)  
- Even after fixing global.json, the project targets `net99.0` which is not a valid TFM
- The installed SDK doesn't support this target framework

### Finding 3: Two-Layer Failure Pattern
- Layer 1 (SDK resolution) must be fixed before Layer 2 (TFM) is even reached
- This is a common confusing pattern — the first error masks the second

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

1. [ ] Identified `global.json` pins SDK version `99.0.100` that doesn't exist
2. [ ] Identified `rollForward: "disable"` as too restrictive (exact match only, no fallback)
3. [ ] Mentioned NETSDK1141 error code by name
4. [ ] Suggested fixing global.json: remove it, change SDK version, OR change rollForward policy
5. [ ] Identified `net99.0` as an invalid/unsupported target framework
6. [ ] Mentioned NETSDK1045 error code by name
7. [ ] Suggested changing TargetFramework to a valid TFM (e.g., net8.0 or net9.0)
8. [ ] Explained the two-layer failure: global.json must be fixed first before TFM error surfaces
9. [ ] Named specific rollForward policy alternatives (at least 2 of: `latestFeature`, `latestPatch`, `latestMajor`, `feature`, `patch`)
10. [ ] Explained SDK feature bands (the hundreds digit: 8.0.100 vs 8.0.200 vs 8.0.300 are different feature bands) OR recommended a best practice policy (e.g., `latestFeature` for dev, `latestPatch` for CI)

Total: __/10

## Expected Skills
- sdk-workload-resolution
