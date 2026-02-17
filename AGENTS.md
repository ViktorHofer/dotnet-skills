# Repository Instructions

## Plugin Versioning

This repository contains plugins under `src/plugins/`. Each plugin has a `plugin.json` with a `version` field following [Semantic Versioning](https://semver.org/).

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
