# Expected Findings: multitarget

## Problem Summary
A multi-targeting library (net8.0, netstandard2.0, net472) fails to build on older TFMs because it uses `ReadOnlySpan<byte>` / `Span<T>`, which require the `System.Memory` polyfill package on non-net8.0 TFMs.

## Expected Findings

### Finding 1: Missing Polyfill for Span<T> on Older TFMs
- **Issue**: `ReadOnlySpan<byte>` in `ProcessData` method is built-in on net8.0 but NOT available on netstandard2.0 or net472 without `System.Memory`
- **Error**: CS0246 on netstandard2.0 and net472
- **Fix**: Add conditional `<PackageReference Include="System.Memory">` for TFMs that lack it

## Expected Fix Patterns
Preferred (using MSBuild function):
```xml
<ItemGroup Condition="!$([MSBuild]::IsTargetFrameworkCompatible('$(TargetFramework)', 'net8.0'))">
  <PackageReference Include="System.Memory" Version="4.5.5" />
</ItemGroup>
```
Alternative (explicit TFM listing):
```xml
<ItemGroup Condition="'$(TargetFramework)' == 'netstandard2.0' or '$(TargetFramework)' == 'net472'">
  <PackageReference Include="System.Memory" Version="4.5.5" />
</ItemGroup>
```

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

1. [ ] Identified project multi-targets net8.0, netstandard2.0, and net472
2. [ ] Identified `ReadOnlySpan<byte>` (or `Span<T>`) as the source of build failure on older TFMs
3. [ ] Explained `Span<T>` is built-in on net8.0 but requires a polyfill on netstandard2.0 and net472
4. [ ] Identified CS0246 error specifically on netstandard2.0 and net472 (not net8.0)
5. [ ] Suggested `System.Memory` NuGet package as the polyfill (correct package name)
6. [ ] Provided conditional PackageReference XML with MSBuild condition
7. [ ] Used `$([MSBuild]::IsTargetFrameworkCompatible())` function or equivalent robust condition syntax (not a fragile string match)
8. [ ] Condition correctly excludes net8.0 (where Span<T> is built-in) and includes both netstandard2.0 AND net472
9. [ ] Mentioned `#if` preprocessor directives as an alternative approach (e.g., `#if NET8_0_OR_GREATER`, `NETSTANDARD2_0`, `NETFRAMEWORK`)
10. [ ] Solution would actually fix the multi-target build (correct package, correct condition, correct TFMs)

Total: __/10

## Expected Skills
- multitarget-tfm-issues
- binlog-generation
