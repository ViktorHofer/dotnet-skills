---
name: template-instantiation
description: "Skill for creating .NET projects from templates with correct parameters, smart defaults, and constraint validation. Use when a user wants to scaffold a new project, solution, or item from a dotnet new template. Covers parameter selection, dry-run preview, multi-template orchestration, and post-creation verification. DO NOT use for template authoring, build failures, or NuGet package management."
---

# Template Instantiation

## When to Use

Invoke this skill when:
- User explicitly asks to create a project/solution/item from a template
- User describes a project they want and the right template has been identified (via `template-discovery` skill)
- User wants to add an item template (e.g., class, interface, razor page) to an existing project

## Step 1: Verify Parameters

Before calling `template_instantiate`, ensure you have:
1. **Template short name** — from search/list results
2. **Project name** — usually provided by user
3. **Output path** — where to create the project
4. **Parameters** — framework, auth, feature flags, etc.

Use `template_inspect` if you need to verify available parameters and their valid values.

## Step 2: Preview with Dry Run

Always offer a dry run before creation:

```
template_dry_run with:
  shortName: "webapi"
  name: "MyService"
  output: "./src/MyService"
  parameters: { "framework": "net10.0", "use-controllers": "true" }
```

Review the output file list with the user before proceeding.

## Step 3: Instantiate

```
template_instantiate with:
  shortName: "webapi"
  name: "MyService"
  output: "./src/MyService"
  parameters: { "framework": "net10.0", "use-controllers": "true" }
```

The tool handles:
- **Auto-resolve**: If template isn't installed, auto-searches NuGet → installs → creates
- **Parameter validation**: Reports invalid values with suggestions
- **Constraint checks**: Validates OS, SDK version, workload requirements
- **Post-actions**: Runs restore, opens files, executes scripts as defined by the template

## Step 4: Post-Creation Verification

After instantiation:
1. Verify the project builds: `dotnet build ./src/MyService`
2. Check for expected files (Program.cs, .csproj, etc.)
3. If adding to a solution, run: `dotnet sln add ./src/MyService`

## Smart Defaults

The MCP server suggests parameter relationships:
- `EnableAot=true` → suggests `net9.0` or later
- `--auth Individual` → appropriate identity packages
- `--use-controllers false` → minimal API pattern

Use `template_suggest_parameters` for parameter suggestions with human-readable rationale.

## Post-Creation Intelligence

The `template_instantiate` tool automatically adapts output to the target environment:

### CPM (Central Package Management)
If `Directory.Packages.props` exists in any parent directory:
- Strips `Version` attributes from generated `.csproj` PackageReferences
- Adds `<PackageVersion>` entries to `Directory.Packages.props` (skips existing entries)

### Latest NuGet Versions
By default (`resolveLatestVersions: true`), queries the NuGet V3 API for every PackageReference and replaces template-hardcoded versions with the latest stable release. In CPM mode, latest versions go into `Directory.Packages.props`.

## Multi-Template Workflows

For complex project structures, use `template_compose` for orchestrated multi-step creation, or chain template operations:

### 1. Solution + Web API + Test Project
```
1. template_instantiate: "sln" → MySolution
2. template_instantiate: "webapi" → src/MyApi
3. template_instantiate: "xunit" → test/MyApi.Tests
4. dotnet sln add src/MyApi test/MyApi.Tests
5. Add ProjectReference from test → src
```

### 2. MAUI App + Class Library + Tests
```
1. template_instantiate: "maui" → src/MyApp
2. template_instantiate: "classlib" → src/MyApp.Core
3. template_instantiate: "mstest" → test/MyApp.Tests
```

## Error Recovery

| Error | Resolution |
|-------|-----------|
| Template not found | Use `template_search` to find alternatives; auto-resolve will install from NuGet |
| Invalid parameter value | Tool returns valid options with "did you mean...?" suggestions |
| SDK constraint failed | Install required SDK version or use `--framework` to target available SDK |
| Workload missing | Install workload: `dotnet workload install <workload>` |
| Output directory exists | Choose a different `--output` path or confirm overwrite |

## Cross-Reference

- **Finding the right template** → `template-discovery` skill
- **Creating templates from existing projects** → `template-authoring` skill
- **Build failures after creation** → MSBuild skills (`common-build-errors`, `nuget-restore-failures`)
