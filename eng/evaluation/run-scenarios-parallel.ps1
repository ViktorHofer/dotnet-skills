<#
.SYNOPSIS
    Runs scenarios in parallel with error propagation.

.DESCRIPTION
    Executes a PowerShell script for each scenario in parallel using
    ForEach-Object -Parallel, collects failures via ConcurrentBag, and
    throws if any scenario's script exited with a non-zero exit code.
    All scenarios run to completion before failing.

.PARAMETER Script
    Path to the per-scenario script (e.g., run-scenario.ps1 or evaluate-response.ps1).

.PARAMETER RunType
    Optional run type passed to the script (e.g., "vanilla" or "skilled").

.PARAMETER Scenarios
    Comma-separated list of scenario names.

.PARAMETER Parallelism
    Number of scenarios to run concurrently.

.PARAMETER Plugin
    Plugin name. Used to derive the testcases base directory.

.PARAMETER ResultsDir
    Path to the results directory.

.PARAMETER RunId
    Unique identifier for this run.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Script,

    [string]$RunType,

    [Parameter(Mandatory)]
    [string]$Scenarios,

    [Parameter(Mandatory)]
    [int]$Parallelism,

    [Parameter(Mandatory)]
    [string]$Plugin,

    [Parameter(Mandatory)]
    [string]$ResultsDir,

    [Parameter(Mandatory)]
    [string]$RunId,

    [Parameter(Mandatory)]
    [string]$Model,

    [Parameter(Mandatory)]
    [int]$MaxRetries
)

$ErrorActionPreference = "Stop"

$scenarioList = ($Scenarios -split ",") | Where-Object { $_.Trim() -ne "" }
if ($scenarioList.Count -eq 0) {
    throw "No scenarios provided. The scenarios list is empty."
}
$label = if ($RunType) { $RunType } else { "evaluation" }
$resolvedScript = (Resolve-Path $Script).Path
$scenariosBaseDir = "src/$Plugin/testcases"

Write-Host "`nRunning $($scenarioList.Count) scenarios ($label) with parallelism level: $Parallelism"

$failures = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

$scenarioList | ForEach-Object -ThrottleLimit $Parallelism -Parallel {
    $scenario = $_
    $script = $using:resolvedScript
    $resultsDir = $using:ResultsDir
    $runId = $using:RunId
    $runType = $using:RunType
    $scenariosBaseDir = $using:scenariosBaseDir
    $failures = $using:failures
    $label = $using:label
    $model = $using:Model
    $maxRetries = $using:MaxRetries

    Write-Host "`n=== ${label}: $scenario ==="

    $scriptArgs = @(
        "-ScenarioName", $scenario,
        "-ResultsDir", $resultsDir,
        "-RunId", $runId,
        "-ScenariosBaseDir", $scenariosBaseDir,
        "-Model", $model,
        "-MaxRetries", $maxRetries
    )
    if ($runType) {
        $scriptArgs += @("-RunType", $runType)
    }

    # Capture output and prefix each line with the scenario name for readable logs
    $output = pwsh -File $script @scriptArgs 2>&1
    $exitCode = $LASTEXITCODE

    $output | ForEach-Object { Write-Host "[$scenario] $_" }

    if ($exitCode -ne 0) {
        $failures.Add($scenario)
        Write-Warning "[$scenario] Scenario $scenario ($label) failed with exit code $exitCode"
    }
}

if ($failures.Count -gt 0) {
    throw "❌ Test run completed. $($failures.Count)/$($scenarioList.Count) $label scenario(s) failed: $($failures -join ', ')"
}
else {
    Write-Host "✅ Test run completed. All $label scenarios passed successfully."
}
