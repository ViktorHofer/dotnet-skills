# cpm-add-project

Tests whether the agent correctly handles Central Package Management when creating a new project in a CPM-enabled solution.

**What MCP adds**: `template_instantiate` automatically detects `Directory.Packages.props`, strips `Version` attributes from generated `.csproj` files, and adds `<PackageVersion>` entries to the props file. Vanilla Copilot typically creates projects with hardcoded versions that cause NU1008 build errors.
