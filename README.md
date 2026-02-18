# .NET Skills for AI Assistants

[![Dashboard](https://github.com/ViktorHofer/dotnet-skills/actions/workflows/pages/pages-build-deployment/badge.svg)](https://viktorhofer.github.io/dotnet-skills/dev/bench/)

This repository provides comprehensive .NET development expertise for AI assistants including [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli), [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview), and [GitHub Agentic Workflows](https://github.com/github/gh-aw).

## What's Included

| Component | Description |
|-----------|-------------|
| 🔧 [`msbuild-skills`](src/msbuild-skills/) | MSBuild and .NET build skills: failure diagnosis, performance optimization, code quality, and modernization |
| 🧪 [`dotnet-unittest-skills`](src/dotnet-unittest-skills/) | C# unit test generation guidance for MSTest, NUnit, and xUnit |
| 🌐 [`polyglot-unittest-skills`](src/polyglot-unittest-skills/) | Multi-agent pipeline for generating unit tests in any language |
| 📦 [`copilot-extension`](src/copilot-extension/) | Deployable `@msbuild` Copilot Extension for GitHub.com, VS Code, and Visual Studio |

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

### Agent Instructions (Zero Install)

Copy an `AGENTS.md` file to your repository root to provide expertise to Copilot, Claude Code, and other agents:
```bash
cp src/<component>/AGENTS.md AGENTS.md
```

### VS Code Prompt Files (Zero Install)

Copy prompt templates for use in Copilot Chat with `#prompt` references:
```bash
mkdir -p .github/prompts
cp src/<component>/prompts/*.prompt.md .github/prompts/
```

### Agentic Workflows

Copy the workflow templates (including the `shared/` directory) and compile with `gh aw`:
```bash
cp -r src/<component>/agentic-workflows/ .github/workflows/
gh aw compile
git add .github/workflows/
```

## Updating

```
/plugin update <plugin>@dotnet-skills
```

## Contributing

See [CONTRIBUTING](docs/CONTRIBUTING.md) for guidelines on adding skills, agents, prompt files, agentic workflows, samples, and more.

## License

See [LICENSE](LICENSE) for details.
