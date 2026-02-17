# Generated Files — Inclusion Issues

A project that generates a .cs file during build but fails to include it in compilation.

## Issue

The `GenerateVersionFile` target creates `Version.g.cs` in the intermediate output,
but doesn't add it to `<Compile>` items or register it in `<FileWrites>`.

Result: `CS0103: The name 'VersionInfo' does not exist in the current context`

## Skills Tested

- `including-generated-files` — How to properly include build-generated files

## How to Test

```bash
dotnet build GeneratedFiles.csproj   # Fails with CS0103
```

## Expected Fix

Add to the target:
```xml
<ItemGroup>
  <Compile Include="$(VersionFile)" />
  <FileWrites Include="$(VersionFile)" />
</ItemGroup>
```
