# Expected Findings: bin-obj-clash Scenario

## Problem Summary
This solution demonstrates MSBuild output path and intermediate output path clashes that cause build failures.

## Expected Findings

### 1. MultiTargetLib - Multi-targeting Clash
- **Issue**: Project multi-targets net8.0 and net9.0 but has `AppendTargetFrameworkToOutputPath=false`
- **Impact**: Both target frameworks write to the same output directory
- **Solution**: Remove `AppendTargetFrameworkToOutputPath=false` or ensure output paths are unique per target framework

### 2. LibraryA & LibraryB - Shared Output Path Clash
- **Issue**: Both projects share `../SharedOutput/` as their output path
- **Impact**: Build artifacts overwrite each other during parallel builds
- **Solution**: Give each project a unique output path

### 3. LibraryA & LibraryB - Shared Intermediate Path Clash
- **Issue**: Both projects share `../SharedObj/` as their intermediate output path
- **Impact**: `project.assets.json` and generated files conflict
- **Error**: "Cannot create a file when that file already exists" during NuGet restore
- **Solution**: Give each project a unique intermediate output path

## Key Concepts That Should Be Mentioned
- IntermediateOutputPath
- OutputPath
- AppendTargetFrameworkToOutputPath
- BaseIntermediateOutputPath
- Multi-targeting
- project.assets.json
- Parallel build conflicts

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified MultiTargetLib has AppendTargetFrameworkToOutputPath=false causing clash
- [ ] Explained that net8.0 and net9.0 write to the same output directory
- [ ] Suggested removing AppendTargetFrameworkToOutputPath=false or using unique output paths
- [ ] Identified LibraryA & LibraryB share ../SharedOutput/ as OutputPath
- [ ] Explained build artifacts overwrite each other during parallel builds
- [ ] Suggested giving each project a unique output path
- [ ] Identified LibraryA & LibraryB share ../SharedObj/ as IntermediateOutputPath
- [ ] Mentioned project.assets.json conflict from shared intermediate path
- [ ] Suggested giving each project a unique intermediate output path
- [ ] Referenced BaseIntermediateOutputPath vs IntermediateOutputPath concepts

Total: __/10

## Expected Skills
- check-bin-obj-clash
