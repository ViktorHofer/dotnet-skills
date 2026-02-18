# Style Issues — Code Review Test

A solution with two projects and build infrastructure (Directory.Build.props, Directory.Build.targets) containing both surface-level and subtle MSBuild anti-patterns for testing the `msbuild-code-review` agent.

## Issues Present

### Surface-level (vanilla LLMs typically find these)
1. **Hardcoded absolute paths** for OutputPath (`C:\builds\output\...`)
2. **Unquoted condition** (`$(Configuration) == Debug` should be `'$(Configuration)' == 'Debug'`)
3. **Explicit Compile includes** in SDK-style project (SDK handles this automatically)
4. **`<Reference>` with HintPath** instead of `<PackageReference>`

### Subtle (require MSBuild expertise from skills)
5. **Property defaults in .targets** — `TreatWarningsAsErrors`, `Company`, etc. set in `.targets` where projects can't override them (should be in `.props` with condition guards)
6. **LibB override silently ignored** — LibB sets `TreatWarningsAsErrors=false` but `.targets` overrides it back to `true`
7. **TargetFramework condition in .props** — `$(TargetFramework)` is empty during `.props` evaluation for single-TFM projects, so the condition silently fails
8. **DefineConstants overwrites** — `<DefineConstants>ENABLE_LOGGING</DefineConstants>` replaces all existing constants (TRACE, DEBUG) instead of appending
9. **Analyzer without PrivateAssets** — `StyleCop.Analyzers` in `.props` leaks to downstream consumers
10. **`<Exec>` for echo** — Should use `<Message>` task, not shell command

## Skills Tested

- `msbuild-style-guide` — Style violations and anti-patterns
- `directory-build-organization` — .props vs .targets evaluation order, TargetFramework availability
- `msbuild-antipatterns` — DefineConstants overwrite, PrivateAssets
- `msbuild-code-review` agent — Full automated review

## How to Test

Ask the AI: "Review all MSBuild project files and build infrastructure in this solution for best practices and potential issues."
