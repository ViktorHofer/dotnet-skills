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

## Updating

```
/plugin update <plugin>@dotnet-skills
```

## Contributing

See [CONTRIBUTING](docs/CONTRIBUTING.md) for guidelines on adding skills, agents, prompt files, agentic workflows, samples, and more.

## License

See [LICENSE](LICENSE) for details.
