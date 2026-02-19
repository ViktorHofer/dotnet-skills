# Expected Findings: eval-heavy

## Problem Summary
A .NET project with multiple MSBuild evaluation-phase anti-patterns causing slow project evaluation. The issues span property functions, glob expansion, import chains, and UsingTask registration — all happening during the evaluation phase before any targets run.

## Expected Findings

### 1. Deep Import Chain
- **Issue**: Project imports `level1.props` which imports `level2.props` which imports `level3.props` — creating a nested import chain. Each import requires file I/O and parsing during evaluation.
- **Solution**: Flatten the import chain by consolidating into fewer files, or at minimum document the chain for maintainability.

### 2. Overly Broad Glob Pattern
- **Issue**: `<AdditionalFiles Include="**\*.*" Exclude="**\bin\**;**\obj\**" />` uses a wildcard that scans the ENTIRE directory tree for all file types. Even with `bin`/`obj` excluded, this still scans `.git/`, `node_modules/`, test data directories, etc. — potentially matching thousands of irrelevant files.
- **Solution**: Use `<DefaultItemExcludes>` to exclude known large directories (`.git`, `node_modules`, `packages`), or restrict globs to specific extensions and directories: `src/**/*.config` instead of `**/*.*`.

### 3. Property Function File I/O During Evaluation
- **Issue**: `$([System.IO.File]::ReadAllText('build-notes.txt'))` executes during the property evaluation phase. This runs on EVERY evaluation pass — not just during builds, but also during IDE design-time evaluations (IntelliSense, solution load, etc.). In VS, a project may be evaluated hundreds of times during an editing session.
- **Solution**: Move file-reading logic to a target (execution phase) using `<ReadLinesFromFile>` task, which only runs when the target is invoked.

### 4. UsingTask with RoslynCodeTaskFactory During Evaluation
- **Issue**: The `UsingTask` with `TaskFactory="RoslynCodeTaskFactory"` is processed during evaluation phase 5 (UsingTask evaluation). While the inline task code isn't compiled until first use, the task registration and factory loading adds overhead to every evaluation pass.
- **Solution**: Move inline tasks to a separate `.targets` file that is only imported when the task is actually needed, or consider converting to a compiled task assembly.

### 5. Evaluation Phase vs Execution Phase Distinction
- **Issue**: All of the above issues (globs, property functions, imports, UsingTask) run during the **evaluation phase** — before any targets execute. This means they affect project load time, IDE responsiveness, and design-time builds, not just actual compilation.
- **Key insight**: Use `/pp` (preprocess) to see the fully expanded project and understand evaluation cost. Use binlog `list_evaluations` to check how many times the project is evaluated — multiple evaluations multiply all these costs.

## Key Concepts That Should Be Mentioned
- MSBuild evaluation phase vs execution phase (evaluation happens before any targets run)
- The 5 evaluation phases: properties, imports, item definitions, items (glob expansion), UsingTask
- `DefaultItemExcludes` property for excluding directories from glob expansion
- Property functions execute during evaluation — every evaluation pass
- `/pp` (preprocess) for analyzing fully expanded project
- Multiple evaluations concept — project may be evaluated more than once
- Design-time evaluations in Visual Studio compound evaluation costs
- `ReadLinesFromFile` task as the execution-phase alternative to `File.ReadAllText`

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified deep import chain (level1→level2→level3)
- [ ] Identified overly broad glob pattern (`**\*.*`) and explained it scans large directories
- [ ] Mentioned `DefaultItemExcludes` by name as the correct solution for glob scope
- [ ] Identified `File.ReadAllText` property function executing during evaluation phase
- [ ] Explained the distinction between evaluation phase and execution phase
- [ ] Explained that evaluation-phase issues affect IDE/design-time builds, not just compilation
- [ ] Suggested moving file I/O to a target using `ReadLinesFromFile` or similar execution-phase task
- [ ] Identified UsingTask with RoslynCodeTaskFactory as adding evaluation overhead
- [ ] Mentioned `/pp` (preprocess) as a diagnostic technique for evaluation analysis
- [ ] Suggested checking evaluation count (multiple evaluations multiply all costs)

Total: __/10

## Expected Skills
- eval-performance
