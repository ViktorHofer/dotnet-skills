# Build Errors: SDK/Workload (NETSDK) Errors

Sample projects demonstrating SDK resolution failures with a two-layer error pattern.

## Issues (Surface Level)

### 1. NETSDK1141 — SDK Version Not Found
- `global.json` pins to nonexistent SDK `99.0.100` with `rollForward: "disable"`
- Build can't even start

### 2. NETSDK1045 — Invalid Target Framework
- Project targets `net99.0` which no installed SDK supports
- Only visible after fixing global.json

## Issues (Subtle / Skill-Specific)

### 3. rollForward Policy Knowledge
- The skill provides a complete table of 9 rollForward policies
- `latestFeature` recommended for dev, `latestPatch` for CI locked environments

### 4. Feature Band Understanding
- SDK versioning: `8.0.100` vs `8.0.200` vs `8.0.300` are different feature bands
- `rollForward: "patch"` stays within a feature band; `"feature"` crosses them

## Skills Tested

- `sdk-workload-resolution` — rollForward policies, feature bands, SDK resolution algorithm
