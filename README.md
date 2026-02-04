# .NET Skills for GitHub Copilot CLI / Claude Code

This repository hosts .NET-specific plugins for [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview). Each plugin provides specialized skills to assist with .NET development tasks.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [msbuild-skills](./msbuild-skills) | Skills for MSBuild development, including multithreaded task migration and binlog analysis |

## Installation

_The following instructions are written for GitHub Copilot CLI but work with Claude Code as well._

1. Launch GitHub Copilot CLI:
   ```bash
   copilot
   ```

2. Add the marketplace:
   ```
   /plugin marketplace add ViktorHofer/dotnet-skills
   ```

3. Browse available plugins in the marketplace:
   ```
   /plugin marketplace browse dotnet-skills
   ```

4. Install a plugin from the marketplace:
   ```
   /plugin install msbuild-skills@dotnet-skills
   ```

5. Restart Copilot CLI (type `/exit` and relaunch) to load the new skills.

6. The plugin's skills will now be available to Copilot in your sessions.

## Updating Plugins

To update plugins from the marketplace and get the latest version:

```
/plugin update msbuild-skills@dotnet-skills
```

## Adding New Plugins

To add a new plugin to this repository:

1. Create a new subdirectory for your plugin
2. Add a `plugin.json` manifest:
   ```json
   {
     "name": "my-plugin",
     "version": "1.0.0",
     "description": "Description of what the plugin does.",
     "skills": ["./skills/"]
   }
   ```
3. Add skills in a `skills/` subdirectory, each with a `SKILL.md` file
4. Add an `mcpServers` entry if the plugin uses mcp server.
5. Update this README to include your plugin in the table
