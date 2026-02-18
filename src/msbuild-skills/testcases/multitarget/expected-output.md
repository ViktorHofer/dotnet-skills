# Expected Findings: multitarget

## Problem Summary
A multi-targeting library (net8.0, netstandard2.0, net472) fails to build on older TFMs because it uses `Span<T>`, which is not available without a polyfill package.

## Expected Findings

### 1. Missing Polyfill for Span<T>
- **Issue**: The project targets net8.0, netstandard2.0, and net472. Code uses `Span<T>` which is built-in on net8.0 but NOT available on netstandard2.0 or net472 without the `System.Memory` NuGet package.
- **Error code**: CS0246 (type or namespace 'Span' could not be found) on netstandard2.0 and net472
- **Solution**: Add a conditional `<PackageReference Include="System.Memory">` for non-net8.0 TFMs, or use `#if` preprocessor directives to conditionally use Span<T>

## Expected Fix Pattern
```xml
<ItemGroup Condition="!$([MSBuild]::IsTargetFrameworkCompatible('$(TargetFramework)', 'net8.0'))">
  <PackageReference Include="System.Memory" Version="4.5.5" />
</ItemGroup>
```
Or simpler:
```xml
<ItemGroup Condition="'$(TargetFramework)' == 'netstandard2.0' or '$(TargetFramework)' == 'net472'">
  <PackageReference Include="System.Memory" Version="4.5.5" />
</ItemGroup>
```

## Key Concepts That Should Be Mentioned
- Multi-targeting with TargetFrameworks (plural)
- API availability differences across TFMs
- Polyfill packages (System.Memory for Span<T>)
- Conditional PackageReference based on TargetFramework
- MSBuild condition syntax for TFM-specific logic

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified project multi-targets net8.0, netstandard2.0, and net472
- [ ] Identified Span<T> usage as the source of build failure
- [ ] Explained Span<T> is built-in on net8.0 but not on older TFMs
- [ ] Identified CS0246 error on netstandard2.0 and net472
- [ ] Suggested System.Memory NuGet package as polyfill
- [ ] Provided conditional PackageReference XML
- [ ] Used correct MSBuild condition syntax for TFM-specific logic
- [ ] Condition correctly targets only non-net8.0 TFMs
- [ ] Mentioned alternative approach (#if preprocessor directives)
- [ ] Solution would actually fix the multi-target build

Total: __/10

## Expected Skills
- multitarget-tfm-issues
- binlog-generation
