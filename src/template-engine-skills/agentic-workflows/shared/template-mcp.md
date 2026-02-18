---
mcp-servers:
  template-engine-mcp:
    command: "dnx"
    args: ["-y", "DotnetTemplateMCP@0.1.0-preview.2"]
tools:
  bash: ["dotnet", "cat", "grep", "head", "tail", "find", "ls"]
---

<!-- Shared: .NET Template Engine MCP Server -->
<!-- Import this in agentic workflows that need template engine capabilities -->

When working with .NET templates, use the template-engine-mcp tools:
1. Search for templates: `template_search` with a query term (searches local + NuGet.org)
2. List installed templates: `template_list` with optional language/type filters
3. Inspect template details: `template_inspect` for parameters, constraints, post-actions
4. Preview creation: `template_dry_run` to see what files would be generated
5. Create project: `template_instantiate` with name, output path, and parameters
6. Install packages: `template_install` to add new template packs
7. Generate from existing: `template_create_from_existing` to reverse-engineer a template from a .csproj
