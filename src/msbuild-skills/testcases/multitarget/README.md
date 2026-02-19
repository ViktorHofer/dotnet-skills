# Multi-targeting & TFM Issues

Demonstrates TFM-specific build issues in a multi-targeting project.

## Issues (Surface Level)

### 1. Missing Span<T> Polyfill
- `ReadOnlySpan<byte>` usage fails on `netstandard2.0` and `net472` without `System.Memory` package
- CS0246 on older TFMs

## Issues (Subtle / Skill-Specific)

### 2. MSBuild Condition Syntax
- Preferred: `$([MSBuild]::IsTargetFrameworkCompatible())` function (robust, future-proof)
- Alternative: Explicit TFM listing with `Or` conditions
- The skill teaches both patterns; base LLMs often only use the explicit form

### 3. Preprocessor Symbol Names
- Correct: `NET8_0_OR_GREATER`, `NETSTANDARD2_0`, `NETFRAMEWORK`
- Wrong: `NET8.0_OR_GREATER`, `NET80_OR_GREATER`

## Skills Tested

- `multitarget-tfm-issues` — TFM compatibility, conditional compilation, polyfill packages

## How to Test

```bash
dotnet build MultiTargetLib.csproj   # Fails on netstandard2.0 and net472
```
