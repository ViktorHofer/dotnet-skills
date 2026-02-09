# ClashTest - BinClash Sample Repository

This repository contains sample projects demonstrating different types of MSBuild binclash scenarios.

## What is BinClash?

BinClash occurs when multiple build targets attempt to write to the same output location, causing file conflicts during parallel builds.

## Sample Projects

### 1. MultiTargetLib - Output Path BinClash

**Location:** `MultiTargetLib/`

This project demonstrates a binclash in the **output path** caused by multi-targeting with disabled target framework path appending.

**Configuration:**
- Multi-targets `net8.0` and `net9.0`
- Sets `AppendTargetFrameworkToOutputPath` to `false`

**Problem:** When building for multiple target frameworks, both `net8.0` and `net9.0` outputs are written to the same output directory, causing file conflicts.

### 2. LibraryA & LibraryB - Intermediate Output Path BinClash

**Location:** `LibraryA/` and `LibraryB/`

These projects demonstrate a binclash in the **intermediate output path** caused by sharing a common intermediate directory.

**Configuration:**
- Both projects use a shared intermediate path: `..\SharedObj\`
- Both projects use a shared output path: `..\SharedOutput\`
- Both disable `AppendTargetFrameworkToOutputPath` and `AppendTargetFrameworkToIntermediateOutputPath`

**Problem:** When building both projects in parallel, they write intermediate files (like `.obj` files, generated sources, etc.) to the same `SharedObj` directory, causing file conflicts.

## Reproducing the Issues

Build the solution with parallel builds enabled:
```bash
dotnet build ClashTest.slnx -m
```