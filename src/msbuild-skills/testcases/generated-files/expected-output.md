# Expected Findings: generated-file-include Scenario

## Problem Summary
This project generates a C# source file during the build (via an MSBuild inline task) and attempts to include it via a project-level glob, but the build fails with CS0103 because the glob is evaluated before the file exists.

## Root Cause
The project has `<Compile Include="$(IntermediateOutputPath)Generated\**\*.cs" />` at the project level (outside of any target). This glob is expanded during MSBuild's **evaluation phase**, before any targets execute. Since the `GenerateSampleCode` target creates the file during the **execution phase**, the glob finds nothing — the directory and file don't exist yet.

## Expected Fix
Move the `<Compile Include>` from the project level into the `GenerateSampleCode` target (after the file is written), and add `FileWrites` for clean support:

```xml
<ItemGroup>
  <Compile Include="$(_GeneratedFilePath)" />
  <FileWrites Include="$(_GeneratedFilePath)" />
</ItemGroup>
```

The project-level `<Compile Include="$(IntermediateOutputPath)Generated\**\*.cs" />` should be removed — it has no effect and is misleading.

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

1. [ ] Identified that the project-level Compile glob doesn't capture the generated file
2. [ ] Explained WHY: globs outside targets are expanded during evaluation phase, before the file exists
3. [ ] Explained evaluation phase vs execution phase distinction clearly
4. [ ] Recommended moving the Compile Include INSIDE the GenerateSampleCode target (after file generation)
5. [ ] Recommended adding FileWrites for proper `dotnet clean` support
6. [ ] Provided correct XML fix with both Compile and FileWrites inside the target
7. [ ] Mentioned or used `$(IntermediateOutputPath)` as the correct base directory for generated files (not hardcoded `obj\`)
8. [ ] Explained that `BeforeTargets="CoreCompile;BeforeCompile"` is the correct target timing for generated source files (both targets, not just one)
9. [ ] Explained that project-level includes (outside targets) cannot work for files that don't exist at evaluation time — the include must be inside a target
10. [ ] Solution would actually fix the CS0103 build error

Total: __/10

## Expected Skills
- including-generated-files
- binlog-generation
- binlog-failure-analysis
