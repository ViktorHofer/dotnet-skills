---
name: msbuild-including-generated-files
description: "Explains how to include files generated during the build into MSBuild's build process. Use when generated files are missing from output, not being compiled, or globs don't capture runtime-generated content."
---

# Including Generated Files Into Your Build

## Overview

Files generated during the build are generally ignored by the build process. This leads to confusing results such as:
- Generated files not being included in the output directory
- Generated source files not being compiled
- Globs not capturing files created during the build

This happens because of how MSBuild's build phases work.

## Why Generated Files Are Ignored

For detailed explanation, see [How MSBuild Builds Projects](https://docs.microsoft.com/visualstudio/msbuild/build-process-overview).

### Evaluation Phase

MSBuild reads your project, imports everything, creates Properties, expands globs for Items **outside of Targets**, and sets up the build process.

### Execution Phase

MSBuild runs Targets & Tasks with the provided Properties & Items to perform the build.

**Key Takeaway:** Files generated during execution don't exist during evaluation, therefore they aren't found. This particularly affects files that are globbed by default, such as source files (`.cs`).

## Solution: Manually Add Generated Files

When files are generated, manually add them into the build process. The recommended approach is adding the new file to the `Content` or `None` items before the `BeforeBuild` target.

### Basic Pattern

```xml
<Target Name="IncludeGeneratedFiles" BeforeTargets="BeforeBuild">
  
  <!-- Your logic that generates files goes here -->
  <!-- Recommendation: Generate files into $(IntermediateOutputPath) -->

  <ItemGroup>
    <!-- If your generated file was placed in obj\ -->
    <None Include="$(IntermediateOutputPath)my-generated-file.xyz" CopyToOutputDirectory="PreserveNewest"/>
    
    <!-- If you know exactly where the file will be -->
    <None Include="some\specific\path\my-generated-file.xyz" CopyToOutputDirectory="PreserveNewest"/>
    
    <!-- Capture all files of a certain type with a glob -->
    <None Include="some\specific\path\*.xyz" CopyToOutputDirectory="PreserveNewest"/>
    <None Include="some\specific\path\*.*" CopyToOutputDirectory="PreserveNewest"/>
  </ItemGroup>
</Target>
```

### For Generated Source Files

If you're generating `.cs` files that need to be compiled:

```xml
<Target Name="IncludeGeneratedSourceFiles" BeforeTargets="BeforeBuild">
  <!-- Generate source files here -->
  
  <ItemGroup>
    <Compile Include="$(IntermediateOutputPath)Generated\*.cs" />
  </ItemGroup>
</Target>
```

## Target Timing

Adding your generated file to `None` or `Content` is sufficient for the build process to see it and copy the files to the output directory. Ensure it gets added at the right time:

- **`BeforeTargets="BeforeBuild"`** - Recommended, runs early enough for most scenarios
- **`BeforeTargets="AssignTargetPaths"`** - The "final stop" before `None` and `Content` items (among others) are transformed into new items

## Globbing Behavior

Globs behave according to **when** the glob took place:

| Glob Location | Files Captured |
|---------------|----------------|
| Outside of a target | Only files visible during Evaluation phase (before build starts) |
| Inside of a target | Files visible when the target runs (can capture generated files if timed correctly) |

This is why the solution places the `<ItemGroup>` inside a `<Target>` - the glob runs during execution when the generated files exist.

## Relevant Links

- [How MSBuild Builds Projects](https://docs.microsoft.com/visualstudio/msbuild/build-process-overview)
- [Evaluation Phase](https://docs.microsoft.com/visualstudio/msbuild/build-process-overview#evaluation-phase)
- [Execution Phase](https://docs.microsoft.com/visualstudio/msbuild/build-process-overview#execution-phase)
- [Common Item Types](https://docs.microsoft.com/visualstudio/msbuild/common-msbuild-project-items)
- [How the SDK imports items by default](https://github.com/dotnet/sdk/blob/main/src/Tasks/Microsoft.NET.Build.Tasks/targets/Microsoft.NET.Sdk.DefaultItems.props)
- [Official docs: Handle generated files](https://learn.microsoft.com/visualstudio/msbuild/customize-your-build#handle-generated-files)
