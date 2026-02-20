# Build Parallelism — Serial Bottleneck

A solution with a deep serial dependency chain: Core → Api → Web → Tests.

## Issues Present

### Surface-Level (any LLM should find)  
1. **Serial dependency chain**: Core → Api → Web → Tests — no parallelism opportunity
2. **Redundant transitive reference**: Tests references both Web and Api, but Api is already transitive via Web

### Subtle (requires specialized knowledge)
3. **Spurious MaxCpuCount property**: `Directory.Build.props` sets `<MaxCpuCount>8</MaxCpuCount>` — has no effect; `/maxcpucount` is a command-line argument only
4. **No `/graph` build mode**: Not using graph build which would improve scheduling for serial chains
5. **Build-order-only opportunity**: `ReferenceOutputAssembly="false"` not considered for test→app references

## Skills Tested

- `build-parallelism` — Dependency graph analysis, `/graph` mode, `ReferenceOutputAssembly`, node timeline
- `binlog-generation` — Binary log analysis for parallelism diagnosis

## How to Test

```bash
dotnet build ParallelTest.sln -m /bl:parallel.binlog
# Analyze: get_node_timeline() should show poor utilization
```
