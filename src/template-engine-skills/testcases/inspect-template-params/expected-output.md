# Expected Findings: inspect-template-params

## Problem Summary
User wants to understand all available parameters, constraints, and configuration options for the Worker Service template before creating a project.

## Expected Findings

### Template Identification
- **Template**: `worker` (Worker Service)
- **Full name**: Worker Service or ASP.NET Core Worker Service
- **Type**: project template

### Parameters
The agent should list parameters with their types, valid values, and defaults. Key parameters include:
- **Framework** (choice): Available TFMs (e.g., net9.0, net10.0) with default
- **use-program-main** (bool): Whether to use explicit Main method, default false
- **no-restore** (bool): Skip automatic restore
- Other parameters specific to the installed SDK version

### Parameter Details
For each parameter:
- Name and description
- Data type (choice, bool, string)
- Default value
- Valid values (for choice parameters)

### Constraints
- SDK version requirements (if any)
- OS constraints (if any)
- Workload requirements (if any)

### Post-Actions
- Whether NuGet restore runs automatically
- Any files opened after creation

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Correctly identified the worker template
- [ ] Listed the Framework parameter with valid choices
- [ ] Listed the use-program-main parameter with type and default
- [ ] Showed parameter types (choice, bool, string, etc.)
- [ ] Showed default values for parameters
- [ ] Listed valid values for choice parameters (framework versions)
- [ ] Mentioned any constraints or SDK requirements
- [ ] Mentioned post-actions (restore, file open)
- [ ] Information is accurate (matches actual template, not hallucinated)
- [ ] Response is well-structured and comprehensive

Total: __/10

## Expected Skills/Tools
- template_inspect
- template_list or template_search (to find the template first)
