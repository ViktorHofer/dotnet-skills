# create-webapi-auth

Tests whether the agent can create a Web API project with specific parameters (controllers, auth, HTTPS, latest framework) using MCP tools vs. raw CLI guessing.

**What MCP adds**: `template_from_intent` resolves "web API with auth and controllers" to the correct template + parameters. `template_instantiate` validates parameters and applies smart defaults (UseControllers=true → UseMinimalAPIs=false). Vanilla Copilot typically guesses CLI flags and may need multiple attempts.
