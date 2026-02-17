# Legacy Project — Modernization Test

A deliberately legacy (non-SDK-style) project for testing the `msbuild-modernization` and `msbuild-style-guide` skills.

## Issues Present

- Non-SDK-style project format (verbose XML with explicit Imports)
- Explicit `<Compile Include>` for every file (SDK does this automatically)
- `<Reference>` for framework assemblies (unnecessary in SDK-style)
- `AssemblyInfo.cs` with properties that should be in .csproj
- Redundant Debug/Release PropertyGroups
- Legacy boilerplate: ProjectGuid, FileAlignment, etc.

## Skills Tested

- `msbuild-modernization` — Legacy → SDK-style migration
- `msbuild-style-guide` — Anti-patterns and best practices

## How to Test

Ask the AI: "Modernize this project to SDK-style format"

## Expected Modernized Result

The ~60-line .csproj should become ~6 lines:
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net472</TargetFramework>
  </PropertyGroup>
</Project>
```
