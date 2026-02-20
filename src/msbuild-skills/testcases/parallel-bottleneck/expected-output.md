# Expected Findings: parallel-bottleneck

## Problem Summary
A solution with 4 projects forming a deep serial dependency chain (Core→Api→Web→Tests), preventing any build parallelism even with `-m`. Additionally, `Directory.Build.props` contains a spurious `MaxCpuCount` property that has no effect on build parallelism.

## Expected Findings

### 1. Serial Dependency Chain
- **Issue**: All projects form a single serial chain: Core → Api → Web → Tests. Each project depends on the previous, so MSBuild must build them sequentially even with `/maxcpucount`.
- **Impact**: Build parallelism is impossible — only one CPU core is utilized. The critical path equals the total build time.
- **Evidence**: Build with binlog and use node timeline analysis (`get_node_timeline()`) to see sequential execution with idle nodes.

### 2. Unnecessary Transitive Dependencies
- **Issue**: Tests depends on both Web and Api, but Web already depends on Api. The explicit `Api` reference in Tests is redundant. While not harmful to correctness, it clutters the dependency graph and can confuse analysis.
- **Solution**: Remove the redundant `<ProjectReference Include="..\Api\Api.csproj" />` from Tests since it's already transitively resolved via Web.

### 3. MaxCpuCount Property Has No Effect
- **Issue**: `Directory.Build.props` sets `<MaxCpuCount>8</MaxCpuCount>` as a project property. This has **no effect** — `/maxcpucount` (or `-m`) is a command-line argument to MSBuild, not a project property. Setting it in a props file does nothing.
- **Solution**: Remove the property. Use `dotnet build -m` on the command line instead.

### 4. Graph Build Mode Opportunity
- **Issue**: For a solution with serial dependencies, `/graph` build mode can improve scheduling by constructing the full dependency graph upfront and enabling isolated builds. This avoids redundant evaluations when the same project is referenced multiple times.
- **Solution**: Use `dotnet build /graph -m` for better scheduling and isolated builds.

### 5. Build-Order-Only Reference Opportunity
- **Issue**: If Tests only needs to ensure Web is built before it runs (for integration testing) but doesn't compile against Web's types directly, the reference could be made build-order-only using `ReferenceOutputAssembly="false"`. This can reduce the coupling and allow more parallelism in dependency resolution.
- **Solution**: Evaluate whether `<ProjectReference Include="..\Web\Web.csproj" ReferenceOutputAssembly="false" />` is appropriate for the Tests→Web reference.

## Key Concepts That Should Be Mentioned
- MSBuild project dependency graph and topological sort
- `/maxcpucount` (`-m`) is a command-line setting, not a project property
- Critical path in dependency graph
- Node timeline analysis from binlog (`get_node_timeline()`)
- `/graph` build mode for better scheduling
- `ReferenceOutputAssembly="false"` for build-order-only dependencies
- Redundant transitive `<ProjectReference>` cluttering dependency graph

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified serial dependency chain (Core→Api→Web→Tests)
- [ ] Explained that serial chain prevents build parallelism even with `-m`
- [ ] Used binlog analysis to diagnose parallelism (node timeline, build with /bl)
- [ ] Identified MaxCpuCount property in Directory.Build.props has no effect (command-line only)
- [ ] Identified redundant transitive ProjectReference (Tests→Api already resolved via Web)
- [ ] Mentioned critical path concept — the longest chain determines minimum build time
- [ ] Suggested `/graph` build mode for better scheduling
- [ ] Suggested `ReferenceOutputAssembly="false"` for build-order-only references
- [ ] Provided specific restructuring suggestions to enable parallelism
- [ ] Analyzed whether Tests truly needs the full Web→Api→Core chain or could be flattened

Total: __/10

## Expected Skills
- build-parallelism
- binlog-generation
