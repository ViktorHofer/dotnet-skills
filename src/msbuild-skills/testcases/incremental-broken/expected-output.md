# Expected Findings: incremental-broken

## Problem Summary
A .NET project with two custom MSBuild targets (`GenerateTimestamp` and `EmbedGitHash`) that break incremental builds — they run on every build even when nothing has changed, due to missing `Inputs`/`Outputs` attributes and volatile data patterns.

## Expected Findings

### 1. GenerateTimestamp Target Missing Inputs/Outputs
- **Issue**: The `GenerateTimestamp` target has no `Inputs` or `Outputs` attributes. Without both, MSBuild cannot determine if the target is up-to-date and runs it unconditionally every build.
- **Solution**: Add `Inputs="$(MSBuildProjectFile)"` (so it reruns when the project file changes) and `Outputs="$(IntermediateOutputPath)build-timestamp.txt"` (so MSBuild can check if the output already exists and is newer than input).

### 2. Volatile Data in GenerateTimestamp (DateTime.Now)
- **Issue**: Even with correct `Inputs`/`Outputs`, the target writes `DateTime.Now` into the file. This means the file's **content** changes every build. While MSBuild's incremental check is timestamp-based (not content-based), this volatile data pattern is a design smell — if any downstream target hashes file contents rather than checking timestamps, it will always see a change.
- **Solution**: Use a stable value (e.g., project file modification time) instead of `DateTime.Now`, or accept that the timestamp file is a one-time generation artifact tied to the project file.

### 3. EmbedGitHash Target Missing Inputs/Outputs
- **Issue**: The `EmbedGitHash` target also lacks `Inputs`/`Outputs`, causing it to run `git rev-parse HEAD` on every build. The `Exec` command runs unconditionally, adding I/O overhead.
- **Solution**: Add `Inputs="$(MSBuildProjectFile);.git\HEAD;.git\refs\heads\**"` (so it re-runs only when HEAD changes) and `Outputs="$(IntermediateOutputPath)git-hash.g.cs"`.

### 4. Generated Files Not Registered in FileWrites
- **Issue**: Both targets generate files (`build-timestamp.txt`, `git-hash.g.cs`) but neither registers them in the `<FileWrites>` item group. This means `dotnet clean` won't remove these files, causing stale artifacts to persist across cleans.
- **Solution**: Add `<FileWrites Include="..." />` inside each target for every file it creates.

### 5. Binlog-Based Diagnosis Approach
- **Issue**: To verify the fix, build twice with binlogs (`/bl:first.binlog`, `/bl:second.binlog`) and check the second binlog — the targets should show as "skipped" with the message "Skipping target because all output files are up-to-date."
- **Technique**: Search the second binlog for "is newer than output" messages to find the specific input that triggered the rebuild. Use `get_project_target_times` to compare target durations between first and second builds.

## Key Concepts That Should Be Mentioned
- MSBuild timestamp-based up-to-date checking (file last-write-time comparison, not content hashing)
- `Inputs`/`Outputs` contract: without **both**, target always runs
- `FileWrites` item group for `dotnet clean` support
- Building twice with binlogs to verify incrementality
- Volatile data (`DateTime.Now`) as a design smell in build-generated content
- `.git/HEAD` and `.git/refs/heads/**` as natural Inputs for git-hash targets
- `$(IntermediateOutputPath)` as the correct location for generated build artifacts

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified both GenerateTimestamp AND EmbedGitHash targets as missing Inputs/Outputs
- [ ] Explained that without both Inputs and Outputs, MSBuild runs the target every build
- [ ] Explained MSBuild's timestamp-based (not content-based) up-to-date checking mechanism
- [ ] Suggested specific Inputs values (e.g., $(MSBuildProjectFile), .git/HEAD for EmbedGitHash)
- [ ] Suggested Outputs referencing $(IntermediateOutputPath) for generated files
- [ ] Identified DateTime.Now as volatile data that changes on every build
- [ ] Identified generated files not registered in FileWrites item group
- [ ] Explained FileWrites is needed for dotnet clean support
- [ ] Provided correct XML fix pattern with Inputs, Outputs, and FileWrites all together
- [ ] Discussed broader incremental build verification strategy (build twice, check skipped targets, or use /clp:PerformanceSummary)

Total: __/10

## Expected Skills
- incremental-build
