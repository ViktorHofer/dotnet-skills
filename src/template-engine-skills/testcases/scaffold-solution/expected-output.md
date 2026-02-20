# Expected Findings: scaffold-solution

## Problem Summary
Create a multi-project solution structure (Web API + class library + test project) with proper organization and references.

## Expected Findings

### Solution Structure
- **Solution file**: `InventoryService.sln` at root
- **API project**: `src/InventoryService.Api/` (webapi template with controllers)
- **Domain library**: `src/InventoryService.Domain/` (classlib template)
- **Test project**: `test/InventoryService.Api.Tests/` (xunit template)

### Project References
- Test project → API project reference
- API project → Domain library reference

### Template Usage
- Uses appropriate templates: `webapi`, `classlib`, `xunit`
- Each project targets a consistent framework version
- UseControllers=true for the API project

### Organization
- Clean `src/` and `test/` directory separation
- All projects added to the solution file
- Consistent naming convention

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Created a solution file (InventoryService.sln)
- [ ] Created a Web API project with controllers (webapi template)
- [ ] Created a class library for domain models (classlib template)
- [ ] Created an xUnit test project (xunit template)
- [ ] Organized projects in src/ and test/ directories
- [ ] Added project reference: test → API
- [ ] Added project reference: API → domain library
- [ ] All projects added to the solution
- [ ] Consistent framework targeting across projects
- [ ] Projects created successfully and solution builds or is buildable

Total: __/10

## Expected Skills/Tools
- template_compose or multiple template_instantiate calls
- template_from_intent (optional, for resolving "webapi", "classlib", "xunit")
