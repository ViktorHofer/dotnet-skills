# Expected Findings: legacy-project

## Problem Summary
A non-SDK-style (legacy) .NET project with ~48 lines of verbose XML that should be modernized to SDK-style format (~6 lines).

## Expected Findings

### 1. Non-SDK-Style Project Format
- **Issue**: Project uses legacy format with `<Import Project="$(MSBuildExtensionsPath)\..."`, explicit `<Compile Include>` items, framework `<Reference>` entries, `ProjectGuid`, separate `AssemblyInfo.cs`, Debug/Release PropertyGroups
- **Solution**: Migrate to SDK-style `<Project Sdk="Microsoft.NET.Sdk">` format

### 2. Explicit File Includes
- **Issue**: Every .cs file is listed with `<Compile Include="...">`
- **Solution**: Remove — SDK-style projects use implicit globbing

### 3. Framework References
- **Issue**: Explicit `<Reference Include="System">`, `System.Core`, etc.
- **Solution**: Remove — SDK handles standard framework references

### 4. Separate AssemblyInfo.cs
- **Issue**: Assembly attributes in `Properties/AssemblyInfo.cs`
- **Solution**: Move relevant attributes to .csproj properties (or let SDK auto-generate them) and delete AssemblyInfo.cs

### 5. Redundant Debug/Release Configurations
- **Issue**: Separate PropertyGroups for Debug and Release with boilerplate
- **Solution**: Remove — SDK provides sensible defaults

### 6. MSBuild Import Statements
- **Issue**: Explicit `<Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />`
- **Solution**: Remove — `Sdk` attribute handles imports

## Expected Modernized Result
The modernized .csproj should be approximately 6 lines:
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <RootNamespace>LegacyApp</RootNamespace>
  </PropertyGroup>
</Project>
```

## Key Concepts That Should Be Mentioned
- SDK-style vs non-SDK-style project format
- Implicit file globbing in SDK-style projects
- MSBuild `Sdk` attribute replacing explicit imports
- Auto-generated AssemblyInfo
- Default Debug/Release configurations in SDK projects

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified project as non-SDK-style (legacy format)
- [ ] Suggested migration to SDK-style Project Sdk="Microsoft.NET.Sdk"
- [ ] Identified explicit Compile Include items as unnecessary
- [ ] Explained SDK-style implicit globbing replaces explicit includes
- [ ] Identified framework Reference elements as removable
- [ ] Identified AssemblyInfo.cs as replaceable by SDK auto-generation
- [ ] Identified redundant Debug/Release PropertyGroups
- [ ] Identified explicit MSBuild Import statements as unnecessary
- [ ] Provided a modernized .csproj example (roughly correct structure)
- [ ] Mentioned that modernized project should be ~6 lines vs ~48

Total: __/10

## Expected Skills
- msbuild-modernization
