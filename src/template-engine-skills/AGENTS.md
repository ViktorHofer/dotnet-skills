# .NET Template Engine Instructions

<!-- Copy this file to your repository root as AGENTS.md for cross-agent support (Copilot, Claude Code, etc.) -->

## Project Scaffolding

This repository uses `dotnet new` templates for project creation. Key commands:
- Search templates: `dotnet new search <term>`
- List installed: `dotnet new list`
- Create project: `dotnet new <template> -n <name> -o <path>`
- Install template pack: `dotnet new install <package>`

## Template Selection

When creating new projects:
1. Use `template_search` or `template_list` MCP tools to find the right template
2. Use `template_inspect` to understand available parameters before creation
3. Use `template_dry_run` to preview output before committing to creation
4. Use `template_instantiate` with appropriate parameters for the project type

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
