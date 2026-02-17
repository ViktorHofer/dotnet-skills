# MSBuild Agentic Workflow Templates

These are [GitHub Agentic Workflow](https://github.com/github/gh-aw) templates for MSBuild and .NET build automation.

## Available Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `build-failure-analysis.md` | CI build fails | Analyzes build failures and posts diagnostic comments on PRs |
| `msbuild-pr-review.md` | PR with MSBuild file changes | Reviews MSBuild project file changes for best practices |

## Shared Components

| Component | Description |
|-----------|-------------|
| `shared/binlog-mcp.md` | Configures the MSBuild binary log MCP server for analysis |
| `shared/msbuild-knowledge.md` | Core MSBuild expertise and error reference |

## Setup

1. Install the `gh aw` CLI extension
2. Copy the desired workflow files to your repository's `.github/workflows/` directory
3. Copy the `shared/` directory as well (workflows import from it)
4. Compile: `gh aw compile`
5. Commit both the `.md` and generated `.lock.yml` files
6. The workflows will now run automatically based on their triggers

## Customization

- Edit the `on:` section to match your CI workflow names
- Adjust `safe-outputs` limits as needed
- Add repository-specific MSBuild knowledge to `shared/msbuild-knowledge.md`
