# Expected Findings: bin-obj-clash Scenario

## Problem Summary
This solution demonstrates MSBuild output path and intermediate output path clashes that cause build failures during parallel builds and NuGet restore.

## Expected Findings

### Finding 1: MultiTargetLib Multi-targeting Clash
- **Issue**: Project uses `TargetFrameworks=net8.0;net9.0` but `AppendTargetFrameworkToOutputPath=false` and `AppendTargetFrameworkToIntermediateOutputPath=false`, causing both TFMs to write to the same directories
- **Fix**: Remove the `AppendTargetFramework*=false` settings (let SDK defaults append TFM to paths)

### Finding 2: LibraryA & LibraryB Shared BaseOutputPath
- **Issue**: Both projects set `BaseOutputPath=..\SharedOutput\` directing final build artifacts to the same directory
- **Fix**: Give each project a unique output directory (or use default SDK paths)

### Finding 3: LibraryA & LibraryB Shared BaseIntermediateOutputPath  
- **Issue**: Both projects set `BaseIntermediateOutputPath=..\SharedObj\` — this causes `project.assets.json` clashes during NuGet restore
- **Critical detail**: Even re-enabling `AppendTargetFrameworkToIntermediateOutputPath=true` would NOT fully fix this, because NuGet writes `project.assets.json` directly to `BaseIntermediateOutputPath` without the TFM subfolder
- **Fix**: Each project MUST have a unique `BaseIntermediateOutputPath` — the only reliable fix is per-project intermediate directories

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

1. [ ] Identified MultiTargetLib multi-targeting clash from `AppendTargetFrameworkToOutputPath=false` with `TargetFrameworks`
2. [ ] Explained both net8.0 and net9.0 write to same output AND intermediate directories
3. [ ] Identified LibraryA & LibraryB share `../SharedOutput/` as BaseOutputPath causing output clash
4. [ ] Identified LibraryA & LibraryB share `../SharedObj/` as BaseIntermediateOutputPath causing intermediate clash
5. [ ] Mentioned `project.assets.json` as the specific file that conflicts during parallel NuGet restore
6. [ ] Explained WHY shared BaseIntermediateOutputPath is especially problematic — `project.assets.json` is written without TFM subfolder, so `AppendTargetFrameworkToIntermediateOutputPath` cannot fix it
7. [ ] Recommended per-project unique BaseIntermediateOutputPath as the fix (not just re-enabling AppendTargetFramework)
8. [ ] Recommended removing `AppendTargetFrameworkToOutputPath=false` for MultiTargetLib (or suggested SDK defaults)
9. [ ] Used binlog analysis or systematic path comparison to detect clashes (vs only reading csproj by inspection)
10. [ ] Explained parallel build as the trigger — these clashes manifest during concurrent builds when multiple projects/TFMs write simultaneously

Total: __/10

## Expected Skills
- check-bin-obj-clash
- binlog-generation
