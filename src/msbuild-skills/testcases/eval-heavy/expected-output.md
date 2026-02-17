# Expected Findings: eval-heavy

## Problem Summary
A .NET project with three MSBuild evaluation-phase anti-patterns causing slow project evaluation.

## Expected Findings

### 1. Deep Import Chain
- **Issue**: Project imports `level1.props` which imports `level2.props` which imports `level3.props` — creating a deep import chain that adds evaluation overhead
- **Solution**: Flatten the import chain or reduce unnecessary nesting

### 2. Overly Broad Glob Pattern
- **Issue**: An `<ItemGroup>` uses `**/*.*` or similar broad glob pattern that would scan all directories including node_modules, .git, bin, obj, etc.
- **Solution**: Restrict globs to specific file extensions and directories; use `DefaultItemExcludes` to exclude known-large directories

### 3. Property Function File I/O During Evaluation
- **Issue**: A property uses `$([System.IO.File]::ReadAllText(...))` or similar property function that performs file I/O during project evaluation phase
- **Solution**: Move file-reading logic to a target (execution phase) instead of property evaluation

## Key Concepts That Should Be Mentioned
- MSBuild evaluation phase vs execution phase
- Import chain depth impact on evaluation performance
- Glob pattern expansion performance
- DefaultItemExcludes
- Property functions and their cost during evaluation
- /pp (preprocess) for analyzing evaluation output
