# Domain Check — Mixed Project Types

A directory containing both .NET and non-.NET project files for testing domain gating.

## Files Present

| File | Type | MSBuild Relevant? |
|------|------|-------------------|
| `DotNetLib.csproj` | .NET SDK project | ✅ Yes |
| `package.json` | Node.js/npm | ❌ No |
| `Makefile` | Make/C | ❌ No |
| `Cargo.toml` | Rust/Cargo | ❌ No |

## Skills Tested

- `msbuild-domain-check` — Should correctly identify .csproj as MSBuild-relevant
  and NOT activate for package.json, Makefile, or Cargo.toml build issues

## How to Test

1. Ask about a "build failure" in this directory — AI should check domain relevance
2. Ask about "npm install failing" — AI should NOT activate MSBuild skills
3. Ask about "dotnet build failing" — AI SHOULD activate MSBuild skills
