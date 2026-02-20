# ClashTest - BinClash Sample Repository

This repository contains sample projects demonstrating different types of MSBuild output path clash scenarios.

## What is BinClash?

BinClash occurs when multiple MSBuild project evaluations write to the same output or intermediate directories, causing file conflicts during parallel builds.

## Issues (Surface Level)

### 1. MultiTargetLib - Multi-targeting Clash
- Multi-targets `net8.0` and `net9.0` with `AppendTargetFrameworkToOutputPath=false` and `AppendTargetFrameworkToIntermediateOutputPath=false`
- Both TFMs write to the same directories

### 2. LibraryA & LibraryB - Shared Output Path
- Both projects set `BaseOutputPath=..\SharedOutput\`
- Build artifacts overwrite each other

### 3. LibraryA & LibraryB - Shared Intermediate Path
- Both projects set `BaseIntermediateOutputPath=..\SharedObj\`
- `project.assets.json` conflicts during restore

## Issues (Subtle / Skill-Specific)

### 4. AppendTargetFramework Cannot Fix Shared BaseIntermediateOutputPath
- Even re-enabling `AppendTargetFrameworkToIntermediateOutputPath=true` won't fix LibraryA/B — NuGet writes `project.assets.json` directly to `BaseIntermediateOutputPath` without the TFM subfolder
- Only fix is unique `BaseIntermediateOutputPath` per project

### 5. Binlog-Based Detection
- Systematic clash detection via binlog: load binlog → list evaluations → compare OutputPath/IntermediateOutputPath — more reliable than manual csproj inspection