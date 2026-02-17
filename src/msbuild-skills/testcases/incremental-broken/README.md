# Incremental Build — Broken Scenarios

A project with custom targets that break incremental builds.

## Issues Present

1. **`GenerateTimestamp` target**: No `Inputs`/`Outputs` attributes — runs every build
2. **Volatile data**: Uses `DateTime.Now` which changes every build, forcing recompilation
3. **Missing `FileWrites`**: Generated files not registered for clean
4. **`EmbedGitHash` target**: Runs `git rev-parse` every build, generates a new .cs file each time

## Skills Tested

- `incremental-build` — Diagnosing and fixing broken incremental builds

## How to Test

```bash
# Build twice — second build should be fast but won't be
dotnet build /bl:first.binlog
dotnet build /bl:second.binlog
# In second.binlog, GenerateTimestamp and EmbedGitHash should NOT have run
# but they do because of missing Inputs/Outputs
```

## Expected Fix

```xml
<Target Name="GenerateTimestamp"
        BeforeTargets="CoreCompile"
        Inputs="$(MSBuildProjectFile)"
        Outputs="$(IntermediateOutputPath)build-timestamp.txt">
  <!-- Only re-generates when project file changes -->
  <WriteLinesToFile ... />
  <ItemGroup>
    <FileWrites Include="$(IntermediateOutputPath)build-timestamp.txt" />
  </ItemGroup>
</Target>
```
