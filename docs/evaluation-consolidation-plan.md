# Evaluation Consolidation Plan

> **Goal**: Merge the duplicated `evaluation/scenarios/` and `msbuild-skills/testcases/` into a single source of truth. The `testcases/` folder becomes the authoritative test suite for both demos and automated evaluation. The `evaluation/` folder retains only its scripts and README.

---

## Table of Contents

1. [Current State Analysis](#1-current-state-analysis)
2. [Target State](#2-target-state)
3. [Step-by-Step Implementation Plan](#3-step-by-step-implementation-plan)
4. [Per-Testcase Change Details](#4-per-testcase-change-details)
5. [Script Changes](#5-script-changes)
6. [Pipeline (YAML) Changes](#6-pipeline-yaml-changes)
7. [README Updates](#7-readme-updates)
8. [Local Testing Guide](#8-local-testing-guide)
9. [Verification Checklist](#9-verification-checklist)
10. [Risk & Rollback](#10-risk--rollback)

---

## 1. Current State Analysis

### What exists today

| Area | Path | Contents |
|------|------|----------|
| **Evaluation scenarios** | `evaluation/scenarios/<name>/scenario/` | Copies of testcase project files (no comments) |
| **Expected outputs** | `evaluation/scenarios/<name>/expected-output.md` | Grading rubrics |
| **Evaluation scripts** | `evaluation/scripts/*.ps1` | `run-scenario.ps1`, `evaluate-response.ps1`, `generate-summary.ps1`, `parse-copilot-stats.ps1` |
| **Testcases** | `msbuild-skills/testcases/<name>/` | Project files WITH hint-comments + README.md |
| **Pipeline** | `.github/workflows/copilot-skills-evaluation.yml` | Discovers scenarios from `evaluation/scenarios/` |

### Key observations

1. **Duplication**: The `evaluation/scenarios/*/scenario/` files are byte-for-byte copies of the corresponding `testcases/` files (confirmed for `bin-obj-clash` and `generated-file-include`/`generated-files`).
2. **Only 2 of 13 testcases** currently have evaluation scenarios (`bin-obj-clash`, `generated-file-include`). The remaining 11 testcases have no evaluation coverage. After consolidation, 12 of 13 will have automated evaluation (`domain-check` is excluded — see Section 4.13).
3. **Hint-comments are answer keys**: Testcase files contain `<!-- BAD: ... -->`, `// CS0246: ...`, `// Fix: ...` comments that would leak the answer to the AI during evaluation.
4. **READMEs contain full solutions**: Most testcase READMEs have "Expected Fix" code blocks — these must be excluded from the evaluation working directory.
5. **Custom prompts**: `run-scenario.ps1` looks for `prompt.txt` in the working directory for custom prompts. No existing scenario uses this file. The default prompt is: _"Analyze the build issues in this scenario and provide required fixes and their explanations."_
6. **Naming mismatch**: The evaluation scenario `generated-file-include` maps to testcase `generated-files` (different name).

### How the pipeline works today

```
Discover scenarios (evaluation/scenarios/*/scenario/)
    ↓
For each scenario:
    ├── Copy scenario/scenario/ → temp dir
    ├── Vanilla run: Copilot CLI (no plugins) in temp dir → output.txt
    ├── Skilled run: Copilot CLI (with msbuild-skills) in temp dir → output.txt
    └── Evaluate: Compare both outputs against expected-output.md → scores
    ↓
Generate summary table
```

---

## 2. Target State

### New folder structure

```
evaluation/
├── scripts/                      # UNCHANGED — PowerShell scripts
│   ├── run-scenario.ps1          # MODIFIED — reads from testcases/
│   ├── evaluate-response.ps1     # MODIFIED — reads from testcases/
│   ├── parse-copilot-stats.ps1   # UNCHANGED
│   └── generate-summary.ps1      # UNCHANGED
├── results/                      # UNCHANGED — git-ignored
└── README.md                     # MODIFIED — updated paths + instructions

msbuild-skills/testcases/
├── README.md                     # UPDATED — add evaluation column to matrix
├── DEMO.md                       # UNCHANGED
├── bin-obj-clash/
│   ├── expected-output.md        # NEW — moved from evaluation/scenarios/
│   ├── <project files>           # MODIFIED — hint-comments removed
│   └── README.md                 # UNCHANGED (excluded from eval copy)
├── generated-files/
│   ├── expected-output.md        # NEW — adapted from evaluation/scenarios/generated-file-include/
│   ├── <project files>           # UNCHANGED (no hint-comments to remove)
│   └── README.md                 # UNCHANGED (excluded from eval copy)
├── build-errors-cs/
│   ├── expected-output.md        # NEW — authored from skill knowledge
│   ├── eval-test-prompt.txt      # NEW (only if custom prompt needed)
│   ├── <project files>           # MODIFIED — hint-comments removed
│   └── README.md                 # UNCHANGED (excluded from eval copy)
├── ... (all 13 testcases follow this pattern, except domain-check)
└── domain-check/
    ├── <project files>           # UNCHANGED — manual-only testcase
    └── README.md                 # UNCHANGED
    # No expected-output.md — excluded from automated evaluation

.github/workflows/
└── copilot-skills-evaluation.yml # MODIFIED — discovers from testcases/
```

### Conventions

| File | Purpose | Copied to eval temp dir? |
|------|---------|--------------------------|
| `expected-output.md` | Grading rubric for evaluator | ❌ No — read directly |
| `eval-test-prompt.txt` | Custom prompt (overrides default) | ❌ No — read then deleted from temp |
| `README.md` | Human documentation | ❌ No — excluded from eval copy |
| `DEMO.md` | Demo guide | ❌ No — excluded from eval copy |
| `.gitignore` | Git ignore rules | ❌ No — excluded from eval copy |
| Everything else | Test project files | ✅ Yes — copied to temp dir |

---

## 3. Step-by-Step Implementation Plan

### Phase 1: Prepare testcases for evaluation (no script/pipeline changes yet)

| # | Task | Details |
|---|------|---------|
| 1.1 | **Remove hint-comments from testcase files** | Strip `<!-- BAD: ... -->`, `// CS0246: ...`, `// Fix: ...`, `<!-- serial dependency -->`, etc. from all `.csproj`, `.cs`, `.props`, `.targets` files. See [Section 4](#4-per-testcase-change-details) for exact list. |
| 1.2 | **Move `expected-output.md` from `evaluation/scenarios/bin-obj-clash/`** | Copy to `msbuild-skills/testcases/bin-obj-clash/expected-output.md` |
| 1.3 | **Move `expected-output.md` from `evaluation/scenarios/generated-file-include/`** | Copy to `msbuild-skills/testcases/generated-files/expected-output.md` |
| 1.4 | **Create `expected-output.md` for remaining 10 testcases** | Author rubrics based on skill SKILL.md content + testcase README content. `domain-check` is excluded from automated evaluation. See [Section 4](#4-per-testcase-change-details). |
| 1.5 | **Create `eval-test-prompt.txt` where needed** | Only for testcases that need a non-default prompt. See [Section 4](#4-per-testcase-change-details). |

### Phase 2: Update scripts to use testcases

| # | Task | Details |
|---|------|---------|
| 2.1 | **Modify `run-scenario.ps1`** | Change scenario discovery path from `evaluation/scenarios/$ScenarioName/scenario` to `msbuild-skills/testcases/$ScenarioName`. Change prompt file from `prompt.txt` to `eval-test-prompt.txt`. Exclude `README.md`, `DEMO.md`, `.gitignore`, `expected-output.md`, `eval-test-prompt.txt` from temp copy. See [Section 5](#5-script-changes). |
| 2.2 | **Modify `evaluate-response.ps1`** | Change expected-output path from `evaluation/scenarios/$ScenarioName/expected-output.md` to `msbuild-skills/testcases/$ScenarioName/expected-output.md`. See [Section 5](#5-script-changes). |
| 2.3 | **`generate-summary.ps1`** | No changes needed (reads from results dir). |
| 2.4 | **`parse-copilot-stats.ps1`** | No changes needed. |

### Phase 3: Update pipeline

| # | Task | Details |
|---|------|---------|
| 3.1 | **Modify `.github/workflows/copilot-skills-evaluation.yml`** | Change discovery path, add `actions/setup-dotnet@v4` step, update trigger paths. See [Section 6](#6-pipeline-yaml-changes). |

### Phase 4: Cleanup & documentation

| # | Task | Details |
|---|------|---------|
| 4.1 | **Delete `evaluation/scenarios/` directory** | Entire directory tree — all content now lives in testcases. |
| 4.2 | **Update `evaluation/README.md`** | Reflect new folder structure, updated paths, new conventions. See [Section 7](#7-readme-updates). |
| 4.3 | **Update `msbuild-skills/testcases/README.md`** | Add evaluation column, note the `expected-output.md` and `eval-test-prompt.txt` conventions. |
| 4.4 | **Verify end-to-end locally** | See [Section 8](#8-local-testing-guide). |

---

## 4. Per-Testcase Change Details

### 4.1 `bin-obj-clash`

**Skills tested**: `check-bin-obj-clash`

**Hint-comments to remove**: None. The `<!-- Multi-targeting -->` comment in `MultiTargetLib.csproj` is just a property group label, not a problem-identification hint — keep it. The issues are structural (shared paths, disabled appending).

**`expected-output.md`**: Move from `evaluation/scenarios/bin-obj-clash/expected-output.md` as-is.

**`eval-test-prompt.txt`**: Not needed — default prompt ("Analyze the build issues...") works.

---

### 4.2 `build-errors-cs`

**Skills tested**: `common-build-errors`

**Hint-comments to remove** (🔴 critical — these are answer keys):

| File | Line(s) | Comment to remove |
|------|---------|-------------------|
| `MissingReference.cs` | near `JsonSerializer` usage | `// CS0246: The type or namespace name 'JsonSerializer' could not be found` |
| `MissingReference.cs` | near `ILogger` usage | `// CS0246: The type or namespace name 'ILogger' could not be found` |
| `MissingReference.cs` | near `ILogger` | `// Fix: Add <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />` |
| `TypeMismatch.cs` | near `int x = "hello"` | `// CS0029: Cannot implicitly convert type 'string' to 'int'` |
| `TypeMismatch.cs` | near nullable | `// CS8600: Converting null literal to non-nullable type` |

**`expected-output.md`**: Create new. Content:

```markdown
# Expected Findings: build-errors-cs

## Problem Summary
Two .NET projects fail to build due to C# compilation errors.

## Expected Findings

### 1. MissingReference.csproj — Missing Package References
- **Issue**: Code uses `System.Text.Json.JsonSerializer` and `Microsoft.Extensions.Logging.ILogger` without the required NuGet package references
- **Error codes**: CS0246 (type or namespace not found)
- **Solution**: Add `<PackageReference Include="System.Text.Json" />` and `<PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />` to the .csproj

### 2. TypeMismatch.csproj — Type Errors
- **Issue**: Code contains a string-to-int assignment and a null-to-non-nullable assignment
- **Error codes**: CS0029 (cannot implicitly convert type), CS8600 (converting null to non-nullable)
- **Solution**: Fix the type assignments in the source code

## Key Concepts That Should Be Mentioned
- CS0246 error and missing PackageReference as root cause
- CS0029 implicit conversion error
- CS8600 nullable reference type warning/error
- How to add PackageReference to resolve missing types
```

**`eval-test-prompt.txt`**: Not needed — default prompt works.

---

### 4.3 `build-errors-nuget`

**Skills tested**: `common-build-errors`, `nuget-restore-failures`

**Hint-comments to remove**:

| File | Comment to remove |
|------|-------------------|
| `PackageNotFound.csproj` | `<!-- NU1101: Package 'Nonexistent.Package.That.Does.Not.Exist' was not found -->` |
| `VersionDowngrade.csproj` | `<!-- NU1605: Package downgrade detected -->` |
| `VersionDowngrade.csproj` | `<!-- Microsoft.Extensions.Logging 8.0.0 depends on Microsoft.Extensions.DependencyInjection.Abstractions >= 8.0.0 -->` |
| `VersionDowngrade.csproj` | `<!-- But we explicitly request an older version -->` |

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: build-errors-nuget

## Problem Summary
Two .NET projects fail during NuGet restore due to package resolution errors.

## Expected Findings

### 1. PackageNotFound.csproj — Nonexistent Package
- **Issue**: Project references a package `Nonexistent.Package.That.Does.Not.Exist` which does not exist on any configured NuGet feed
- **Error code**: NU1101 (package not found)
- **Solution**: Remove or replace the nonexistent package reference with a valid package

### 2. VersionDowngrade.csproj — Package Downgrade
- **Issue**: Project references `Microsoft.Extensions.Logging` 8.0.0 which depends on `Microsoft.Extensions.DependencyInjection.Abstractions` >= 8.0.0, but a direct reference pins it to 6.0.0
- **Error code**: NU1605 (package downgrade detected)
- **Solution**: Upgrade the direct PackageReference for `Microsoft.Extensions.DependencyInjection.Abstractions` to 8.0.0 or higher to match the transitive dependency requirement

## Key Concepts That Should Be Mentioned
- NU1101 and NuGet feed configuration
- NU1605 package downgrade / diamond dependency resolution
- Transitive vs direct package references
- NuGet version resolution (nearest-wins rule)
```

**`eval-test-prompt.txt`**: Not needed.

---

### 4.4 `build-errors-sdk`

**Skills tested**: `common-build-errors`, `sdk-workload-resolution`

**Hint-comments to remove**:

| File | Comment to remove |
|------|-------------------|
| `SdkNotFound.csproj` | `<!-- NETSDK1045: The current .NET SDK does not support targeting .NET 99.0 -->` |

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: build-errors-sdk

## Problem Summary
A .NET project fails to build due to SDK resolution errors caused by global.json pinning and an invalid target framework.

## Expected Findings

### 1. global.json — SDK Version Pinning Failure
- **Issue**: `global.json` pins SDK version `99.0.100` with `rollForward: "disable"`, which prevents any SDK roll-forward. This SDK version does not exist.
- **Error code**: NETSDK1141 (the specified .NET SDK version could not be found)
- **Solution**: Either install the pinned SDK, remove `global.json`, or change `rollForward` to a more permissive policy (e.g., `"latestFeature"`)

### 2. SdkNotFound.csproj — Invalid Target Framework
- **Issue**: Even if global.json is fixed, the project targets `net99.0` which is not a valid/supported TFM
- **Error code**: NETSDK1045 (the current .NET SDK does not support targeting this framework)
- **Solution**: Change `TargetFramework` to a valid, installed TFM (e.g., `net8.0`)

## Key Concepts That Should Be Mentioned
- global.json SDK resolution and rollForward policies
- NETSDK1141 vs NETSDK1045 error distinction
- SDK feature bands and version matching
- Two-layer failure: global.json blocks SDK resolution, then TFM is invalid even after fixing
```

**`eval-test-prompt.txt`**: Not needed.

---

### 4.5 `multitarget`

**Skills tested**: `multitarget-tfm-issues`

**Hint-comments to remove** (🔴 critical — answer key in code):

| File | Comment to remove |
|------|-------------------|
| `PlatformApi.cs` | `// This will cause CS0246 on netstandard2.0 and net472 because Span<T> is not available` |
| `PlatformApi.cs` | `// without the System.Memory package` |

**`expected-output.md`**: Create new.

```markdown
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
```

**`eval-test-prompt.txt`**: Not needed.

---

### 4.6 `legacy-project`

**Skills tested**: `msbuild-modernization`, `msbuild-style-guide`

**Hint-comments to remove**: None in the .csproj itself — the entire file format IS the problem. No `<!-- BAD -->` comments exist.

**`expected-output.md`**: Create new.

```markdown
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
```

**`eval-test-prompt.txt`**: Create — the default prompt focuses on "build issues", but legacy-project builds successfully. Custom prompt needed:

```
Modernize this project to SDK-style format. Identify all legacy patterns and suggest how to simplify the project file.
```

---

### 4.7 `style-issues`

**Skills tested**: `msbuild-style-guide`, `directory-build-organization`

**Hint-comments to remove** (🔴 critical — heavily commented):

| File | Comments to remove |
|------|--------------------|
| `LibA/LibA.csproj` | `<!-- BAD: Hardcoded absolute path -->` |
| `LibA/LibA.csproj` | `<!-- BAD: Condition not quoted properly on both sides -->` |
| `LibA/LibA.csproj` | `<!-- BAD: Explicit file includes (SDK handles this) -->` |
| `LibA/LibA.csproj` | `<!-- BAD: Using Reference instead of PackageReference -->` |
| `LibA/LibA.csproj` | `<!-- BAD: Exec for something a built-in task could do -->` |
| `LibB/LibB.csproj` | `<!-- BAD: Same properties duplicated from LibA — should be in Directory.Build.props -->` |
| `LibB/LibB.csproj` | `<!-- BAD: Hardcoded absolute path -->` |

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: style-issues

## Problem Summary
A solution with two projects (LibA, LibB) containing multiple MSBuild anti-patterns and style violations.

## Expected Findings

### 1. Hardcoded Absolute Paths
- **Issue**: Both LibA and LibB use hardcoded absolute paths for OutputPath (e.g., `C:\Build\Output\`)
- **Solution**: Use relative paths or MSBuild properties like `$(ArtifactsPath)`

### 2. Unquoted Condition
- **Issue**: MSBuild condition uses unquoted comparison (`$(Configuration) == Debug` instead of `'$(Configuration)' == 'Debug'`)
- **Solution**: Quote both sides of the condition

### 3. Duplicated Properties Across Projects
- **Issue**: LangVersion, Nullable, Company, and other properties are duplicated identically in both LibA.csproj and LibB.csproj
- **Solution**: Extract shared properties into a `Directory.Build.props` file

### 4. Explicit Compile Includes
- **Issue**: Files are listed explicitly with `<Compile Include="...">` in SDK-style project
- **Solution**: Remove — SDK-style projects use implicit globbing

### 5. Reference Instead of PackageReference
- **Issue**: NuGet package referenced using old-style `<Reference>` with `<HintPath>` instead of `<PackageReference>`
- **Solution**: Replace with `<PackageReference Include="..." Version="..." />`

### 6. Exec Instead of Built-in Task
- **Issue**: `<Exec Command="mkdir ...">` used where MSBuild's built-in `<MakeDir>` task would be more appropriate
- **Solution**: Replace with `<MakeDir Directories="..." />`

### 7. No Directory.Build.props
- **Issue**: No centralized build properties file exists for the solution
- **Solution**: Create `Directory.Build.props` with shared settings

## Key Concepts That Should Be Mentioned
- Directory.Build.props for centralized settings
- MSBuild condition quoting rules
- SDK-style implicit globbing
- PackageReference vs Reference
- Built-in MSBuild tasks vs Exec
- Cross-platform path handling
```

**`eval-test-prompt.txt`**: Create — the default prompt focuses on "build issues", but style-issues builds successfully:

```
Review the MSBuild project files in this solution for best practices and anti-patterns. What should be improved?
```

---

### 4.8 `perf-analyzers`

**Skills tested**: `build-perf-diagnostics`, `build-caching`

**Hint-comments to remove**:

| File | Comment to remove |
|------|-------------------|
| `AnalyzerHeavy.csproj` | `<!-- Many analyzers to demonstrate analyzer overhead -->` |

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: perf-analyzers

## Problem Summary
A .NET project with 5 Roslyn analyzer packages causing slow build times due to analyzer overhead.

## Expected Findings

### 1. Excessive Analyzer Overhead
- **Issue**: Project includes 5 analyzer packages (Microsoft.CodeAnalysis.NetAnalyzers, StyleCop.Analyzers, Roslynator.Analyzers, SonarAnalyzer.CSharp, Meziantou.Analyzer) which significantly increase compilation time
- **Evidence**: Analyzer execution time visible in binlog as a large portion of the Csc task duration
- **Solution**: Disable analyzers during development inner loop with `<RunAnalyzers>false</RunAnalyzers>` or `<EnforceCodeStyleInBuild>false</EnforceCodeStyleInBuild>`

## Key Concepts That Should Be Mentioned
- Roslyn analyzer performance impact on build time
- RunAnalyzers property to disable analyzers
- EnforceCodeStyleInBuild property
- Using binlog to measure analyzer time (get_expensive_analyzers)
- Separating CI enforcement from dev inner loop
```

**`eval-test-prompt.txt`**: Create — needs performance-focused prompt:

```
Build this project and analyze its build performance. Identify any bottlenecks.
```

---

### 4.9 `incremental-broken`

**Skills tested**: `incremental-build`

**Hint-comments to remove** (🔴 critical):

| File | Comment to remove |
|------|-------------------|
| `IncrementalBroken.csproj` | `<!-- BAD: Custom target WITHOUT Inputs/Outputs — always runs, breaking incremental build -->` |
| `IncrementalBroken.csproj` | `<!-- BAD: Not registered in FileWrites, so clean won't remove it -->` |
| `IncrementalBroken.csproj` | `<!-- BAD: No Inputs/Outputs, so this target runs every single build -->` |

> **Note**: Only the `GenerateTimestamp` target has `<!-- BAD -->` hint-comments. The second target (`EmbedGitHash`) has no hint-comments and should be left as-is.

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: incremental-broken

## Problem Summary
A .NET project with custom MSBuild targets that break incremental build — they run on every build even when nothing has changed.

## Expected Findings

### 1. Custom Target Missing Inputs/Outputs
- **Issue**: The custom target(s) do not declare `Inputs` and `Outputs` attributes, so MSBuild cannot determine if they are up-to-date and runs them every time
- **Solution**: Add `Inputs` and `Outputs` attributes referencing the source files and generated outputs respectively

### 2. Generated Files Not Registered in FileWrites
- **Issue**: Files generated by custom targets are not added to the `FileWrites` item group, so `dotnet clean` won't remove them
- **Solution**: Add generated files to `<FileWrites Include="..." />` within the target

## Expected Fix Pattern
```xml
<Target Name="CustomTarget"
        Inputs="@(Compile)"
        Outputs="$(IntermediateOutputPath)generated-file.txt"
        BeforeTargets="Build">
  <!-- generation logic -->
  <ItemGroup>
    <FileWrites Include="$(IntermediateOutputPath)generated-file.txt" />
  </ItemGroup>
</Target>
```

## Key Concepts That Should Be Mentioned
- MSBuild Inputs/Outputs for incremental builds
- Timestamp-based up-to-date checking
- FileWrites item group for clean support
- Building twice to verify incrementality (second build should skip the target)
```

**`eval-test-prompt.txt`**: Create — needs incrementality-focused prompt (static analysis — more reliable for automation than asking the AI to build twice):

```
Analyze this project for incremental build issues. Identify any custom targets that would unnecessarily re-run on every build even when nothing has changed.
```

---

### 4.10 `parallel-bottleneck`

**Skills tested**: `build-parallelism`

**Hint-comments to remove** (🟡 moderate):

| File | Comment to remove |
|------|-------------------|
| `Api/Api.csproj` | `<!-- Depends on Core — serial chain link 2 -->` (or similar) |
| `Web/Web.csproj` | `<!-- Depends on Api — serial chain link 3 -->` (or similar) |
| `Tests/Tests.csproj` | `<!-- Depends on Web AND Api — but Web already depends on Api -->` |
| `Tests/Tests.csproj` | `<!-- This means Core→Api→Web→Tests is fully serial, no parallelism possible -->` |

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: parallel-bottleneck

## Problem Summary
A solution with 4 projects forming a deep serial dependency chain (Core→Api→Web→Tests), preventing any build parallelism even with `-m`.

## Expected Findings

### 1. Serial Dependency Chain
- **Issue**: All projects form a single serial chain: Core → Api → Web → Tests. Each project depends on the previous, so MSBuild must build them sequentially even with `/maxcpucount`
- **Impact**: Build parallelism is impossible — only one CPU core is utilized
- **Evidence**: Node timeline in binlog should show sequential execution with idle cores

### 2. Unnecessary Transitive Dependencies
- **Issue**: Tests depends on both Web and Api, but Web already depends on Api, making the explicit Api dependency on Tests redundant (though not harmful). The real issue is whether Tests truly needs to depend on Web, or could depend on Api or Core directly.
- **Solution**: Analyze whether dependency chain can be flattened — e.g., can Tests depend on Core + Api without going through Web?

## Key Concepts That Should Be Mentioned
- MSBuild project dependency graph and topological sort
- /maxcpucount (-m) and parallel scheduling
- Critical path in dependency graph
- Node timeline analysis from binlog
- ProjectReference graph optimization
```

**`eval-test-prompt.txt`**: Create — needs parallelism-focused prompt:

```
Build this solution with parallel build enabled and analyze the build parallelism. Are there any bottlenecks in the dependency graph?
```

---

### 4.11 `eval-heavy`

**Skills tested**: `eval-performance`

**Hint-comments to remove** (🔴 critical):

| File | Comment to remove |
|------|-------------------|
| `EvalHeavy.csproj` | `<!-- BAD: Import chain — multiple levels of imports adding evaluation overhead -->` |
| `EvalHeavy.csproj` | `<!-- BAD: Overly broad glob that would scan everything including node_modules, .git, etc. -->` |
| `EvalHeavy.csproj` | `<!-- In a real repo with node_modules, this glob would be extremely slow -->` |
| `EvalHeavy.csproj` | `<!-- BAD: Property function that reads a file during evaluation -->` |
| `imports/level1.props` | `<!-- BAD: Deeply nested import chain, each level adds evaluation cost -->` |

**`expected-output.md`**: Create new.

```markdown
# Expected Findings: eval-heavy

## Problem Summary
A .NET project with three MSBuild evaluation-phase anti-patterns causing slow project evaluation.

## Expected Findings

### 1. Deep Import Chain
- **Issue**: Project imports `level1.props` which imports `level2.props` which imports `level3.props` — creating a deep import chain that adds evaluation overhead
- **Solution**: Flatten the import chain or reduce unnecessary nesting

### 2. Overly Broad Glob Pattern
- **Issue**: An `<ItemGroup>` uses `**/*.*` or similar broad glob pattern that would scan all directories including node_modules, .git, bin, obj, etc.
- **Solution**: Restrict globs to specific file extensions and directories; use `DefaultItemExcludes` to exclude known-large directories

### 3. Property Function File I/O During Evaluation
- **Issue**: A property uses `$([System.IO.File]::ReadAllText(...))` or similar property function that performs file I/O during project evaluation phase
- **Solution**: Move file-reading logic to a target (execution phase) instead of property evaluation

## Key Concepts That Should Be Mentioned
- MSBuild evaluation phase vs execution phase
- Import chain depth impact on evaluation performance
- Glob pattern expansion performance
- DefaultItemExcludes
- Property functions and their cost during evaluation
- /pp (preprocess) for analyzing evaluation output
```

**`eval-test-prompt.txt`**: Create — needs evaluation-performance-focused prompt:

```
Analyze this project for MSBuild evaluation performance issues. What patterns are causing slow project evaluation?
```

---

### 4.12 `generated-files`

**Skills tested**: `including-generated-files`

**Hint-comments to remove**: None — the .csproj and .cs files don't contain hint-comments. The README has the fix but README is excluded from eval copy.

**`expected-output.md`**: Move from `evaluation/scenarios/generated-file-include/expected-output.md`, no content changes needed.

**`eval-test-prompt.txt`**: Not needed — default prompt works (project fails to build, which triggers analysis).

---

### 4.13 `domain-check`

**Skills tested**: `msbuild-domain-check`

**Hint-comments to remove**: Minor — `# A non-.NET Makefile` comment in Makefile. The structure is inherently the test.

**❌ Excluded from automated evaluation**: This testcase is fundamentally different from all others — it tests skill *gating* (what NOT to do) rather than build failure diagnosis. The current evaluation rubric (accuracy, completeness, actionability, clarity) doesn't map well to domain-check behavior. It remains a manual-only testcase.

**`expected-output.md`**: Not created — absence of this file means the pipeline discovery (`Where-Object { Test-Path ... "expected-output.md" }`) will automatically skip it.

**`eval-test-prompt.txt`**: Not created.

---

## 5. Script Changes

### 5.1 `run-scenario.ps1`

**Change 1**: Update scenario source path (line ~213)

```powershell
# BEFORE:
$scenarioBaseDir = Join-Path $RepoRoot "evaluation\scenarios\$ScenarioName"
$scenarioSourceDir = Join-Path $scenarioBaseDir "scenario"

# AFTER:
$scenarioBaseDir = Join-Path $RepoRoot "msbuild-skills\testcases\$ScenarioName"
$scenarioSourceDir = $scenarioBaseDir
```

**Change 2**: Update `Copy-ScenarioToTemp` to exclude evaluation/documentation files (the function around line ~77)

```powershell
# AFTER copying, remove files that shouldn't be in the eval environment:
function Copy-ScenarioToTemp {
    param(
        [string]$ScenarioSourceDir,
        [string]$ScenarioName,
        [string]$RunType
    )

    $tempBase = Join-Path ([System.IO.Path]::GetTempPath()) "copilot-eval"
    $tempDir = Join-Path $tempBase "${ScenarioName}-${RunType}-$(Get-Random)"

    Write-Host "[COPY] Copying scenario to temp directory: $tempDir"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    Copy-Item -Path "$ScenarioSourceDir\*" -Destination $tempDir -Recurse -Force

    # Remove evaluation and documentation files from temp copy
    $excludeFiles = @("expected-output.md", "eval-test-prompt.txt", "README.md", "DEMO.md", ".gitignore")
    foreach ($file in $excludeFiles) {
        $filePath = Join-Path $tempDir $file
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
            Write-Host "[CLEAN] Excluded $file from working directory"
        }
    }

    Write-Host "[OK] Scenario copied to clean working directory"
    return $tempDir
}
```

**Change 3**: Update prompt file name (around line ~249)

```powershell
# BEFORE:
$promptFile = Join-Path $workingDir "prompt.txt"

# AFTER:
# Read eval-test-prompt.txt from the ORIGINAL testcase dir (before exclusion)
$promptFile = Join-Path $scenarioBaseDir "eval-test-prompt.txt"
```

Note: The prompt should be read from the original source dir, not from the temp copy (since it's excluded from the copy). This avoids the prompt file being visible to the AI.

### 5.2 `evaluate-response.ps1`

**Change 1**: Update expected-output path (around line ~190)

```powershell
# BEFORE:
$scenarioBaseDir = Join-Path $RepoRoot "evaluation\scenarios\$ScenarioName"
$expectedFile = Join-Path $scenarioBaseDir "expected-output.md"

# AFTER:
$scenarioBaseDir = Join-Path $RepoRoot "msbuild-skills\testcases\$ScenarioName"
$expectedFile = Join-Path $scenarioBaseDir "expected-output.md"
```

---

## 6. Pipeline (YAML) Changes

### 6.1 Trigger paths

```yaml
# BEFORE:
on:
  pull_request:
    paths:
      - 'msbuild-skills/**'
      - 'evaluation/**'
      - '.github/workflows/copilot-skills-evaluation.yml'

# AFTER (no change needed — msbuild-skills/** already covers testcases):
on:
  pull_request:
    paths:
      - 'msbuild-skills/**'
      - 'evaluation/**'
      - '.github/workflows/copilot-skills-evaluation.yml'
```

### 6.2 Scenario discovery step

```yaml
# BEFORE:
- name: Discover scenarios
  id: discover
  run: |
    $inputScenarios = "${{ github.event.inputs.scenarios }}"
    if ($inputScenarios) {
      $scenarios = $inputScenarios -split ',' | ForEach-Object { $_.Trim() }
    }
    else {
      $scenarios = Get-ChildItem -Path "evaluation/scenarios" -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "scenario") } |
        Select-Object -ExpandProperty Name
    }
    ...

# AFTER:
- name: Discover scenarios
  id: discover
  run: |
    $inputScenarios = "${{ github.event.inputs.scenarios }}"
    if ($inputScenarios) {
      $scenarios = $inputScenarios -split ',' | ForEach-Object { $_.Trim() }
    }
    else {
      $scenarios = Get-ChildItem -Path "msbuild-skills/testcases" -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "expected-output.md") } |
        Select-Object -ExpandProperty Name
    }
    ...
```

**Key difference**: Instead of looking for a `scenario/` subfolder, we look for `expected-output.md`. This means only testcases that have a grading rubric will be included in evaluation. Testcases without `expected-output.md` (e.g., `domain-check`) are automatically skipped.

### 6.3 Add .NET SDK setup step

Some testcases require building .NET projects (e.g., `perf-analyzers`, `parallel-bottleneck`). The GitHub Actions runner may not have the required SDK version. Add a step **before** the vanilla run:

```yaml
      - name: Setup .NET SDK
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'
```

This ensures `dotnet build` works reliably in the temp directory for scenarios where the AI invokes it.

---

## 7. README Updates

### 7.1 `evaluation/README.md`

Major rewrite needed. Key sections to update:

1. **Folder structure** — remove `scenarios/` tree, point to `msbuild-skills/testcases/`
2. **"Adding a New Scenario"** — update instructions:
   - Create testcase in `msbuild-skills/testcases/<name>/`
   - Add `expected-output.md` grading rubric
   - Optionally add `eval-test-prompt.txt` for custom prompt
   - Ensure no hint-comments in project files
3. **Convention table** — document `expected-output.md`, `eval-test-prompt.txt`, `README.md` roles
4. **Pipeline steps** — update discovery description
5. **Running Locally** — keep as-is (act commands unchanged)

### 7.2 `msbuild-skills/testcases/README.md`

Add a column or note to the sample matrix:

| Sample | Skills Tested | Build Result | Eval? |
|--------|--------------|--------------|-------|
| `build-errors-cs` | `common-build-errors` | ❌ Fails | ✅ |
| `domain-check` | `msbuild-domain-check` | ✅ | — |
| ... | ... | ... | ... |

Add a section explaining evaluation conventions:

```markdown
## Evaluation Integration

Testcases with an `expected-output.md` file are automatically included in the
evaluation pipeline. See [evaluation/README.md](../../evaluation/README.md) for details.

### Special Files
- `expected-output.md` — Grading rubric (required for evaluation)
- `eval-test-prompt.txt` — Custom prompt override (optional)
- `README.md` — Human documentation (excluded from AI evaluation context)
```

---

## 8. Local Testing Guide

### Quick sanity check (no Copilot CLI needed)

Verify the structural changes are correct:

```powershell
# From repo root

# 1. Verify all testcases have expected-output.md
Get-ChildItem -Path "msbuild-skills/testcases" -Directory |
  ForEach-Object {
    $has = Test-Path (Join-Path $_.FullName "expected-output.md")
    [PSCustomObject]@{ Name = $_.Name; HasExpectedOutput = $has }
  } | Format-Table

# 2. Verify NO hint-comments remain in project files
$patterns = @("<!-- BAD:", "// CS0246:", "// Fix:", "// CS0029:", "// CS8600:",
              "<!-- NU1101:", "<!-- NU1605:", "<!-- NETSDK1045:",
              "// This will cause", "<!-- serial dependency")
foreach ($p in $patterns) {
    $hits = Get-ChildItem -Path "msbuild-skills/testcases" -Recurse `
              -Include "*.csproj","*.cs","*.props","*.targets" |
            Select-String -Pattern $p -SimpleMatch
    if ($hits) {
        Write-Warning "HINT-COMMENT FOUND: $p"
        $hits | ForEach-Object { Write-Warning "  $_" }
    }
}
Write-Host "✅ No hint-comments found" -ForegroundColor Green

# 3. Verify evaluation/scenarios/ is deleted
if (Test-Path "evaluation/scenarios") {
    Write-Warning "evaluation/scenarios/ still exists — should be deleted"
} else {
    Write-Host "✅ evaluation/scenarios/ deleted" -ForegroundColor Green
}

# 4. Verify scenario discovery logic
$scenarios = Get-ChildItem -Path "msbuild-skills/testcases" -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName "expected-output.md") } |
  Select-Object -ExpandProperty Name
Write-Host "Discoverable scenarios: $($scenarios -join ', ')"
```

### Run a single scenario locally (requires Copilot CLI)

```powershell
# From repo root — test one scenario end-to-end

$resultsDir = "evaluation/results/local-test"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

# Vanilla run
pwsh -File ./evaluation/scripts/run-scenario.ps1 `
  -ScenarioName "build-errors-cs" `
  -RunType "vanilla" `
  -ResultsDir $resultsDir

# Skilled run
copilot plugin install ./msbuild-skills
pwsh -File ./evaluation/scripts/run-scenario.ps1 `
  -ScenarioName "build-errors-cs" `
  -RunType "skilled" `
  -ResultsDir $resultsDir

# Evaluate
copilot plugin uninstall msbuild-skills
pwsh -File ./evaluation/scripts/evaluate-response.ps1 `
  -ScenarioName "build-errors-cs" `
  -ResultsDir $resultsDir

# Summary
pwsh -File ./evaluation/scripts/generate-summary.ps1 -ResultsDir $resultsDir
cat "$resultsDir/summary.md"
```

### Full pipeline with `act` (Docker)

Same as today — the `act` command in the evaluation README remains valid. The only prerequisite change is that `evaluation/scenarios/` no longer needs to exist.

```powershell
$ErrorActionPreference = "Continue"
& act workflow_dispatch `
    --pull=false `
    -P ubuntu-latest=act-pwsh:latest `
    --use-new-action-cache `
    --secret-file .secrets `
    --bind `
    --artifact-server-path "$PWD/.act-artifacts" `
    --env "GITHUB_RUN_ID=local-run" `
    --env "GITHUB_RUN_ATTEMPT=1" `
    2>&1 | Tee-Object -FilePath act-eval.log
```

---

## 9. Verification Checklist

After implementation, verify each item:

- [ ] 12 testcases have `expected-output.md` (all except `domain-check`)
- [ ] `domain-check` does NOT have `expected-output.md` (excluded from automated eval)
- [ ] No `<!-- BAD: -->`, `// CS0246:`, `// Fix:`, or similar hint-comments in project files (.csproj, .cs, .props, .targets)
- [ ] READMEs are unchanged (they're for humans, excluded from eval)
- [ ] `eval-test-prompt.txt` exists for: `legacy-project`, `style-issues`, `perf-analyzers`, `incremental-broken`, `parallel-bottleneck`, `eval-heavy`
- [ ] `eval-test-prompt.txt` does NOT exist for: `bin-obj-clash`, `build-errors-cs`, `build-errors-nuget`, `build-errors-sdk`, `multitarget`, `generated-files`, `domain-check` (first 6 use default prompt; `domain-check` is excluded from eval)
- [ ] `evaluation/scenarios/` directory is deleted
- [ ] `run-scenario.ps1` reads from `msbuild-skills/testcases/`
- [ ] `run-scenario.ps1` reads `eval-test-prompt.txt` from source dir (not temp copy)
- [ ] `run-scenario.ps1` excludes `expected-output.md`, `eval-test-prompt.txt`, `README.md`, `DEMO.md`, `.gitignore` from temp copy
- [ ] `evaluate-response.ps1` reads `expected-output.md` from `msbuild-skills/testcases/`
- [ ] `.yml` discovery uses `expected-output.md` presence (not `scenario/` subfolder) — `domain-check` is auto-skipped
- [ ] `evaluation/README.md` reflects new structure
- [ ] `msbuild-skills/testcases/README.md` documents evaluation conventions
- [ ] Sanity-check script passes (section 8)
- [ ] At least one scenario runs end-to-end locally

---

## 10. Risk & Rollback

### Risks

| Risk | Mitigation |
|------|------------|
| Removing hint-comments changes testcase behavior for demos | READMEs still describe what's wrong; demos don't rely on comments |
| Some testcases may need prompt tuning | `eval-test-prompt.txt` can be iterated independently |
| AI reads `README.md` from testcase dir (leaking answers) | `README.md` is excluded from temp copy — AI never sees it |
| New `expected-output.md` rubrics may not match skill expectations | Author based on SKILL.md content; iterate after first eval run |
| Testcases requiring `dotnet build` may fail without .NET SDK | Pipeline adds `actions/setup-dotnet@v4` step; `act` Docker image includes dotnet-sdk-8.0 |

### Rollback

This is a refactoring with no behavioral change for existing scenarios. If issues arise:

1. Re-create `evaluation/scenarios/` from git history
2. Revert script path changes
3. Revert YAML discovery path

The testcase hint-comment removal is the only irreversible change — but comments can be recovered from git history if needed.

---

## Appendix: Files Changed Summary

| File | Action |
|------|--------|
| `evaluation/scenarios/**` | **DELETE** (entire directory) |
| `evaluation/scripts/run-scenario.ps1` | **MODIFY** (3 changes) |
| `evaluation/scripts/evaluate-response.ps1` | **MODIFY** (1 change) |
| `evaluation/README.md` | **REWRITE** |
| `.github/workflows/copilot-skills-evaluation.yml` | **MODIFY** (discovery step + add setup-dotnet step) |
| `msbuild-skills/testcases/README.md` | **MODIFY** (add eval section) |
| `msbuild-skills/testcases/bin-obj-clash/expected-output.md` | **ADD** (moved) |
| `msbuild-skills/testcases/generated-files/expected-output.md` | **ADD** (moved+renamed) |
| `msbuild-skills/testcases/build-errors-cs/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/build-errors-nuget/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/build-errors-sdk/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/multitarget/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/legacy-project/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/style-issues/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/perf-analyzers/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/incremental-broken/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/parallel-bottleneck/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/eval-heavy/expected-output.md` | **ADD** (new) |
| `msbuild-skills/testcases/legacy-project/eval-test-prompt.txt` | **ADD** (new) |
| `msbuild-skills/testcases/style-issues/eval-test-prompt.txt` | **ADD** (new) |
| `msbuild-skills/testcases/perf-analyzers/eval-test-prompt.txt` | **ADD** (new) |
| `msbuild-skills/testcases/incremental-broken/eval-test-prompt.txt` | **ADD** (new) |
| `msbuild-skills/testcases/parallel-bottleneck/eval-test-prompt.txt` | **ADD** (new) |
| `msbuild-skills/testcases/eval-heavy/eval-test-prompt.txt` | **ADD** (new) |
| `msbuild-skills/testcases/build-errors-cs/MissingReference.cs` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/build-errors-cs/TypeMismatch.cs` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/build-errors-nuget/PackageNotFound.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/build-errors-nuget/VersionDowngrade.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/build-errors-sdk/SdkNotFound.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/multitarget/PlatformApi.cs` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/eval-heavy/EvalHeavy.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/eval-heavy/imports/level1.props` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/incremental-broken/IncrementalBroken.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/style-issues/LibA/LibA.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/style-issues/LibB/LibB.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/parallel-bottleneck/Api/Api.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/parallel-bottleneck/Web/Web.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/parallel-bottleneck/Tests/Tests.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/perf-analyzers/AnalyzerHeavy.csproj` | **MODIFY** (remove comments) |
| `msbuild-skills/testcases/domain-check/Makefile` | **MODIFY** (optional — remove `# A non-.NET Makefile` comment if desired, but low priority since domain-check is manual-only) |
