<#
.SYNOPSIS
    Converts evaluation results into github-action-benchmark JSON format.

.DESCRIPTION
    Reads evaluation results from the results directory and produces two JSON files:
    - benchmark-quality.json (customBiggerIsBetter): quality scores per scenario
    - benchmark-efficiency.json (customSmallerIsBetter): time and token metrics

.PARAMETER ResultsDir
    Path to the results directory for this run.

.PARAMETER OutputDir
    Path to write the benchmark JSON files. Defaults to ResultsDir.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResultsDir,

    [Parameter()]
    [string]$OutputDir
)

$ErrorActionPreference = "Stop"

if (-not $OutputDir) {
    $OutputDir = $ResultsDir
}

$scenarioDirs = Get-ChildItem -Path $ResultsDir -Directory -ErrorAction SilentlyContinue
if (-not $scenarioDirs) {
    Write-Warning "No scenario results found in $ResultsDir"
    exit 0
}

$qualityBenchmarks = [System.Collections.Generic.List[object]]::new()
$efficiencyBenchmarks = [System.Collections.Generic.List[object]]::new()

$totalVanilla = 0.0
$totalSkilled = 0.0
$scenarioCount = 0

foreach ($scenarioDir in $scenarioDirs) {
    $scenarioName = $scenarioDir.Name
    $evalFile = Join-Path $scenarioDir.FullName "evaluation.json"
    $vanillaStatsFile = Join-Path $scenarioDir.FullName "vanilla-stats.json"
    $skilledStatsFile = Join-Path $scenarioDir.FullName "skilled-stats.json"

    # Quality scores
    if (Test-Path $evalFile) {
        $evalData = Get-Content $evalFile -Raw | ConvertFrom-Json
        $vanillaEval = $evalData.evaluations.vanilla
        $skilledEval = $evalData.evaluations.skilled

        if ($skilledEval -and $skilledEval.score) {
            $qualityBenchmarks.Add(@{
                name  = "$scenarioName - Skilled Quality"
                unit  = "Score (1-5)"
                value = [float]$skilledEval.score
            })
            $totalSkilled += [float]$skilledEval.score
            $scenarioCount++
        }

        if ($vanillaEval -and $vanillaEval.score) {
            $qualityBenchmarks.Add(@{
                name  = "$scenarioName - Vanilla Quality"
                unit  = "Score (1-5)"
                value = [float]$vanillaEval.score
            })
            $totalVanilla += [float]$vanillaEval.score
        }
    }

    # Efficiency metrics (time)
    $skilledStats = $null
    if (Test-Path $skilledStatsFile) {
        $skilledStats = Get-Content $skilledStatsFile -Raw | ConvertFrom-Json
        if ($skilledStats.TotalTimeSeconds) {
            $efficiencyBenchmarks.Add(@{
                name  = "$scenarioName - Skilled Time"
                unit  = "seconds"
                value = [float]$skilledStats.TotalTimeSeconds
            })
        }
        if ($skilledStats.TokensIn) {
            $efficiencyBenchmarks.Add(@{
                name  = "$scenarioName - Skilled Tokens In"
                unit  = "tokens"
                value = [float]$skilledStats.TokensIn
            })
        }
    }
}

# Add overall averages
if ($scenarioCount -gt 0) {
    $qualityBenchmarks.Add(@{
        name  = "Overall - Skilled Avg Quality"
        unit  = "Score (1-5)"
        value = [math]::Round($totalSkilled / $scenarioCount, 2)
    })
    $qualityBenchmarks.Add(@{
        name  = "Overall - Vanilla Avg Quality"
        unit  = "Score (1-5)"
        value = [math]::Round($totalVanilla / $scenarioCount, 2)
    })
}

# Write output files
$qualityFile = Join-Path $OutputDir "benchmark-quality.json"
$efficiencyFile = Join-Path $OutputDir "benchmark-efficiency.json"

$qualityBenchmarks | ConvertTo-Json -Depth 5 | Out-File -FilePath $qualityFile -Encoding utf8
$efficiencyBenchmarks | ConvertTo-Json -Depth 5 | Out-File -FilePath $efficiencyFile -Encoding utf8

Write-Host "[OK] Benchmark data generated:"
Write-Host "   Quality metrics ($($qualityBenchmarks.Count) entries): $qualityFile"
Write-Host "   Efficiency metrics ($($efficiencyBenchmarks.Count) entries): $efficiencyFile"
