<#
.SYNOPSIS
    Converts evaluation results into benchmark dashboard data.

.DESCRIPTION
    Reads evaluation results from the results directory and produces a data.json
    file compatible with the custom benchmark dashboard. If an existing data.json
    is provided, the new data point is appended to the existing history.

.PARAMETER ResultsDir
    Path to the results directory for this run.

.PARAMETER OutputDir
    Path to write the output files. Defaults to ResultsDir.

.PARAMETER ExistingDataFile
    Optional path to an existing data.json file from gh-pages to append to.

.PARAMETER CommitJson
    Optional JSON string with commit info (id, message, author, timestamp, url).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResultsDir,

    [Parameter()]
    [string]$OutputDir,

    [Parameter()]
    [string]$ExistingDataFile,

    [Parameter()]
    [string]$CommitJson
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

# Build bench arrays for this run
$qualityBenches = [System.Collections.Generic.List[object]]::new()
$efficiencyBenches = [System.Collections.Generic.List[object]]::new()

$totalVanilla = 0.0
$totalSkilled = 0.0
$scenarioCount = 0

foreach ($scenarioDir in $scenarioDirs) {
    $scenarioName = $scenarioDir.Name
    $evalFile = Join-Path $scenarioDir.FullName "evaluation.json"
    $skilledStatsFile = Join-Path $scenarioDir.FullName "skilled-stats.json"

    if (Test-Path $evalFile) {
        $evalData = Get-Content $evalFile -Raw | ConvertFrom-Json
        $vanillaEval = $evalData.evaluations.vanilla
        $skilledEval = $evalData.evaluations.skilled

        if ($skilledEval -and $skilledEval.score) {
            $qualityBenches.Add(@{ name = "$scenarioName - Skilled Quality"; unit = "Score (1-5)"; value = [float]$skilledEval.score })
            $totalSkilled += [float]$skilledEval.score
            $scenarioCount++
        }

        if ($vanillaEval -and $vanillaEval.score) {
            $qualityBenches.Add(@{ name = "$scenarioName - Vanilla Quality"; unit = "Score (1-5)"; value = [float]$vanillaEval.score })
            $totalVanilla += [float]$vanillaEval.score
        }
    }

    if (Test-Path $skilledStatsFile) {
        $skilledStats = Get-Content $skilledStatsFile -Raw | ConvertFrom-Json
        if ($skilledStats.TotalTimeSeconds) {
            $efficiencyBenches.Add(@{ name = "$scenarioName - Skilled Time"; unit = "seconds"; value = [float]$skilledStats.TotalTimeSeconds })
        }
        if ($skilledStats.TokensIn) {
            $efficiencyBenches.Add(@{ name = "$scenarioName - Skilled Tokens In"; unit = "tokens"; value = [float]$skilledStats.TokensIn })
        }
    }
}

if ($scenarioCount -gt 0) {
    $qualityBenches.Add(@{ name = "Overall - Skilled Avg Quality"; unit = "Score (1-5)"; value = [math]::Round($totalSkilled / $scenarioCount, 2) })
    $qualityBenches.Add(@{ name = "Overall - Vanilla Avg Quality"; unit = "Score (1-5)"; value = [math]::Round($totalVanilla / $scenarioCount, 2) })
}

# Build commit info
$commit = @{}
if ($CommitJson) {
    $commit = $CommitJson | ConvertFrom-Json -AsHashtable
} else {
    $commit = @{ id = "local"; message = "Local run"; timestamp = (Get-Date -Format "o") }
}

$now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

# Detect model from skilled-stats.json files
$model = $null
foreach ($scenarioDir in $scenarioDirs) {
    $skilledStatsFile = Join-Path $scenarioDir.FullName "skilled-stats.json"
    if (Test-Path $skilledStatsFile) {
        $skilledStats = Get-Content $skilledStatsFile -Raw | ConvertFrom-Json
        if ($skilledStats.Model) {
            $model = $skilledStats.Model
            break
        }
    }
}

$qualityEntry = @{
    commit = $commit
    date   = $now
    tool   = "customBiggerIsBetter"
    model  = $model
    benches = $qualityBenches.ToArray()
}

$efficiencyEntry = @{
    commit = $commit
    date   = $now
    tool   = "customSmallerIsBetter"
    model  = $model
    benches = $efficiencyBenches.ToArray()
}

# Load existing data or create new structure
$benchmarkData = @{
    lastUpdate = $now
    repoUrl    = ""
    entries    = @{
        "Skills Evaluation - Quality"    = @()
        "Skills Evaluation - Efficiency" = @()
    }
}

if ($ExistingDataFile -and (Test-Path $ExistingDataFile)) {
    $existingContent = Get-Content $ExistingDataFile -Raw
    try {
        $benchmarkData = $existingContent | ConvertFrom-Json -AsHashtable
        $benchmarkData['lastUpdate'] = $now
    } catch {
        Write-Warning "Failed to parse existing data.json, starting fresh: $_"
    }
}

# Append new entries
if (-not $benchmarkData['entries']) {
    $benchmarkData['entries'] = @{}
}
if (-not $benchmarkData['entries']['Skills Evaluation - Quality']) {
    $benchmarkData['entries']['Skills Evaluation - Quality'] = @()
}
if (-not $benchmarkData['entries']['Skills Evaluation - Efficiency']) {
    $benchmarkData['entries']['Skills Evaluation - Efficiency'] = @()
}

$benchmarkData['entries']['Skills Evaluation - Quality'] += @($qualityEntry)
$benchmarkData['entries']['Skills Evaluation - Efficiency'] += @($efficiencyEntry)

# Write data.json
$dataJson = $benchmarkData | ConvertTo-Json -Depth 10
$dataJsonFile = Join-Path $OutputDir "data.json"
$dataJson | Out-File -FilePath $dataJsonFile -Encoding utf8

Write-Host "[OK] Benchmark data.json generated: $dataJsonFile"
Write-Host "   Quality entries: $($qualityBenches.Count)"
Write-Host "   Efficiency entries: $($efficiencyBenches.Count)"
Write-Host "   Total data points: $($benchmarkData['entries']['Skills Evaluation - Quality'].Count)"
