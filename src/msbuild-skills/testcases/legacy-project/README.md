# Legacy Project — Modernization Test

A deliberately legacy (non-SDK-style) project for testing the `msbuild-modernization` skill.

## Issues (Surface Level)

- Non-SDK-style project format (verbose XML with explicit Imports)
- Explicit `<Compile Include>` for every file
- `<Reference>` for framework assemblies
- Redundant Debug/Release PropertyGroups
- Legacy boilerplate: ProjectGuid, FileAlignment, etc.

## Issues (Subtle / Skill-Specific)

### TFM Mapping Trap
- Project uses `TargetFrameworkVersion v4.7.2` — correct migration preserves as `net472`
- A common mistake is suggesting `net8.0` which changes the target framework (breaking change)
- The skill explicitly provides a TFM mapping table: v4.7.2 → net472

### packages.config Migration
- `packages.config` with Newtonsoft.Json and Serilog must migrate to `<PackageReference>`
- HintPath references must be removed

### AssemblyInfo.cs Handling
- `GenerateAssemblyInfo` property as alternative to deleting AssemblyInfo.cs

### Migration Tools
- `try-convert` and .NET Upgrade Assistant — recommended by the skill

## Skills Tested

- `msbuild-modernization` — Legacy → SDK-style migration, TFM mapping, packages.config
