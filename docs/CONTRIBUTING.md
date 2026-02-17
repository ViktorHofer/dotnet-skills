# Contributing

We welcome contributions! This repository ships several types of artifacts — each has its own format and conventions.

## Repository Structure

```
src/msbuild-skills/
├── plugin.json                  # Plugin manifest (bump version on releases)
├── .mcp.json                    # MCP server configuration (binlog-mcp)
├── agents/                      # Custom agents (*.agent.md)
├── skills/                      # Skills (*/SKILL.md)
├── samples/                     # Test/demo sample projects
│   └── DEMO.md                  # Presenter-ready demo guide
└── templates/                   # Distribution templates for end users
    ├── AGENTS.md                # Template for repo-root AGENTS.md
    ├── prompts/                 # Reusable .prompt.md files
    └── agentic-workflows/       # GitHub Agentic Workflow templates
        ├── shared/              # Shared components (imported by workflows)
        └── *.md                 # Workflow definitions
```

## Adding a Skill

Skills are AI-readable knowledge documents. The AI reads them for guidance when a matching topic comes up.

1. Create a directory: `src/msbuild-skills/skills/my-skill-name/`
2. Create `SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill-name
description: "Clear description of WHEN to use this skill. Include DO NOT trigger conditions."
---
```

**Conventions:**
- `name` must match the directory name
- `description` is critical — it's how the AI decides whether to invoke the skill. Be precise about trigger conditions
- Include `DO NOT use for` exclusions (e.g., "DO NOT use for npm/Gradle/CMake builds")
- Cross-reference related skills by name (e.g., "see `build-caching` skill for caching strategies")
- Be actionable: exact commands, MSBuild XML snippets, step-by-step fix instructions
- Target the content at an AI reader, not a human tutorial audience — be dense, skip pleasantries
- Keep skills focused. If it grows beyond ~20KB, consider splitting into multiple skills

**Good description example:**
```
"Diagnose and fix NuGet package restore failures in .NET projects. Use when dotnet restore
fails, packages can't be resolved, or feed authentication fails. Covers nuget.config issues,
private feed auth, version conflicts, and lock files. DO NOT use for non-.NET package managers
(npm, pip, Maven, etc.)."
```

## Adding a Custom Agent

Agents are autonomous AI personas that orchestrate multi-step workflows — they take actions, run tools, and dispatch to skills.

1. Create `src/msbuild-skills/agents/my-agent.agent.md`
2. Use YAML frontmatter:

```yaml
---
name: my-agent
description: "What this agent does and when to invoke it."
user-invokable: true
disable-model-invocation: false
---
```

**Conventions:**
- `user-invokable: true` — user can explicitly invoke via agent name
- `disable-model-invocation: false` — AI can also decide to invoke automatically
- Define a clear **workflow** (Step 1 → Step 2 → ...) in the body
- Reference related skills with relative paths (e.g., `../skills/my-skill/SKILL.md`)
- Agents should orchestrate, not duplicate skill content — link to skills for deep knowledge
- Agents are auto-discovered from the `agents` directory (no manifest change needed)

## Adding a Prompt File

Prompt files are user-triggered workflow templates for VS Code Copilot Chat (`#prompt` references).

1. Create `src/msbuild-skills/templates/prompts/my-workflow.prompt.md`
2. Use YAML frontmatter with a description:

```yaml
---
description: "Short description of what this prompt does"
---
```

**Conventions:**
- Keep prompts goal-oriented: "Fix X", "Optimize Y", "Migrate Z"
- Include numbered steps for the AI to follow
- Provide context about what to check (project files, config, recent changes)
- These are templates — users copy them to their repo's `.github/prompts/`

## Adding an Agentic Workflow

[GitHub Agentic Workflows](https://github.com/github/gh-aw) are event-driven AI automation that runs in GitHub Actions. They're written in markdown with YAML frontmatter.

1. Create `src/msbuild-skills/templates/agentic-workflows/my-workflow.md`
2. Use the `gh aw` frontmatter format:

```yaml
---
on:
  # Standard GitHub Actions trigger syntax
  pull_request:
    types: [opened, synchronize]
    paths: ["**/*.csproj"]

permissions:
  contents: read
  pull-requests: write

imports:
  - shared/msbuild-knowledge.md    # Reuse shared components

tools:
  github:
    toolsets: [repos, pull_requests]
  bash: ["dotnet", "cat", "grep"]

safe-outputs:
  add-comment:
    max: 3
---

# My Workflow Title

Natural language instructions for the AI agent...
```

**Conventions:**
- Use `imports:` to reuse shared components from `shared/` (DRY)
- Always set `permissions:` to minimum required (read-only by default)
- Use `safe-outputs:` for any write operations (comments, issues) — never request broad write permissions
- Set `max:` limits on safe-outputs to prevent runaway AI writes
- Use `bash:` with an explicit allowlist of commands, never `[":*"]` in templates
- Add custom MCP servers under `mcp-servers:` when tools are needed (e.g., `binlog-mcp`)
- These are templates — users copy them to `.github/workflows/` and run `gh aw compile`

**Shared components** (`templates/agentic-workflows/shared/`):
- Reusable fragments that workflows import via `imports:`
- Contain tool configuration, MCP server setup, or shared knowledge
- Keep them focused on one concern (e.g., `binlog-mcp.md` only configures the MCP server)

## Adding a Sample

Samples are small .NET projects that intentionally trigger specific skill scenarios — for testing and demos.

1. Create a directory: `src/msbuild-skills/samples/my-scenario/`
2. Add minimal project files that reproduce the issue
3. Add a `README.md` with:

```markdown
# Sample Name — Short Description

## Issues Present
- What's intentionally wrong and why

## Skills Tested
- `skill-name-1` — what aspect it tests
- `skill-name-2` — what aspect it tests

## How to Test
```bash
dotnet build MyProject.csproj   # Expected: fails with error XXXX
```

## Expected Behavior
What the AI should do when encountering this sample

## Expected Fix
The correct solution (for validation)
```

**Conventions:**
- Keep samples minimal — smallest possible project that demonstrates the issue
- Each sample should have a clear, predictable outcome (specific error code or identifiable anti-pattern)
- Clean up `bin/` and `obj/` before committing (they're in `.gitignore`)
- Update `samples/README.md` sample matrix table
- Consider updating `samples/DEMO.md` if the sample is good for demos

## Updating the Custom Instructions Template

The file `templates/AGENTS.md` is a template users copy to their repo root as `AGENTS.md`. Keep it concise — these instructions are injected into **every** AI interaction, so brevity matters. Focus on the highest-impact conventions only.

## Plugin Manifest

When adding new agents or skills, no `plugin.json` change is needed — both are auto-discovered from their directories.
- Add new agents to the `agents` array
- Skills are auto-discovered from the `skills` directory (no manifest change needed)
- Agents are auto-discovered from the `agents` directory (no manifest change needed)
- Bump `version` following [semver](https://semver.org/) on releases:
  - Patch: fix content in existing skills
  - Minor: add new skills, agents, or templates
  - Major: breaking changes to skill names or structure

## Quality Checklist

Before submitting a PR:

- [ ] Skill `description` includes when to trigger AND when NOT to trigger
- [ ] Skill `name` matches its directory name
- [ ] Agent file is placed in the `agents/` directory (auto-discovered)
- [ ] Content is actionable (commands, XML snippets, step-by-step fixes — not vague advice)
- [ ] Related skills are cross-referenced by name
- [ ] A sample project exists for the new skill (in `samples/`)
- [ ] `samples/README.md` matrix is updated
- [ ] No `bin/`, `obj/`, or `.binlog` files committed
- [ ] Agentic workflow templates use `safe-outputs:` with `max:` limits
- [ ] Agentic workflow templates use minimal `permissions:`
