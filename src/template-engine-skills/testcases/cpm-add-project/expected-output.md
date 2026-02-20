# Expected Findings: cpm-add-project

## Problem Summary
Add a class library to a solution that uses Central Package Management (CPM). The agent must recognize the `Directory.Packages.props` file and handle package versions correctly.

## Context
The working directory contains:
- `Directory.Packages.props` with `ManagePackageVersionsCentrally=true` and existing package versions
- `ExistingProject/ExistingProject.csproj` with PackageReferences that have no Version attributes (CPM-compliant)

## Expected Findings

### CPM Awareness
- **Detect CPM**: Agent should recognize `Directory.Packages.props` and understand this is a CPM-enabled solution
- **No hardcoded versions**: The new .csproj should NOT have `Version` attributes on PackageReference items
- **Props file updates**: Any new packages should be added to `Directory.Packages.props`, not the .csproj

### Project Creation
- **Template**: `classlib` (Class Library)
- **Name**: `SharedModels`
- **Output**: `src/SharedModels` subdirectory
- **Framework**: Should match existing project (net9.0) or use latest

### Post-Creation Handling
- If the template generates PackageReferences with hardcoded versions, they should be stripped
- New PackageVersion entries should be added to Directory.Packages.props
- Existing entries in Directory.Packages.props should NOT be duplicated

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Recognized that this is a CPM-enabled solution (Directory.Packages.props exists)
- [ ] Selected the correct template (classlib)
- [ ] Named the project SharedModels
- [ ] Created the project in src/SharedModels directory
- [ ] Ensured no Version attributes on PackageReferences in the new .csproj
- [ ] Added any new package versions to Directory.Packages.props (if packages were added)
- [ ] Did not duplicate existing entries in Directory.Packages.props
- [ ] Project was created successfully
- [ ] Response explains CPM handling or mentions version management
- [ ] Framework choice is appropriate (matches existing or uses latest)

Total: __/10

## Expected Skills/Tools
- template_instantiate (with CPM post-creation processing)
- template_from_intent (optional)
