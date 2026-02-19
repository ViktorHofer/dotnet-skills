# Generated Files — Inclusion Issues

A project that generates a .cs file during build and attempts to include it via a project-level glob, but fails.

## Issues (Surface Level)

### 1. Build Fails with CS0103
- `GenerateSampleCode` target creates `GeneratedInfo.cs` in the intermediate output
- Program.cs references `TestProject.Generated.BuildInfo` which doesn't compile

## Issues (Subtle / Skill-Specific)

### 2. Project-Level Glob Red Herring
- There IS a `<Compile Include="$(IntermediateOutputPath)Generated\**\*.cs" />` at the project level
- It looks like it should capture the generated file, but it doesn't — globs outside targets are expanded during evaluation phase before the file exists
- The skilled response should explain WHY the existing include doesn't work

### 3. Missing FileWrites
- Generated file is not registered in `FileWrites` for proper `dotnet clean` support

### 4. Target Timing Knowledge
- Skill teaches `BeforeTargets="CoreCompile;BeforeCompile"` (both targets) for robust ordering

## Skills Tested

- `including-generated-files` — Evaluation vs execution phase, proper include patterns

## How to Test

```bash
dotnet build TestProject.csproj   # Fails with CS0103
```
