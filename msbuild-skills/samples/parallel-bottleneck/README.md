# Build Parallelism — Serial Bottleneck

A solution with a deep serial dependency chain: Core → Api → Web → Tests.

## Issue

All 4 projects form a single serial chain with no parallelism opportunity:
```
Core → Api → Web → Tests
```

With `-m` (maxcpucount), MSBuild can only build one project at a time because each depends on the previous.

## Skills Tested

- `build-parallelism` — Dependency graph analysis, identifying serial bottlenecks

## How to Test

```bash
dotnet build ParallelTest.sln -m /bl:parallel.binlog
# Analyze: get_node_timeline() should show poor utilization
```

## Potential Improvements

- Can Tests depend directly on Core instead of through Web?
- Can any project reference be removed or made build-order-only?
- Consider if Api and Web could be independent (parallel) instead of chained
