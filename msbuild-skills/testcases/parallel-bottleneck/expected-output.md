# Expected Findings: parallel-bottleneck

## Problem Summary
A solution with 4 projects forming a deep serial dependency chain (Core→Api→Web→Tests), preventing any build parallelism even with `-m`.

## Expected Findings

### 1. Serial Dependency Chain
- **Issue**: All projects form a single serial chain: Core → Api → Web → Tests. Each project depends on the previous, so MSBuild must build them sequentially even with `/maxcpucount`
- **Impact**: Build parallelism is impossible — only one CPU core is utilized
- **Evidence**: Node timeline in binlog should show sequential execution with idle cores

### 2. Unnecessary Transitive Dependencies
- **Issue**: Tests depends on both Web and Api, but Web already depends on Api, making the explicit Api dependency on Tests redundant (though not harmful). The real issue is whether Tests truly needs to depend on Web, or could depend on Api or Core directly.
- **Solution**: Analyze whether dependency chain can be flattened — e.g., can Tests depend on Core + Api without going through Web?

## Key Concepts That Should Be Mentioned
- MSBuild project dependency graph and topological sort
- /maxcpucount (-m) and parallel scheduling
- Critical path in dependency graph
- Node timeline analysis from binlog
- ProjectReference graph optimization
