# .NET Skills for AI Assistants

[![Dashboard](https://github.com/ViktorHofer/dotnet-skills/actions/workflows/pages/pages-build-deployment/badge.svg)](https://viktorhofer.github.io/dotnet-skills/dev/bench/)

This repository provides comprehensive .NET development expertise for AI assistants including [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli), [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview), and [GitHub Agentic Workflows](https://github.com/github/gh-aw).

## What's Included

| Component | Description |
|-----------|-------------|
| [`msbuild-skills`](src/msbuild-skills/) | MSBuild and .NET build skills: failure diagnosis, performance optimization, code quality, and modernization |
| [`dotnet-unittest-skills`](src/dotnet-unittest-skills/) | C# unit test generation guidance for MSTest, NUnit, and xUnit |
| [`polyglot-unittest-skills`](src/polyglot-unittest-skills/) | Multi-agent pipeline for generating unit tests in any language |

## Installation

### Copilot CLI / Claude Code

1. Launch Copilot CLI or Claude Code
2. Add the marketplace:
   ```
   /plugin marketplace add ViktorHofer/dotnet-skills
   ```
3. Install a plugin:
   ```
   /plugin install <plugin>@dotnet-skills
   ```
4. Restart to load the new plugins
5. View available skills:
   ```
   /skills
   ```
6. View available agents:
   ```
   /agents
   ```

### Distribution Templates

Some components include ready-to-use templates (agent instructions, prompt files) that can be copied directly into your repository without installing a component:

1. Browse the component's **Distribution Templates** section in its README
2. Copy agent instructions to your repo root as `AGENTS.md`
3. Copy prompt files to `.github/prompts/`

### Agentic Workflows

Some components include [GitHub Agentic Workflow](https://github.com/github/gh-aw) templates for CI/CD automation:

1. Install the `gh aw` CLI extension
2. Copy the desired workflow `.md` files and the `shared/` directory to your repository's `.github/workflows/`
3. Compile and commit:
   ```
   gh aw compile
   ```
4. Commit both the `.md` and generated `.lock.yml` files

### Copilot Extension

Some components include a deployable [Copilot Extension](https://docs.github.com/copilot/building-copilot-extensions) for GitHub.com, VS Code, and Visual Studio:

1. Find the extension in the [GitHub Marketplace](https://github.com/marketplace) or your organization's Copilot Extensions
2. Install the GitHub App on your organization or personal account
3. Use `@<extension-name>` in any Copilot Chat surface to interact with it

## Updating

```
/plugin update <plugin>@dotnet-skills
```

## Contributing

See [CONTRIBUTING](docs/CONTRIBUTING.md) for guidelines on adding skills, agents, prompt files, agentic workflows, samples, and more.

## License

See [LICENSE](LICENSE) for details.
