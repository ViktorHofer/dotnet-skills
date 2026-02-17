# MSBuild Skills — Demo Guide

A step-by-step walkthrough for demoing the MSBuild skills plugin. Each scenario is self-contained and takes 2-3 minutes. Pick the ones that resonate with your audience.

---

## Prerequisites

```bash
# 1. Launch Copilot CLI
copilot

# 2. Install the plugin (if not already installed)
/plugin marketplace add ViktorHofer/dotnet-skills
/plugin install msbuild-skills@dotnet-skills

# 3. Restart Copilot CLI
/exit
copilot
```

Verify skills are loaded: `/skills` should list all MSBuild skills.

---

## Scenario 1: "My Build is Broken" — Build Failure Diagnosis

**Story**: A developer added a new feature but the build fails. The AI diagnoses the root cause from the error codes and suggests the exact fix.

**Duration**: ~2 minutes

### Setup
```bash
cd src/plugins/msbuild-skills/samples/build-errors-cs
```

### Demo Script

**Step 1** — Try to build:
```
Build MissingReference.csproj
```

> **What happens**: The build fails with errors about missing types. The AI should:
> 1. Recognize the CS error codes (CS0246 or similar)
> 2. Invoke the `common-build-errors` skill automatically
> 3. Identify that `System.Text.Json` and `Microsoft.Extensions.Logging.Abstractions` packages are missing
> 4. Add the missing `<PackageReference>` entries
> 5. Rebuild to verify the fix

**Key talking point**: _"The AI didn't just read the error message — it consulted a deep knowledge base of .NET build errors and knew exactly which NuGet packages provide the missing types."_

### Fallback
If time is short, you can also use `samples/generated-files` which produces CS0103. Ask:
```
Build GeneratedFiles.csproj and fix any errors
```

The AI should discover the generated file isn't included in compilation and add the `<Compile>` and `<FileWrites>` items to the target.

---

## Scenario 2: "Clean Up My Project" — Code Review & Modernization

**Story**: A team inherited a legacy project. The AI reviews it, identifies everything that's wrong, and modernizes it — reducing 60 lines of XML to 6.

**Duration**: ~3 minutes

### Setup
```bash
cd src/plugins/msbuild-skills/samples/legacy-project
```

### Demo Script

**Step 1** — Show the audience the bloated legacy project:
```
Show me the contents of LegacyApp.csproj
```

> **What to point out**: ~55 lines of XML with explicit file lists, framework references, Import statements, Debug/Release configurations, AssemblyInfo in a separate file — all unnecessary boilerplate.

**Step 2** — Ask for modernization:
```
Modernize this project to SDK-style format. Remove all unnecessary boilerplate.
```

> **What happens**: The AI should:
> 1. Invoke the `msbuild-modernization` skill
> 2. Replace the project root with `<Project Sdk="Microsoft.NET.Sdk">`
> 3. Remove all explicit `<Compile>` items (SDK handles this)
> 4. Remove framework `<Reference>` entries
> 5. Remove Import statements
> 6. Move AssemblyInfo properties to the .csproj
> 7. Delete `Properties/AssemblyInfo.cs`
> 8. Result: ~6 lines of clean XML

**Step 3** — Verify it still works:
```
Build the project to make sure the migration worked
```

**Key talking point**: _"The AI followed a structured migration checklist from the modernization skill. It knows every piece of boilerplate that's safe to remove in SDK-style projects. What took teams hours to migrate manually happens in seconds."_

---

## Scenario 3: "Why is My Build Slow?" — Performance Diagnosis

**Story**: A solution builds slowly. The AI generates a binlog, analyzes it, and identifies that Roslyn analyzers are the bottleneck.

**Duration**: ~3 minutes

### Setup
```bash
cd src/plugins/msbuild-skills/samples/perf-analyzers
```

### Demo Script

**Step 1** — Ask the AI to analyze performance:
```
Build this project and analyze its build performance. Is anything unusually slow?
```

> **What happens**: The AI should:
> 1. Build with a binlog: `dotnet build /bl:1.binlog -m`
> 2. Load the binlog with MCP tools
> 3. Call `get_expensive_tasks` and `get_expensive_analyzers`
> 4. Identify that analyzer execution time is a significant portion of the Csc task
> 5. List the specific slow analyzers (StyleCop, SonarAnalyzer, etc.)
> 6. Suggest: disable analyzers in dev inner loop with `<RunAnalyzers>false</RunAnalyzers>`

**Step 2** (optional) — Apply the fix and compare:
```
Disable analyzers and rebuild. How much faster is it?
```

**Key talking point**: _"The AI used the binlog MCP server to get actual timing data — not guessing, but measuring. It identified the exact analyzers causing the slowdown and suggested the standard MSBuild property to fix it."_

---

## Scenario 4: "Review My Project Files" — Multi-Project Code Review

**Story**: A team has two projects with duplicated settings and anti-patterns. The AI spots everything and sets up proper build infrastructure.

**Duration**: ~3 minutes

### Setup
```bash
cd src/plugins/msbuild-skills/samples/style-issues
```

### Demo Script

**Step 1** — Ask for a review:
```
Review the MSBuild project files in this solution for best practices. What should be improved?
```

> **What happens**: The AI should invoke the `msbuild-code-review` agent or `msbuild-style-guide` skill and identify:
> 1. 🔴 **Hardcoded absolute path** for OutputPath in both projects
> 2. 🔴 **Unquoted condition** (`$(Configuration) == Debug` → missing quotes)
> 3. 🟡 **Duplicated properties** (LangVersion, Nullable, Company, etc.) in both LibA and LibB
> 4. 🟡 **Explicit Compile include** (unnecessary in SDK-style)
> 5. 🟡 **`<Reference>` with HintPath** instead of PackageReference
> 6. 🟡 **`<Exec>`** where a built-in task would work
> 7. 🔵 **No Directory.Build.props** to centralize shared settings

**Step 2** — Ask it to fix:
```
Fix these issues. Create a Directory.Build.props and clean up both projects.
```

> **What happens**: The AI should:
> 1. Create `Directory.Build.props` with the shared properties
> 2. Remove duplicated properties from both .csproj files
> 3. Fix the hardcoded paths
> 4. Fix the unquoted condition
> 5. Replace `<Reference>` with `<PackageReference>`
> 6. Remove explicit `<Compile>` entries
> 7. Rebuild to verify

**Key talking point**: _"In a real codebase with 50+ projects, these duplicated settings drift apart over time. The AI found every instance, centralized them into Directory.Build.props, and made the projects consistent — exactly what the MSBuild style guide recommends."_

---

## Tips for Presenters

1. **Start with Scenario 1 or 2** — they have the most visual impact (errors → fix, 60 lines → 6 lines)
2. **Show `/skills`** at the start so the audience sees the breadth of available skills
3. **Highlight the automatic skill invocation** — the AI picks the right skill without being told
4. **If the AI takes a different path**, that's fine — roll with it and explain the reasoning
5. **Have the README open** for each sample as a cheat sheet for what should happen
6. **Time budget**: allow 2-3 min per scenario, plus 2 min for setup and Q&A

## Quick Reference: All Demo-able Samples

| Sample | Best For | Audience |
|--------|----------|----------|
| `build-errors-cs` | "AI fixes build errors" | Developers |
| `generated-files` | "AI fixes tricky build issue" | Developers |
| `legacy-project` | "AI modernizes legacy code" | Managers, architects |
| `perf-analyzers` | "AI diagnoses slow builds" | DevOps, CI/CD teams |
| `style-issues` | "AI reviews and cleans up project files" | Tech leads, architects |
| `incremental-broken` | "AI fixes incremental build" | Build engineers |
| `multitarget` | "AI handles multi-targeting" | Library authors |
