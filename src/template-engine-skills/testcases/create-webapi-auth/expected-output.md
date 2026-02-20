# Expected Findings: create-webapi-auth

## Problem Summary
Create an ASP.NET Web API project with specific parameters: controllers, Individual auth, HTTPS, latest framework.

## Expected Findings

### Template Selection
- **Correct template**: `webapi` (ASP.NET Core Web API)
- **Not acceptable**: Using `dotnet new` with wrong flags, guessing parameters, or creating files manually

### Parameter Configuration
- **UseControllers**: `true` (not minimal APIs)
- **auth**: `Individual` (Individual authentication)
- **UseHttps**: `true` (HTTPS enabled)
- **Framework**: Latest available (net9.0 or net10.0)
- **Project name**: `OrderService`

### Smart Defaults
- Setting `UseControllers=true` should also set `UseMinimalAPIs=false` (mutual exclusion)
- Setting `auth=Individual` should ensure HTTPS is enabled (security requirement)

### Output Quality
- Project should be created successfully with all specified features
- Response should confirm what was created and what parameters were applied
- File structure should include a Controllers directory

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Selected the correct template (webapi)
- [ ] Set UseControllers to true
- [ ] Set auth to Individual
- [ ] Ensured HTTPS is enabled
- [ ] Targeted the latest available framework
- [ ] Named the project OrderService
- [ ] Created the project successfully (files on disk)
- [ ] Mentioned or applied smart defaults (UseMinimalAPIs=false)
- [ ] Response includes confirmation of what was created
- [ ] Used structured template tools (not raw dotnet new CLI with guessed flags)

Total: __/10

## Expected Skills/Tools
- template_from_intent or template_instantiate
- template_inspect (optional, for parameter discovery)
