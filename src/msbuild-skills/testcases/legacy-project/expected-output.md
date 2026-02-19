# Expected Findings: legacy-project

## Problem Summary
A non-SDK-style (legacy) .NET project with ~60 lines of verbose XML, `packages.config`, and `AssemblyInfo.cs` that should be modernized to SDK-style format (~10 lines).

## Expected Findings

### Finding 1: Non-SDK-Style Project Format
- Explicit `<Import>` statements, `ToolsVersion`, `xmlns` attribute
- **Fix**: Replace with `<Project Sdk="Microsoft.NET.Sdk">`

### Finding 2: TFM Migration
- Uses `<TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>` (legacy property name)
- **Fix**: Map to `<TargetFramework>net472</TargetFramework>` — preserving the original framework, NOT upgrading to net8.0

### Finding 3: Explicit File Includes
- `<Compile Include="Calculator.cs" />` etc. listed individually
- **Fix**: Remove — SDK-style uses implicit globbing

### Finding 4: packages.config → PackageReference
- `packages.config` with Newtonsoft.Json and Serilog, plus `<Reference>` elements with `<HintPath>`
- **Fix**: Migrate to `<PackageReference Include="..." Version="..." />` and delete packages.config

### Finding 5: AssemblyInfo.cs
- `Properties/AssemblyInfo.cs` with assembly attributes
- **Fix**: Move to csproj properties or set `<GenerateAssemblyInfo>false</GenerateAssemblyInfo>` to keep the file

### Finding 6: Boilerplate Removal
- Debug/Release PropertyGroups, framework References, ProjectGuid, FileAlignment, etc.
- **Fix**: Delete — SDK provides defaults

## Expected Modernized Result
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net472</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
    <PackageReference Include="Serilog" Version="3.1.1" />
  </ItemGroup>
</Project>
```

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

1. [ ] Identified project as non-SDK-style and recommended `<Project Sdk="Microsoft.NET.Sdk">`
2. [ ] Correctly mapped `TargetFrameworkVersion v4.7.2` to `TargetFramework net472` (NOT net8.0 — preserving original framework)
3. [ ] Identified explicit Compile Include items as unnecessary due to SDK implicit globbing
4. [ ] Identified `packages.config` and recommended migration to `<PackageReference>` format
5. [ ] Provided correct PackageReference XML for both Newtonsoft.Json and Serilog (with versions)
6. [ ] Identified AssemblyInfo.cs as replaceable by SDK auto-generation (or mentioned `GenerateAssemblyInfo` property)
7. [ ] Identified HintPath references and framework Reference elements as removable
8. [ ] Identified Debug/Release PropertyGroups and other boilerplate (ProjectGuid, FileAlignment) as removable
9. [ ] Provided a complete modernized .csproj example that would work correctly
10. [ ] Mentioned `try-convert` or .NET Upgrade Assistant as migration tools, or explained binding redirect changes

Total: __/10

## Expected Skills
- msbuild-modernization
