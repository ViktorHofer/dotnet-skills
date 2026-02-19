# .NET Template Engine Instructions

<!-- Copy this file to your repository root as AGENTS.md for cross-agent support (Copilot, Claude Code, etc.) -->

## Project Scaffolding

This repository uses `dotnet new` templates for project creation, powered by the DotnetTemplateMCP MCP server. Prefer MCP tools over raw `dotnet new` CLI commands for validation, smart defaults, and auto-resolution.

## Template Selection

When creating new projects:
1. Use `template_from_intent` to resolve natural-language descriptions (e.g., *"web API with auth"* → webapi + `auth=Individual`)
2. Use `template_search` or `template_list` to find templates by keyword
3. Use `template_inspect` to understand available parameters before creation
4. Use `template_dry_run` to preview output before committing to creation
5. Use `template_instantiate` with appropriate parameters — it validates, applies smart defaults, adapts to CPM, and resolves latest NuGet versions automatically

## Smart Behaviors

The MCP server handles these automatically during `template_instantiate`:
- **Auto-resolve**: Template not installed? Searches NuGet, installs, and creates — one call
- **Smart defaults**: `EnableAot=true` → suggests latest framework; `auth=Individual` → keeps HTTPS; `UseControllers=true` → sets `UseMinimalAPIs=false`
- **CPM adaptation**: Detects `Directory.Packages.props`, strips versions from `.csproj`, adds `<PackageVersion>` entries to the props file
- **Latest versions**: Queries NuGet V3 API to replace stale template-hardcoded package versions with latest stable releases
- **Parameter validation**: Reports invalid values with "did you mean...?" suggestions before files are written

## Multi-Template Workflows

Use `template_compose` for complex project structures (solution + API + tests) in a single orchestrated workflow, or chain `template_instantiate` calls manually.

## Parameter Conventions

- Always specify `--framework` when the template supports multiple TFMs
- Use `--language` when creating projects in F# or VB.NET (default is C#)
- For test projects, match the test framework to the repository conventions (xUnit, NUnit, MSTest)
- Enable `--use-program-main` if the repository uses explicit Program.Main patterns

## Template Authoring

When creating custom templates:
- Place template.json in `.template.config/template.json`
- Use meaningful `identity` and `shortName` fields
- Document all parameters with `description` and `displayName`
- Add `defaultValue` for optional parameters
- Set appropriate `classifications` and `tags` for discoverability
- Use `template_create_from_existing` to bootstrap templates from existing projects
