# Template Engine Skills

.NET Template Engine skills for AI assistants: template discovery, instantiation, authoring, and project scaffolding powered by the [DotnetTemplateMCP](https://github.com/YuliiaKovalova/dotnet-template-mcp) MCP server.

## 🔧 Skills

### Template Discovery & Usage

| Skill | Description |
|-------|-------------|
| [`template-discovery`](skills/template-discovery/) | Finding, inspecting, and selecting the right template for a task |
| [`template-instantiation`](skills/template-instantiation/) | Creating projects from templates with correct parameters and smart defaults |

### Template Authoring

| Skill | Description |
|-------|-------------|
| [`template-authoring`](skills/template-authoring/) | Creating and maintaining custom `dotnet new` templates |

## 🤖 Agents

| Agent | Description |
|-------|-------------|
| [`template-engine`](agents/template-engine.agent.md) | Expert agent for .NET template operations — discovery, creation, authoring |

## 🔌 MCP Server

This plugin uses the **DotnetTemplateMCP** MCP server (v0.1.0-preview.3), which exposes the following tools:

| Tool | Description |
|------|-------------|
| `template_search` | Search templates locally and on NuGet.org (ranked results) |
| `template_list` | List installed templates with language/type/classification filters |
| `template_inspect` | Full metadata: parameters, constraints, post-actions |
| `template_instantiate` | Create projects with auto-resolve, validation, smart defaults, CPM adaptation, and latest NuGet versions |
| `template_dry_run` | Preview what instantiation would produce without writing files |
| `template_install` | Install template packages (idempotent, supports upgrade) |
| `template_uninstall` | Remove installed template packages |
| `template_create_from_existing` | Analyze a .csproj and generate a reusable template from it |
| `template_from_intent` | Natural-language intent resolution: *"web API with auth"* → webapi + `auth=Individual` (70+ keyword mappings, offline) |
| `template_compose` | Execute a sequence of template operations (project + items) in one orchestrated workflow |
| `template_suggest_parameters` | Suggest parameter values with rationale based on cross-parameter relationships |

### Smart Behaviors (v0.1.0-preview.3)

| Feature | Description |
|---------|-------------|
| **Intent Resolution** | 70+ keyword mappings resolve natural-language descriptions to template + parameters. No LLM needed. |
| **CPM Adaptation** | Detects `Directory.Packages.props` in parent directories, strips versions from `.csproj`, adds entries to props file |
| **Latest NuGet Versions** | Queries NuGet V3 API at creation time to replace template-hardcoded versions with latest stable releases |
| **Multi-Template Composition** | `template_compose` chains project + item templates in a single orchestrated workflow |
| **Parameter Suggestions** | `template_suggest_parameters` returns values with human-readable rationale (e.g., "AOT works best with net9.0+") |

### Resources & Prompts

| Type | Name | Description |
|------|------|-------------|
| Resource | `templates_installed` | List all currently installed templates |
| Prompt | `create_project` | Guided workflow: describe → match → fill params → dry-run → create |

## 📦 Installation

The MCP server is installed automatically via `dnx` when the plugin is loaded. Requires .NET 10+ SDK.

Manual installation:
```bash
dotnet tool install -g DotnetTemplateMCP --version 0.1.0-preview.3
```

## 📄 Distribution Templates

| Template | Description |
|----------|-------------|
| [Agent Instructions](AGENTS.md) | Copy to repo root as `AGENTS.md` for cross-agent template guidance |
| [Prompt Files](prompts/) | Copy to `.github/prompts/` for VS Code Copilot Chat workflows |
