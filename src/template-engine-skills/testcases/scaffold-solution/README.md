# scaffold-solution

Tests whether the agent can create a multi-project solution with proper structure, references, and organization.

**What MCP adds**: `template_compose` can chain solution + webapi + classlib + xunit creation in one orchestrated workflow. `template_from_intent` resolves natural descriptions to templates. Vanilla Copilot typically runs multiple `dotnet new` commands with potential flag errors and may miss cross-project references.
