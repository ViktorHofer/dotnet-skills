<#
.SYNOPSIS
    Runs a single evaluation scenario against Copilot CLI.

.DESCRIPTION
    Copies the testcase's project files to a clean temp directory,
    executes Copilot CLI in programmatic mode there, captures output and stats,
    saves results to the results directory, and cleans up the temp copy.

.PARAMETER ScenarioName
    Name of the testcase folder under the scenarios base directory.
    Each testcase folder must contain project files and optionally
    an 'expected-output.md' for evaluation and 'eval-test-prompt.txt' for custom prompts.

.PARAMETER RunType
    Either "vanilla" (no plugins) or "skilled" (with the skills plugin).

.PARAMETER ResultsDir
    Path to the results directory for this run.

.PARAMETER TimeoutSeconds
    Maximum time to wait for Copilot CLI to complete (default: 300).

.PARAMETER ScenariosBaseDir
    Path to the testcases directory. Can be relative (resolved against RepoRoot)
    or absolute.

.PARAMETER RepoRoot
    Root directory of the repository. Defaults to two levels up from this script.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ScenarioName,

    [Parameter(Mandatory)]
    [ValidateSet("vanilla", "skilled")]
    [string]$RunType,

    [Parameter(Mandatory)]
    [string]$ResultsDir,

    [int]$TimeoutSeconds = 300,

    [string]$ScenariosBaseDir,

    [Parameter(Mandatory)]
    [string]$RunId,

    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

# Resolve repo root
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\")).Path
}

# Import helper functions
. (Join-Path $PSScriptRoot "parse-copilot-stats.ps1")

#region Helper Functions

function Get-SkillActivation {
    param(
        [string]$ConfigDir
    )

    $sessionStateDir = Join-Path $ConfigDir "session-state"
    if (-not (Test-Path $sessionStateDir)) {
        Write-Warning "[ACTIVATION] No session-state directory found at $sessionStateDir"
        return @{
            SessionId = $null
            Skills    = @()
            Agents    = @()
            Activated = $false
        }
    }

    $sessionDir = Get-ChildItem $sessionStateDir -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $sessionDir) {
        Write-Warning "[ACTIVATION] No session directories found in $sessionStateDir"
        return @{
            SessionId = $null
            Skills    = @()
            Agents    = @()
            Activated = $false
        }
    }

    $eventsFile = Join-Path $sessionDir.FullName "events.jsonl"
    if (-not (Test-Path $eventsFile)) {
        Write-Warning "[ACTIVATION] No events.jsonl found at $eventsFile"
        return @{
            SessionId = $sessionDir.Name
            Skills    = @()
            Agents    = @()
            Activated = $false
        }
    }

    $lines = Get-Content $eventsFile -ErrorAction SilentlyContinue
    $skills = @()
    $agents = @()

    foreach ($line in $lines) {
        $e = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $e) { continue }
        # Check for skill tool calls
        if ($e.type -eq "tool.execution_start" -and $e.data.toolName -eq "skill") {
            $skillName = $e.data.arguments.skill
            if ($skillName -and $skills -notcontains $skillName) {
                $skills += $skillName
            }
        }
        # Check for subagent delegation
        if ($e.type -eq "subagent.started") {
            $agentName = $e.data.agentName
            if ($agentName -and $agents -notcontains $agentName) {
                $agents += $agentName
            }
        }
    }

    return @{
        SessionId = $sessionDir.Name
        Skills    = $skills
        Agents    = $agents
        Activated = ($skills.Count -gt 0 -or $agents.Count -gt 0)
    }
}

function Copy-ScenarioToTemp {
    param(
        [string]$ScenarioSourceDir,
        [string]$ScenarioName,
        [string]$RunType
    )

    $tempBase = Join-Path ([System.IO.Path]::GetTempPath()) "copilot-eval"
    $tempDir = Join-Path $tempBase "${ScenarioName}-${RunType}-$(Get-Random)"

    Write-Host "[COPY] Copying scenario to temp directory: $tempDir"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    Copy-Item -Path "$ScenarioSourceDir\*" -Destination $tempDir -Recurse -Force

    # Remove evaluation and documentation files from temp copy
    $excludeFiles = @("expected-output.md", "eval-test-prompt.txt", "README.md", "DEMO.md", ".gitignore")
    foreach ($file in $excludeFiles) {
        $filePath = Join-Path $tempDir $file
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
            Write-Host "[CLEAN] Excluded $file from working directory"
        }
    }

    Write-Host "[OK] Scenario copied to clean working directory"

    return $tempDir
}

function Invoke-CopilotWithTimeout {
    param(
        [string]$Prompt,
        [string]$WorkingDir,
        [string]$OutputFile,
        [int]$TimeoutSeconds = 300,
        [string]$ConfigDir = ""
    )

    Write-Host "[RUN] Running Copilot CLI..."
    Write-Host "   Working directory: $WorkingDir"
    Write-Host "   Timeout: ${TimeoutSeconds}s"
    Write-Host "   Prompt: $Prompt"

    $errorFile = "${OutputFile}.err"

    # Resolve copilot executable - prefer .cmd/.bat/.exe for Process.Start compatibility
    # Use -All to search across all PATH entries, not just the first match
    $copilotCmd = Get-Command copilot -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq 'Application' } |
        Select-Object -First 1 -ExpandProperty Source

    $configDirArg = ""
    if ($ConfigDir -and $ConfigDir -ne "") {
        $configDirArg = " --config-dir `"$ConfigDir`""
    }

    if (-not $copilotCmd) {
        if ($env:OS -match 'Windows') {
            # Windows: use cmd.exe to run copilot (works with .cmd/.bat shims via PATH)
            $copilotCmd = "cmd.exe"
            $copilotArgs = "/c copilot -p `"$Prompt`" --model claude-opus-4.5 --allow-all-tools --allow-all-paths --no-ask-user$configDirArg"
        } else {
            # Linux/macOS: use /usr/bin/env to find copilot
            $copilotCmd = "/usr/bin/env"
            $copilotArgs = "copilot -p `"$Prompt`" --model claude-opus-4.5 --allow-all-tools --allow-all-paths --no-ask-user$configDirArg"
        }
    } else {
        $copilotArgs = "-p `"$Prompt`" --model claude-opus-4.5 --allow-all-tools --allow-all-paths --no-ask-user$configDirArg"
    }

    Write-Host "   Copilot executable: $copilotCmd"

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $copilotCmd
    $processInfo.Arguments = $copilotArgs
    $processInfo.WorkingDirectory = $WorkingDir
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo

    # Capture output asynchronously to avoid deadlocks
    $stdoutBuilder = New-Object System.Text.StringBuilder
    $stderrBuilder = New-Object System.Text.StringBuilder

    $stdoutEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
        if ($null -ne $EventArgs.Data) {
            $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null
        }
    } -MessageData $stdoutBuilder

    $stderrEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
        if ($null -ne $EventArgs.Data) {
            $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null
        }
    } -MessageData $stderrBuilder

    $startTime = Get-Date
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    $elapsed = (Get-Date) - $startTime

    # Flush async output streams — the parameterless WaitForExit() ensures
    # all redirected stdout/stderr has been processed by the event handlers
    if ($completed) {
        $process.WaitForExit()
    }

    # Unregister events
    Unregister-Event -SourceIdentifier $stdoutEvent.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $stderrEvent.Name -ErrorAction SilentlyContinue

    $stdout = $stdoutBuilder.ToString()
    $stderr = $stderrBuilder.ToString()

    # Save outputs
    $stdout | Out-File -FilePath $OutputFile -Encoding utf8
    if ($stderr) {
        $stderr | Out-File -FilePath $errorFile -Encoding utf8
    }

    if (-not $completed) {
        $process.Kill()
        Write-Warning "[TIMEOUT] Copilot timed out after $TimeoutSeconds seconds for $ScenarioName ($RunType)"
        return $null
    }

    $exitCode = $process.ExitCode
    Write-Host "   Exit code: $exitCode"
    Write-Host "   Elapsed: $([math]::Round($elapsed.TotalSeconds, 1))s"

    if ($exitCode -ne 0) {
        Write-Warning "Copilot CLI exited with code $exitCode"
        Write-Warning "Stderr: $stderr"
        # Don't throw - we still want to capture and evaluate partial output
    }

    # Return combined output (stats are written to stderr by Copilot CLI)
    return ($stdout + "`n" + $stderr)
}

#endregion

#region Main Logic

Write-Host ""
Write-Host ("=" * 60)
Write-Host "[SCENARIO] Running: $ScenarioName ($RunType)"
Write-Host ("=" * 60)

if (-not $ScenariosBaseDir) {
    throw "ScenariosBaseDir is required."
}
if (-not [System.IO.Path]::IsPathRooted($ScenariosBaseDir)) {
    $ScenariosBaseDir = Join-Path $RepoRoot $ScenariosBaseDir
}
$scenarioBaseDir = Join-Path $ScenariosBaseDir $ScenarioName
$scenarioSourceDir = $scenarioBaseDir
$scenarioResultsDir = Join-Path $ResultsDir $ScenarioName $RunId

if (-not (Test-Path $scenarioSourceDir)) {
    throw "Scenario source directory not found: $scenarioSourceDir"
}

# Create results directory
New-Item -ItemType Directory -Force -Path $scenarioResultsDir | Out-Null

# Step 1: Copy scenario to a clean temp directory
$workingDir = Copy-ScenarioToTemp -ScenarioSourceDir $scenarioSourceDir -ScenarioName $ScenarioName -RunType $RunType

# Step 2: Build the prompt
# Read eval-test-prompt.txt from the ORIGINAL testcase dir (before exclusion)
$promptFile = Join-Path $scenarioBaseDir "eval-test-prompt.txt"
if (Test-Path $promptFile) {
    $prompt = (Get-Content $promptFile -Raw).Trim()
    Write-Host "[PROMPT] Loaded from: $promptFile"
} else {
    $prompt = "Analyze the build issues in this scenario and provide required fixes and their explanations. The fixes should not alter logic of the code (e.g. by suggesting to delete code files)."
    Write-Host "[PROMPT] Using default prompt (no eval-test-prompt.txt found)"
}

# Step 3: Run Copilot CLI
$outputFile = Join-Path $scenarioResultsDir "${RunType}-output.txt"

# Create a per-run config directory for session isolation (must be absolute path)
$sessionConfigDir = Join-Path (Resolve-Path $scenarioResultsDir).Path "${RunType}-config"
New-Item -ItemType Directory -Force -Path $sessionConfigDir | Out-Null
Write-Host "[SESSION] Config directory: $sessionConfigDir"

$maxRetries = 3
$output = $null
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    if ($attempt -gt 1) {
        Write-Host "[RETRY] Attempt $attempt of $maxRetries..."
        # Clean up previous session config for fresh retry
        Remove-Item -Recurse -Force $sessionConfigDir -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $sessionConfigDir | Out-Null
    }

    $output = Invoke-CopilotWithTimeout `
        -Prompt $prompt `
        -WorkingDir $workingDir `
        -OutputFile $outputFile `
        -TimeoutSeconds $TimeoutSeconds `
        -ConfigDir $sessionConfigDir

    if ($null -ne $output) {
        break
    }
    Write-Warning "[RETRY] Attempt $attempt failed (timeout or error), retrying in 60s..."
    # Wait before retry to avoid hitting API quota limits
    Start-Sleep -Seconds 60
}
if ($null -eq $output) {
    Write-Warning "[RETRY] All $maxRetries attempts failed for $ScenarioName ($RunType)"
}

# Step 4: Parse stats
Write-Host ""
Write-Host "[STATS] Parsing stats..."
$stats = Parse-CopilotStats -Output $output

# Add metadata
$stats.RunType = $RunType
$stats.ScenarioName = $ScenarioName
$stats.Timestamp = (Get-Date -Format "o")

$statsFile = Join-Path $scenarioResultsDir "${RunType}-stats.json"
$stats | ConvertTo-Json -Depth 5 | Out-File -FilePath $statsFile -Encoding utf8

Write-Host "   Premium Requests: $($stats.PremiumRequests)"
Write-Host "   API Time: $($stats.ApiTimeSeconds)s"
Write-Host "   Total Time: $($stats.TotalTimeSeconds)s"
Write-Host "   Model: $($stats.Model)"
Write-Host "   Tokens In: $($stats.TokensIn)"
Write-Host "   Tokens Out: $($stats.TokensOut)"

# Step 4b: Extract skill activation from session logs
Write-Host ""
Write-Host "[ACTIVATION] Checking skill activation from session logs..."
$activation = Get-SkillActivation -ConfigDir $sessionConfigDir

$activationFile = Join-Path $scenarioResultsDir "${RunType}-activations.json"
$activation | ConvertTo-Json -Depth 5 | Out-File -FilePath $activationFile -Encoding utf8

if ($activation.Activated) {
    Write-Host "   Skills activated: $($activation.Skills -join ', ')"
    if ($activation.Agents.Count -gt 0) {
        Write-Host "   Agents delegated: $($activation.Agents -join ', ')"
    }
} else {
    if ($RunType -eq "skilled") {
        Write-Host "   WARNING: No skills or agents were activated in skilled run"
    } else {
        Write-Host "   (vanilla run - no skills expected)"
    }
}

# Save session ID for reproducibility
if ($activation.SessionId) {
    $sessionInfo = @{
        SessionId = $activation.SessionId
        ConfigDir = $sessionConfigDir
        RunType   = $RunType
        Scenario  = $ScenarioName
        Timestamp = (Get-Date -Format "o")
    }
    $sessionFile = Join-Path $scenarioResultsDir "${RunType}-session.json"
    $sessionInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath $sessionFile -Encoding utf8
    Write-Host "   Session ID: $($activation.SessionId)"
}

# Step 5: Clean up temp directory
Write-Host ""
Write-Host "[CLEAN] Removing temp working directory: $workingDir"
Remove-Item -Path $workingDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[OK] Scenario $ScenarioName ($RunType) completed"
Write-Host "   Output: $outputFile"
Write-Host "   Stats: $statsFile"

#endregion
