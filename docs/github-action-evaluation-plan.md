# GitHub Action: Copilot Skills Evaluation - Planning Document

## Executive Summary

This document outlines the design for a GitHub Action that evaluates the quality of Copilot CLI responses when using MSBuild skills versus vanilla (unenhanced) Copilot CLI. The action runs test scenarios and produces comparative metrics.

**Key Design Decisions**:
- Use `copilot plugin install/uninstall` commands for plugin management (non-interactive)
- **Validate plugin state** with `copilot plugin list` before each run (catches installation bugs!)
- `--config-dir` does NOT isolate plugins - use actual install/uninstall instead
- Store expected outputs OUTSIDE scenario folders (prevents Copilot "cheating")
- Parse stats directly from `-p` mode output (no need for workarounds)
- Use `--no-ask-user` + `--allow-all-tools` + `--allow-all-paths` for full automation
- Don't specify model - use default (newest) and verify consistency

---

## 1. Requirements Summary

### 1.1 Trigger Conditions
- **Pull Requests** - Run on PRs to validate skills changes
- **Daily Schedule** - Automated regression testing
- **Manual Dispatch** - On-demand testing with configurable parameters

### 1.2 Local Development Support
- Must be runnable locally using **[act](https://github.com/nektos/act)** (local GitHub Actions runner)
- Environment variables and secrets should work both locally and in GitHub

### 1.3 Results Display
- **Job Summary** via `$GITHUB_STEP_SUMMARY` - visible on workflow run page
- **PR Comment** using `peter-evans/create-or-update-comment` - directly on PR
- Use **both** for maximum visibility

### 1.4 Test Scenarios
- Located in `evaluation/scenarios/`
- Each scenario is a self-contained build problem
- Expected outputs stored separately in `evaluation/expected-outputs/`

### 1.5 Comparison Methodology
- Run each scenario **twice**:
  1. **Vanilla**: Copilot CLI without skills plugin
  2. **With Skills**: Copilot CLI with the msbuild-skills plugin installed
- Capture output, timing, and token usage

### 1.6 Evaluation Method
- Use a **separate Copilot CLI instance** (vanilla) to evaluate/rank responses
- Compare actual output against expected output file
- Produce 1-5 quality rating across multiple dimensions

### 1.7 Artifacts
- Store all Copilot outputs as workflow artifacts
- Include detailed logs for troubleshooting

---

## 2. Technical Architecture

### 2.1 Directory Structure

```
viktor-dotnet-skills/
├── .github/
│   └── workflows/
│       └── copilot-skills-evaluation.yml
├── evaluation/
│   ├── scripts/
│   │   ├── run-scenario.ps1          # Runs a single scenario
│   │   ├── evaluate-response.ps1      # Evaluates response quality
│   │   ├── parse-copilot-stats.ps1    # Parses stats from output
│   │   └── generate-summary.ps1       # Generates markdown summary
│   ├── expected-outputs/              # ⚠️ OUTSIDE scenario folders!
│   │   └── bin-obj-clash.md           # Expected findings for bin-obj-clash
│   ├── scenarios/
│   │   └── bin-obj-clash/             # Contains ONLY build files
│   │       ├── ClashTest.slnx
│   │       ├── LibraryA/
│   │       ├── LibraryB/
│   │       └── MultiTargetLib/
│   └── results/                       # Generated at runtime
│       └── <run-id>/
│           ├── bin-obj-clash/
│           │   ├── vanilla-output.txt
│           │   ├── vanilla-stats.json
│           │   ├── skilled-output.txt
│           │   ├── skilled-stats.json
│           │   └── evaluation.json
│           └── summary.md
├── msbuild-skills/
│   └── ... (existing skills - installed as plugin)
└── docs/
    └── github-action-evaluation-plan.md
```

**Key Design Decision**: Expected outputs are stored OUTSIDE scenario folders to prevent Copilot from "cheating" by reading the expected answer.

### 2.2 Workflow Triggers

```yaml
on:
  pull_request:
    paths:
      - 'msbuild-skills/**'
      - 'evaluation/**'
      - '.github/workflows/copilot-skills-evaluation.yml'
  
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  
  workflow_dispatch:
    inputs:
      scenarios:
        description: 'Comma-separated scenario names (empty = all)'
        required: false
        default: ''
      skip_vanilla:
        description: 'Skip vanilla comparison (faster testing)'
        required: false
        type: boolean
        default: false
```

### 2.3 Plugin Management Strategy

#### Key Finding: `--config-dir` Does NOT Isolate Plugins

Testing confirmed that the `--config-dir` flag does **not** properly isolate plugin state. Plugins installed globally are visible regardless of `--config-dir` setting.

**Solution**: Use `copilot plugin install/uninstall` commands to manage plugin state between runs.

#### Plugin State Per Run

| Run Type | Before Run | Validation |
|----------|------------|------------|
| Vanilla | `copilot plugin uninstall msbuild-skills --force` | Assert NOT installed |
| Skilled | `copilot plugin install ./msbuild-skills` | Assert IS installed |
| Evaluator | `copilot plugin uninstall msbuild-skills --force` | Assert NOT installed |

#### Validation Function

```powershell
function Assert-PluginState {
    param(
        [string]$PluginName,
        [bool]$ShouldBeInstalled
    )
    
    $output = copilot plugin list 2>&1
    $isInstalled = $output -match $PluginName
    
    if ($ShouldBeInstalled -and -not $isInstalled) {
        throw "❌ VALIDATION FAILED: Plugin '$PluginName' should be installed but is NOT"
    }
    if (-not $ShouldBeInstalled -and $isInstalled) {
        throw "❌ VALIDATION FAILED: Plugin '$PluginName' should NOT be installed but IS"
    }
    
    Write-Host "✅ Plugin state validated: '$PluginName' installed=$isInstalled (expected=$ShouldBeInstalled)"
}
```

### 2.4 Copilot CLI Invocation

**Key Flags for Non-Interactive Mode**:

| Flag | Purpose |
|------|---------|
| `-p, --prompt` | Run in programmatic (non-interactive) mode |
| `--allow-all-tools` | Allow all tools without approval |
| `--allow-all-paths` | Skip path trust verification |
| `--allow-all-urls` | Skip URL verification |
| `--no-ask-user` | Disable clarifying questions (agent works autonomously) |
| `--yolo, --allow-all` | Enable all permissions at once |

**Example Invocation**:
```powershell
copilot -p "Analyze the problem with my build and suggest solution" `
  --allow-all-tools `
  --allow-all-paths `
  --no-ask-user `
  2>&1 | Tee-Object -FilePath output.txt
```

**Note**: Do NOT use `-s` / `--silent` as it suppresses stats output needed for metrics.

### 2.5 Timeout Wrapper

Add an external timeout to prevent infinite hangs:

```powershell
function Invoke-CopilotWithTimeout {
    param(
        [string]$Prompt,
        [string]$WorkingDir,
        [int]$TimeoutSeconds = 300  # 5 minutes default
    )
    
    $outputFile = Join-Path $WorkingDir "copilot-output.txt"
    
    $process = Start-Process -FilePath "copilot" `
        -ArgumentList @(
            "-p", "`"$Prompt`"",
            "--allow-all-tools",
            "--allow-all-paths",
            "--no-ask-user"
        ) `
        -WorkingDirectory $WorkingDir `
        -RedirectStandardOutput $outputFile `
        -RedirectStandardError "$outputFile.err" `
        -PassThru `
        -NoNewWindow
    
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    
    if (-not $completed) {
        $process.Kill()
        throw "Copilot timed out after $TimeoutSeconds seconds"
    }
    
    if ($process.ExitCode -ne 0) {
        $errorContent = Get-Content "$outputFile.err" -Raw -ErrorAction SilentlyContinue
        throw "Copilot failed with exit code $($process.ExitCode): $errorContent"
    }
    
    return Get-Content $outputFile -Raw
}
```

### 2.6 Capturing Metrics

Copilot CLI `-p` mode outputs detailed stats at the end of execution:

```
Total usage est:        6 Premium requests
API time spent:         14s
Total session time:     19s
Total code changes:     +0 -0
Breakdown by AI model:
 claude-opus-4.6         97.1k in, 370 out, 71.1k cached (Est. 6 Premium requests)
```

**Metrics to Capture**:

| Metric | Source | Parsing Pattern |
|--------|--------|-----------------|
| Premium Requests | `Total usage est:` line | `(\d+) Premium requests` |
| API Time | `API time spent:` line | `(\d+)s` |
| Total Time | `Total session time:` line | `(\d+)s` |
| Code Changes | `Total code changes:` line | `\+(\d+) -(\d+)` |
| Model Used | `Breakdown by AI model:` section | First model name |
| Tokens In | Model breakdown line | `([\d.]+)k in` |
| Tokens Out | Model breakdown line | `([\d+.]+) out` |
| Tokens Cached | Model breakdown line | `([\d.]+)k cached` |

**Parsing Script**:
```powershell
function Parse-CopilotStats {
    param([string]$Output)
    
    $stats = @{}
    
    if ($Output -match "Total usage est:\s+(\d+) Premium requests") {
        $stats.PremiumRequests = [int]$Matches[1]
    }
    if ($Output -match "API time spent:\s+(\d+)s") {
        $stats.ApiTimeSeconds = [int]$Matches[1]
    }
    if ($Output -match "Total session time:\s+(\d+)s") {
        $stats.TotalTimeSeconds = [int]$Matches[1]
    }
    if ($Output -match "Total code changes:\s+\+(\d+) -(\d+)") {
        $stats.LinesAdded = [int]$Matches[1]
        $stats.LinesRemoved = [int]$Matches[2]
    }
    # Model and tokens from breakdown
    if ($Output -match "^\s*([\w\-\.]+)\s+([\d.]+)k in,\s+(\d+) out,\s+([\d.]+)k cached") {
        $stats.Model = $Matches[1]
        $stats.TokensIn = [float]$Matches[2] * 1000
        $stats.TokensOut = [int]$Matches[3]
        $stats.TokensCached = [float]$Matches[4] * 1000
    }
    
    return $stats
}
```

**Model Verification**: After both runs, verify `$vanillaStats.Model -eq $skilledStats.Model` to ensure fair comparison.

### 2.7 Scenario Isolation

**Critical Requirements**:
1. Copilot must ONLY see the scenario folder (not expected outputs)
2. Scenario folder must be CLEAN before each run (no build artifacts, no previous outputs)
3. Different runs must not interfere with each other

**Pre-Run Cleanup Script**:
```powershell
function Clean-ScenarioFolder {
    param([string]$ScenarioPath)
    
    # Remove build artifacts
    Get-ChildItem -Path $ScenarioPath -Recurse -Directory -Include 'bin','obj' | 
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    # Remove any previous copilot outputs
    Get-ChildItem -Path $ScenarioPath -Recurse -File -Include '*.copilot.*','copilot-session-*' |
        Remove-Item -Force -ErrorAction SilentlyContinue
    
    # Remove SharedObj and SharedOutput contents (from bin-obj-clash sample)
    @('SharedObj', 'SharedOutput') | ForEach-Object {
        $path = Join-Path $ScenarioPath $_
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
```

**Run Sequence**:
1. Clean scenario folder
2. Uninstall plugin → Run vanilla Copilot → Save output
3. Clean scenario folder
4. Install plugin → Run skilled Copilot → Save output
5. Clean scenario folder
6. Uninstall plugin → Run evaluation Copilot (with access to results + expected outputs)

### 2.8 Evaluation Prompt

```markdown
You are evaluating the quality of an AI assistant's response to a build problem diagnosis task.

## Expected Output (Ground Truth)
[Contents of expected-outputs/<scenario>.md]

## Actual Response
[Contents of the Copilot output]

## Evaluation Criteria
Rate the response from 1-5 based on:
1. **Accuracy** - Did it correctly identify the problem?
2. **Completeness** - Did it find all issues mentioned in expected output?
3. **Actionability** - Are the suggested solutions practical and correct?
4. **Clarity** - Is the explanation clear and well-organized?

## Response Format
Respond with ONLY a JSON object:
{
  "score": <1-5>,
  "accuracy": <1-5>,
  "completeness": <1-5>,
  "actionability": <1-5>,
  "clarity": <1-5>,
  "reasoning": "<brief explanation>"
}
```

### 2.9 Result Classification

| Metric | Significantly Better | Somewhat Better | Similar | Somewhat Worse | Significantly Worse |
|--------|---------------------|-----------------|---------|----------------|---------------------|
| Quality (1-5) | +2 or more | +1 | 0 | -1 | -2 or more |
| Duration | <50% | 50-80% | 80-120% | 120-150% | >150% |
| Tokens | <50% | 50-80% | 80-120% | 120-150% | >150% |

### 2.10 Output Table Format (Job Summary)

```markdown
## Copilot Skills Evaluation Results

**Run Date**: 2026-02-13
**Trigger**: Pull Request #42
**Scenarios Tested**: 1

### Summary

| Scenario | Vanilla Quality | Skilled Quality | Quality Δ | Vanilla Time | Skilled Time | Time Δ | Winner |
|----------|-----------------|-----------------|-----------|--------------|--------------|--------|--------|
| bin-obj-clash | 2.5 | 4.5 | ✅ +2.0 | 45s | 52s | ⚠️ +15% | 🏆 Skilled |

### Overall Result: **Skills Improved Response Quality** ✅

### Detailed Results

<details>
<summary>bin-obj-clash</summary>

#### Vanilla Response Score: 2.5/5
- Accuracy: 2/5
- Completeness: 3/5
- Actionability: 2/5
- Clarity: 3/5

**Evaluation Notes**: Identified general build issues but missed specific bin/obj clash patterns.

#### Skilled Response Score: 4.5/5
- Accuracy: 5/5
- Completeness: 4/5
- Actionability: 5/5
- Clarity: 4/5

**Evaluation Notes**: Correctly identified all clash scenarios and provided specific remediation steps.

</details>
```

---

## 3. Implementation Plan

### Phase 1: Setup (Week 1)
1. Create evaluation directory structure
2. Copy first scenario from `check-bin-obj-clash/samples`
3. Create expected output file for the first scenario
4. Basic workflow YAML with triggers and environment setup

### Phase 2: Core Functionality (Week 2)
1. Implement `run-scenario.ps1` - Execute Copilot CLI and capture output
2. Implement `evaluate-response.ps1` - Use Copilot to score responses
3. Implement `parse-copilot-stats.ps1` - Parse metrics from output
4. Test locally with `act`

### Phase 3: Reporting (Week 3)
1. Implement `generate-summary.ps1` - Create markdown tables
2. Add Job Summary output (`$GITHUB_STEP_SUMMARY`)
3. Add PR Comment using `peter-evans/create-or-update-comment`
4. Configure artifact upload for logs and outputs

### Phase 4: Polish (Week 4)
1. Add more scenarios
2. Tune evaluation prompts
3. Add retry logic for flaky API calls
4. Documentation

---

## 4. Local Testing with `act`

### Prerequisites
```powershell
# Install act
winget install nektos.act
# Or via chocolatey
choco install act-cli
```

### Running Locally
```powershell
# Set up secrets file (.secrets)
echo "COPILOT_GITHUB_TOKEN=your_token_here" > .secrets

# Run the workflow
act -j evaluate --secret-file .secrets

# Run with specific event
act pull_request --secret-file .secrets

# Dry run (show what would happen)
act -n
```

### Local Environment Variables
```powershell
# For direct script testing
$env:COPILOT_GITHUB_TOKEN = "your_copilot_token"
$env:GH_TOKEN = $env:COPILOT_GITHUB_TOKEN  # Copilot CLI reads this
$env:GITHUB_TOKEN = "your_github_token"    # For GitHub API operations (optional locally)
```

---

## 5. Security Considerations

1. **Token Security**
   - Use GitHub Secrets for `COPILOT_GITHUB_TOKEN`
   - Never log tokens; use `::add-mask::` workflow command

2. **Fork PRs**
   - Secrets not available for PRs from forks
   - Consider using `pull_request_target` with caution, or skip evaluation for fork PRs

3. **Code Execution**
   - Copilot CLI with `--allow-all-tools` can execute arbitrary code
   - Run in isolated environment (GitHub-hosted runner)
   - Never run untrusted scenario files

---

## 6. Sample Workflow YAML

```yaml
name: Copilot Skills Evaluation

on:
  pull_request:
    paths:
      - 'msbuild-skills/**'
      - 'evaluation/**'
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch:
    inputs:
      scenarios:
        description: 'Scenarios to test (comma-separated, empty=all)'
        required: false
        default: ''

env:
  COPILOT_GITHUB_TOKEN: ${{ secrets.COPILOT_GITHUB_TOKEN }}  # For Copilot CLI authentication
  GH_TOKEN: ${{ secrets.COPILOT_GITHUB_TOKEN }}              # Copilot CLI reads this env var
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}                  # For GitHub API (PR comments, etc.)

jobs:
  evaluate:
    runs-on: windows-latest  # Windows for MSBuild scenarios
    timeout-minutes: 30
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Copilot CLI
        run: npm install -g @github/copilot

      - name: Create results directory
        run: |
          $runId = "${{ github.run_id }}-${{ github.run_attempt }}"
          New-Item -ItemType Directory -Force -Path "evaluation/results/$runId"
          echo "RUN_ID=$runId" >> $env:GITHUB_ENV
        shell: pwsh

      - name: Run Vanilla Copilot (no plugins)
        run: |
          # Ensure no custom plugins are installed
          copilot plugin uninstall msbuild-skills --force 2>$null
          
          # Validate plugin state
          $pluginList = copilot plugin list 2>&1
          if ($pluginList -match "msbuild-skills") {
            throw "❌ VALIDATION FAILED: msbuild-skills should NOT be installed for vanilla run"
          }
          Write-Host "✅ Validated: No msbuild-skills plugin installed"
          
          # Run evaluation script for vanilla
          pwsh -File ./evaluation/scripts/run-scenario.ps1 `
            -ScenarioName "bin-obj-clash" `
            -RunType "vanilla" `
            -ResultsDir "evaluation/results/$env:RUN_ID"
        shell: pwsh

      - name: Install Plugin and Run Skilled Copilot
        run: |
          # Install the plugin from local source
          copilot plugin install "${{ github.workspace }}/msbuild-skills"
          
          # Validate plugin is installed
          $pluginList = copilot plugin list 2>&1
          if ($pluginList -notmatch "msbuild-skills") {
            throw "❌ VALIDATION FAILED: msbuild-skills should be installed for skilled run"
          }
          Write-Host "✅ Validated: msbuild-skills plugin is installed"
          Write-Host "Installed plugins: $pluginList"
          
          # Run evaluation script for skilled
          pwsh -File ./evaluation/scripts/run-scenario.ps1 `
            -ScenarioName "bin-obj-clash" `
            -RunType "skilled" `
            -ResultsDir "evaluation/results/$env:RUN_ID"
        shell: pwsh

      - name: Uninstall Plugin and Run Evaluation
        run: |
          # Uninstall plugin for clean evaluation
          copilot plugin uninstall msbuild-skills --force
          
          # Validate plugin is removed
          $pluginList = copilot plugin list 2>&1
          if ($pluginList -match "msbuild-skills") {
            throw "❌ VALIDATION FAILED: msbuild-skills should NOT be installed for evaluation"
          }
          Write-Host "✅ Validated: No msbuild-skills plugin installed for evaluation"
          
          pwsh -File ./evaluation/scripts/evaluate-response.ps1 `
            -ScenarioName "bin-obj-clash" `
            -ResultsDir "evaluation/results/$env:RUN_ID" `
            -ExpectedOutputsDir "evaluation/expected-outputs"
        shell: pwsh

      - name: Generate Summary
        run: |
          pwsh -File ./evaluation/scripts/generate-summary.ps1 `
            -ResultsDir "evaluation/results/$env:RUN_ID"
          
          # Add to job summary
          Get-Content "evaluation/results/$env:RUN_ID/summary.md" >> $env:GITHUB_STEP_SUMMARY
        shell: pwsh

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: peter-evans/create-or-update-comment@v5
        with:
          issue-number: ${{ github.event.pull_request.number }}
          body-path: evaluation/results/${{ env.RUN_ID }}/summary.md
          edit-mode: replace

      - name: Upload Artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: evaluation-results-${{ env.RUN_ID }}
          path: evaluation/results/${{ env.RUN_ID }}/
          retention-days: 30
```

---

## 7. First Scenario: bin-obj-clash

### Source
Copy from `msbuild-skills/skills/check-bin-obj-clash/samples/`

### Expected Output

Store at `evaluation/expected-outputs/bin-obj-clash.md`:

```markdown
# Expected Findings: bin-obj-clash Scenario

## Problem Summary
This solution demonstrates MSBuild output path and intermediate output path clashes that cause build failures.

## Expected Findings

### 1. MultiTargetLib - Multi-targeting Clash
- **Issue**: Project multi-targets net8.0 and net9.0 but has `AppendTargetFrameworkToOutputPath=false`
- **Impact**: Both target frameworks write to the same output directory
- **Solution**: Remove `AppendTargetFrameworkToOutputPath=false` or ensure output paths are unique per target framework

### 2. LibraryA & LibraryB - Shared Output Path Clash
- **Issue**: Both projects share `../SharedOutput/` as their output path
- **Impact**: Build artifacts overwrite each other during parallel builds
- **Solution**: Give each project a unique output path

### 3. LibraryA & LibraryB - Shared Intermediate Path Clash
- **Issue**: Both projects share `../SharedObj/` as their intermediate output path
- **Impact**: `project.assets.json` and generated files conflict
- **Error**: "Cannot create a file when that file already exists" during NuGet restore
- **Solution**: Give each project a unique intermediate output path

## Key Concepts That Should Be Mentioned
- IntermediateOutputPath
- OutputPath
- AppendTargetFrameworkToOutputPath
- BaseIntermediateOutputPath
- Multi-targeting
- project.assets.json
- Parallel build conflicts
```

---

## 8. Appendix: Copilot CLI Reference

### Installation & Authentication
```bash
npm install -g @github/copilot

# Copilot CLI authentication (use GH_TOKEN)
export GH_TOKEN="your_copilot_token"

# Note: GITHUB_TOKEN is separate - used for GitHub API operations (PR comments, etc.)
```

### Plugin Management Commands
```bash
copilot plugin install <source>          # Install plugin from path or URL
copilot plugin uninstall <name>          # Uninstall plugin
copilot plugin list                      # List installed plugins
copilot plugin update <name>             # Update plugin
```

**Note**: Slash commands like `/plugin install` only work in interactive mode.

### Plugin Storage Locations
- Installed plugins: `~/.copilot/installed-plugins/`
- Configuration: `~/.copilot/config.json`

⚠️ `--config-dir` does NOT isolate plugin state. Plugins are always stored globally.

### Skills & Agents Locations (Auto-discovered)
- Project skills: `.github/skills/<skill-name>/SKILL.md`
- Personal skills: `~/.copilot/skills/<skill-name>/SKILL.md`
- Project agents: `.github/agents/<agent-name>.agent.md`
- Personal agents: `~/.copilot/agents/<agent-name>.agent.md`
