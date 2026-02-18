---
name: template-authoring
description: "Skill for creating, maintaining, and validating custom dotnet new templates. Use when a user wants to create a reusable template from an existing project, author template.json manually, add parameters or post-actions, or validate a template before publishing. Covers template.json structure, parameter types, conditional content, post-actions, constraints, and ai.host.json metadata. DO NOT use for using/instantiating existing templates or for MSBuild build issues."
---

# Template Authoring

## When to Use

Invoke this skill when:
- User wants to create a custom `dotnet new` template
- User wants to reverse-engineer a template from an existing project
- User needs to add parameters, post-actions, or constraints to an existing template
- User wants to validate or test a template before publishing

## Creating a Template from an Existing Project

Use `template_create_from_existing` to analyze a .csproj and generate a complete template:

```
template_create_from_existing with:
  projectPath: "C:/repos/MyProject/MyProject.csproj"
  templateName: "My Custom Template"
  shortName: "mycustomtemplate"
  outputDir: "C:/repos/MyProject/.template.config"
```

This generates:
- `template.json` — complete metadata with parameters extracted from project properties
- Templatized `.csproj` — namespace tokens, conditional sections
- `sourceName` set for automatic namespace/filename renaming
- Gaps report showing differences from generic `dotnet new` templates

## Template Directory Structure

```
MyTemplate/
├── .template.config/
│   ├── template.json          # Template metadata (required)
│   ├── ide.host.json          # VS/Rider IDE integration (optional)
│   ├── dotnetcli.host.json    # CLI parameter mappings (optional)
│   └── ai.host.json           # AI assistant metadata (optional)
├── MyProject.csproj           # Project file (templatized)
├── Program.cs                 # Source files
└── ...
```

## template.json Structure

```json
{
  "$schema": "http://json.schemastore.org/template",
  "author": "Your Name",
  "classifications": ["Web", "API"],
  "identity": "MyOrg.MyTemplate.CSharp",
  "name": "My Custom Template",
  "shortName": "mytemplate",
  "sourceName": "MyTemplate",
  "preferNameDirectory": true,
  "tags": {
    "language": "C#",
    "type": "project"
  },
  "symbols": { },
  "sources": [{ "modifiers": [] }],
  "postActions": []
}
```

### Key Fields
| Field | Required | Description |
|-------|----------|-------------|
| `identity` | Yes | Unique identifier (use reverse-domain: `Org.Template.Lang`) |
| `shortName` | Yes | CLI name used with `dotnet new <shortName>` |
| `sourceName` | Yes | Token replaced with project name in filenames and content |
| `name` | Yes | Human-readable display name |
| `classifications` | Yes | Categories for discovery (Web, Console, Test, Library) |
| `tags.language` | Yes | Primary language (C#, F#, VB) |
| `tags.type` | Yes | `project`, `item`, or `solution` |

## Parameter Types (symbols)

```json
"symbols": {
  "Framework": {
    "type": "parameter",
    "datatype": "choice",
    "defaultValue": "net10.0",
    "choices": [
      { "choice": "net10.0", "description": ".NET 10" },
      { "choice": "net9.0", "description": ".NET 9" }
    ],
    "replaces": "net10.0"
  },
  "EnableAot": {
    "type": "parameter",
    "datatype": "bool",
    "defaultValue": "false",
    "description": "Enable Native AOT publishing"
  },
  "copyrightYear": {
    "type": "generated",
    "generator": "now",
    "parameters": { "format": "yyyy" },
    "replaces": "1975"
  }
}
```

### Supported Data Types
| Type | Use Case | Notes |
|------|----------|-------|
| `choice` | Framework, auth mode | Define `choices` array |
| `bool` | Feature toggles | Drives `#if` conditional sections |
| `string` | Namespace, author | Free-form text replacement |
| `integer` | Port numbers | Numeric values |
| `float` | Version numbers | Decimal values |

## Conditional Content

Use C# preprocessor-style directives for conditional content:

```csharp
#if (EnableAot)
[JsonSerializable(typeof(WeatherForecast))]
internal partial class AppJsonContext : JsonSerializerContext { }
#endif
```

In `.csproj` files, use XML comments:
```xml
<!--#if (EnableAot) -->
<PublishAot>true</PublishAot>
<!--#endif -->
```

## Post-Actions

Common post-actions to include:

```json
"postActions": [
  {
    "actionId": "210D431B-A78B-4D2F-B762-4ED3E3EA9025",
    "description": "Restore NuGet packages",
    "manualInstructions": [{ "text": "Run 'dotnet restore'" }],
    "continueOnError": true
  },
  {
    "actionId": "84C0DA21-51C8-4541-9940-6CA19AF04EE6",
    "description": "Open README in editor",
    "args": { "files": "README.md" },
    "manualInstructions": [{ "text": "Open README.md" }]
  }
]
```

### Post-Action GUIDs
| GUID | Action |
|------|--------|
| `210D431B-...` | Restore NuGet packages |
| `84C0DA21-...` | Open file in editor |
| `3A7C4B45-...` | Run script |
| `D396686C-...` | Add project reference |
| `B17581D1-...` | Add to solution |
| `AC1156F7-...` | chmod (Unix permissions) |

## Constraints

```json
"constraints": {
  "sdk-version": {
    "type": "sdk-version",
    "args": [ "[9.0,)" ]
  },
  "os": {
    "type": "os",
    "args": "Windows"
  },
  "workload": {
    "type": "workload",
    "args": [ "maui" ]
  }
}
```

## Testing a Template

1. Install locally: `dotnet new install ./path/to/template/`
2. List to verify: `dotnet new list mytemplate`
3. Dry run: `template_dry_run` or `dotnet new mytemplate --dry-run`
4. Create and build: `dotnet new mytemplate -n TestProject && dotnet build TestProject`
5. Uninstall: `dotnet new uninstall ./path/to/template/`

## Packaging for NuGet

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <PackageType>Template</PackageType>
    <PackageId>MyOrg.Templates</PackageId>
    <PackageVersion>1.0.0</PackageVersion>
    <IncludeContentInPack>true</IncludeContentInPack>
    <IncludeBuildOutput>false</IncludeBuildOutput>
    <ContentTargetFolders>content</ContentTargetFolders>
  </PropertyGroup>
  <ItemGroup>
    <Content Include="templates\**\*" Exclude="templates\**\bin\**;templates\**\obj\**" />
  </ItemGroup>
</Project>
```

## Cross-Reference

- **Finding templates** → `template-discovery` skill
- **Creating projects from templates** → `template-instantiation` skill
- **MSBuild project file best practices** → `msbuild-style-guide` skill (msbuild-skills plugin)
