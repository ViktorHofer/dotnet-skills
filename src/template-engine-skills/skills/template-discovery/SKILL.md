---
name: template-discovery
description: "Skill for finding, inspecting, and selecting the right .NET template for a task. Use when a user asks to create a new project, library, test project, or solution, and the right template needs to be identified. Covers searching NuGet.org and local caches, inspecting template parameters and constraints, and comparing template alternatives. DO NOT use for MSBuild build issues, NuGet restore problems, or non-template .NET tasks."
---

# Template Discovery

## When to Use

Invoke this skill when:
- User wants to create a new .NET project, library, test, or solution
- User asks "what templates are available for X?"
- User needs to find the right template for a specific scenario (e.g., "MAUI app", "Blazor WASM", "worker service")
- User wants to compare template options before choosing

## Step 0: Try Intent Resolution First

For natural-language requests like *"I need a web API with auth and controllers"*, start with `template_from_intent`:

```
template_from_intent with description: "web API with auth and controllers"
→ Returns: { template: "webapi", confidence: 0.85, params: { auth: "Individual", UseControllers: "true" } }
```

This uses 70+ keyword mappings to resolve intent offline (no LLM round-trip). If confidence is high (>0.7), proceed directly to `template-instantiation`. If low or ambiguous, fall through to Step 1.

## Step 1: Search for Templates

Use `template_search` to find templates matching the user's intent. The tool searches both local installed templates and NuGet.org, returning ranked results.

```
template_search with query: "blazor"
template_search with query: "worker service"
template_search with query: "class library"
```

Results include: template name, short name, language, type, author, NuGet package (if remote), and relevance ranking.

### Search Tips
- Use descriptive terms: "web api", "console app", "test project"
- Search by technology: "maui", "blazor", "grpc", "minimal api"
- Search by project type: "classlib", "webapp", "worker"

## Step 2: List Installed Templates

Use `template_list` to see what's already available locally:

```
template_list                              # All installed
template_list with language: "C#"          # C# only
template_list with type: "project"         # Projects only
template_list with classification: "Web"   # Web templates
```

## Step 3: Inspect Template Details

Before instantiation, always inspect the template to understand its parameters:

```
template_inspect with identity: "Microsoft.DotNet.Web.ProjectTemplates.9.0.blazorserver"
```

Returns:
- **Parameters**: name, type, default value, choices (for choice params), description
- **Constraints**: OS, SDK version, workload requirements
- **Post-actions**: what happens after creation (restore, open file, run script)
- **Framework versions**: supported TFMs

### Parameter Types
| Type | Examples | Notes |
|------|----------|-------|
| `choice` | `--framework net8.0\|net9.0\|net10.0` | Must be one of the listed values |
| `bool` | `--use-program-main true\|false` | Toggle features on/off |
| `string` | `--namespace MyApp` | Free-form text |
| `integer` | `--port 5000` | Numeric values |

## Step 4: Preview with Dry Run

Use `template_dry_run` to see exactly what files would be created:

```
template_dry_run with:
  shortName: "webapi"
  name: "MyApi"
  output: "./src/MyApi"
  parameters: { "framework": "net10.0", "use-controllers": "true" }
```

Returns file list, directory structure, and any warnings — without writing anything to disk.

## Smart Behaviors

The template-engine-mcp server includes smart behaviors:
- **Auto-resolve**: If a template isn't installed, the server searches NuGet, installs the package, and proceeds
- **Parameter validation**: Invalid choice values or types are caught with "did you mean...?" suggestions
- **Constraint checking**: OS, SDK version, and workload constraints are verified before creation
- **Smart defaults**: Parameter relationships are suggested (e.g., `EnableAot=true` → suggest `net9.0+`)

## Common Template Quick-Reference

| Scenario | Short Name | Key Parameters |
|----------|-----------|----------------|
| Console app | `console` | `--framework`, `--use-program-main` |
| Class library | `classlib` | `--framework` |
| Web API | `webapi` | `--framework`, `--use-controllers`, `--auth` |
| Blazor Server | `blazorserver` | `--framework`, `--auth` |
| Worker Service | `worker` | `--framework` |
| xUnit tests | `xunit` | `--framework` |
| MSTest tests | `mstest` | `--framework` |
| NUnit tests | `nunit` | `--framework` |
| MAUI app | `maui` | `--framework` |
| gRPC service | `grpc` | `--framework` |
