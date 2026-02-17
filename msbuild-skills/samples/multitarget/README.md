# Multi-targeting & TFM Issues

Demonstrates TFM-specific build issues in a multi-targeting project.

## Issues Demonstrated

- `ReadOnlySpan<byte>` usage fails on `netstandard2.0` and `net472` without `System.Memory` package
- Conditional compilation patterns for platform-specific APIs
- Different API availability across TFMs

## Skills Tested

- `multitarget-tfm-issues` — TFM compatibility, conditional compilation
- `common-build-errors` — CS0246 on specific TFMs

## How to Test

```bash
dotnet build MultiTargetLib.csproj   # Fails on netstandard2.0 and net472
```

## Expected Fix

Add conditional PackageReference for older TFMs:
```xml
<ItemGroup Condition="'$(TargetFramework)' == 'netstandard2.0' or '$(TargetFramework)' == 'net472'">
  <PackageReference Include="System.Memory" Version="4.5.5" />
</ItemGroup>
```
