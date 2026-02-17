# MSBuild Copilot Extension — Design Document

## Overview

A GitHub Copilot Extension that provides MSBuild expertise across all Copilot Chat surfaces (GitHub.com, VS Code, Visual Studio). Unlike the CLI plugin (which requires explicit installation), a Copilot Extension is a GitHub App that organizations install once and all members benefit.

## Why an Extension?

| Mechanism | Reach | Install Effort | Works In |
|-----------|-------|---------------|----------|
| CLI Plugin | Individual users | Manual per-user | Copilot CLI only |
| Custom Instructions | Per-repo | Copy file to repo | GitHub.com, VS Code, VS |
| **Copilot Extension** | **Org-wide** | **One-time org install** | **GitHub.com, VS Code, VS** |

The extension provides the broadest reach with the least friction.

## Architecture

```
User in Copilot Chat
        │
        ▼
GitHub Copilot Platform
        │
        ▼ (routes @msbuild mentions)
MSBuild Copilot Extension (GitHub App)
        │
        ├── Knowledge Base (embedded from skills repository)
        │   ├── Build error catalog
        │   ├── Performance optimization guides
        │   └── Style guide & modernization
        │
        ├── Binlog MCP Server (for deep analysis)
        │
        └── GitHub API (read repo context)
```

## Key Capabilities

1. **Build failure assistance**: `@msbuild help me fix this build error` → lookup in error knowledge base
2. **Performance advice**: `@msbuild why is my build slow?` → analysis guidance
3. **Project file review**: `@msbuild review my csproj` → style guide checks
4. **Modernization help**: `@msbuild modernize this project` → migration guidance

## Implementation Options

### Option A: Serverless (Recommended for MVP)
- **Runtime**: Azure Functions or AWS Lambda
- **Knowledge**: Embed skill content as system prompts
- **No binlog analysis**: Just knowledge-based assistance
- **Pros**: Simple, low cost, fast to build
- **Cons**: Can't analyze binlogs or run builds

### Option B: Full Agent
- **Runtime**: Container-based service (Azure Container Apps, GitHub Codespaces)
- **Knowledge**: Full skill set + binlog MCP server
- **Can**: Run builds, analyze binlogs, apply fixes
- **Pros**: Full capability
- **Cons**: Higher cost, complexity, security considerations

### Recommended Approach
Start with Option A for broad reach, then expand to Option B for users who need deep analysis.

## Implementation Steps

1. **Register GitHub App** with Copilot Extension capabilities
2. **Build backend**: serverless function that receives Copilot messages
3. **Embed knowledge**: compile skill content into system prompts
4. **Add routing**: detect MSBuild-related queries vs. general queries
5. **Test**: verify across GitHub.com, VS Code, VS
6. **Publish**: list on GitHub Marketplace

## Open Questions

- Should the extension be free or part of a paid tier?
- What's the token/context budget for embedded knowledge?
- How to handle repo-specific context (the extension doesn't have file access by default)?
- Should we support custom knowledge overlays per organization?

## Status: Design Phase
This document captures the design direction. Implementation is a separate initiative pending resource allocation.
