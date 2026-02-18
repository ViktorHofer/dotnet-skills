# Repository Instructions

## Plugin Versioning

This repository contains plugins under `src/`. Each plugin has a `plugin.json` with a `version` field following [Semantic Versioning](https://semver.org/).

**When making changes to a plugin, always bump its version in `plugin.json`:**

| Change Type | Version Bump | Examples |
|-------------|-------------|----------|
| **Major** | `X.0.0` | Renaming or removing skills/agents, restructuring plugin layout, breaking changes to skill names or frontmatter contracts |
| **Minor** | `x.Y.0` | Adding new skills, adding new agents, adding new templates or prompts |
| **Patch** | `x.y.Z` | Fixing content in existing skills, typo corrections, updating examples, documentation improvements |

**Rules:**
- Bump the version in the same commit as the content change
- Reset lower version components when bumping a higher one (e.g., `2.3.1` → `3.0.0` for major)
- When multiple changes land in one commit, use the highest applicable bump

## Component Build Scripts

Each component under `src/` may have a `build.js` file at its root. When making changes to a component, run its build script to validate:

```bash
node src/<component>/build.js
```

This is an extension point — each component defines its own validation and build logic.

## Skill Conventions

Every skill's `description` field in its YAML frontmatter **must** include the domain gate text:

```
Only activate in MSBuild/.NET build contexts (see shared/domain-check.md for signals).
```

This ensures skills are only activated when the user is working in an MSBuild/.NET context. The `skills/shared/domain-check.md` file defines the relevance signals (high/medium/low confidence).

## Compiled Knowledge

Skill content is compiled into knowledge bundles for agentic workflows and the Copilot Extension. When modifying skills, regenerate compiled knowledge:

```bash
node eng/compile-knowledge.js
```

The workflow compiled output (`src/msbuild-skills/agentic-workflows/shared/compiled/`) and Copilot Extension compiled output (`src/msbuild-skills/copilot-extension/src/knowledge/`) are both checked in and must be committed alongside skill changes.
