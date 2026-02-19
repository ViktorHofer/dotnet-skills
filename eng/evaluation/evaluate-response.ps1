<#
.SYNOPSIS
    Evaluates a Copilot CLI response against expected output using Copilot as evaluator.

.DESCRIPTION
    Takes the actual Copilot output and compares it against the expected output file
    using a separate Copilot CLI invocation (vanilla, no plugins) as the evaluator.
    Files are written to a temp directory so Copilot can read them with file tools.

.PARAMETER ScenarioName
    Name of the scenario to evaluate.

.PARAMETER ResultsDir
    Path to the results directory for this run.

.PARAMETER ScenariosBaseDir
    Path to the testcases directory. Can be relative (resolved against RepoRoot)
    or absolute.

.PARAMETER TimeoutSeconds
    Maximum time to wait for evaluation Copilot CLI to complete.

.PARAMETER RepoRoot
    Root directory of the repository.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ScenarioName,

    [Parameter(Mandatory)]
    [string]$ResultsDir,

    [string]$ScenariosBaseDir,

    [int]$TimeoutSeconds = 300,

    [Parameter(Mandatory)]
    [string]$RunId,

    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\")).Path
}

#region Helper Functions

function Invoke-EvaluationCopilot {
    param(
        [string]$Prompt,
        [string]$WorkingDir,
        [int]$TimeoutSeconds = 300
    )

# Resolve copilot executable - prefer .cmd/.bat/.exe for Process.Start compatibility
    # Use -All to search across all PATH entries, not just the first match
    $copilotCmd = Get-Command copilot -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq 'Application' } |
        Select-Object -First 1 -ExpandProperty Source
    if (-not $copilotCmd) {
        if ($env:OS -match 'Windows') {
            $copilotCmd = "cmd.exe"
            $copilotArgs = "/c copilot -p `"$Prompt`" --model claude-opus-4.5 --no-ask-user --allow-all-tools --allow-all-paths"
        } else {
            $copilotCmd = "/usr/bin/env"
            $copilotArgs = "copilot -p `"$Prompt`" --model claude-opus-4.5 --no-ask-user --allow-all-tools --allow-all-paths"
        }
    } else {
        $copilotArgs = "-p `"$Prompt`" --model claude-opus-4.5 --no-ask-user --allow-all-tools --allow-all-paths"
    }

    Write-Host "   Copilot executable: $copilotCmd"
    Write-Host "   Working dir: $WorkingDir"

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

    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    $completed = $process.WaitForExit($TimeoutSeconds * 1000)

    # Flush async output streams — the parameterless WaitForExit() ensures
    # all redirected stdout/stderr has been processed by the event handlers
    if ($completed) {
        $process.WaitForExit()
    }

    Unregister-Event -SourceIdentifier $stdoutEvent.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $stderrEvent.Name -ErrorAction SilentlyContinue

    $stdout = $stdoutBuilder.ToString()
    $stderr = $stderrBuilder.ToString()

    if (-not $completed) {
        $process.Kill()
        Write-Warning "[TIMEOUT] Evaluation Copilot timed out after $TimeoutSeconds seconds"
        if ($stderr) { Write-Warning "Stderr: $stderr" }
        return $null
    }

    $exitCode = $process.ExitCode
    Write-Host "   Exit code: $exitCode"
    if ($exitCode -ne 0) {
        Write-Warning "Evaluation Copilot exited with code $exitCode"
        if ($stderr) { Write-Warning "Stderr: $stderr" }
    }

    return $stdout
}

function Parse-EvaluationJson {
    param([string]$Output)

    # Try to extract JSON from the output - it may be wrapped in markdown code blocks
    # Use a pattern that can match across lines for multi-line JSON
    $lines = $Output -split "`n"
    $jsonStartIdx = -1
    $jsonEndIdx = -1

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\{' -and $lines[$i] -match '"score"') {
            # Single-line JSON
            $jsonCandidate = $lines[$i].Trim()
            try {
                $json = $jsonCandidate | ConvertFrom-Json
                return $json
            } catch { }
        }
        if ($lines[$i] -match '^\s*\{' -and $jsonStartIdx -eq -1) {
            $jsonStartIdx = $i
        }
        if ($jsonStartIdx -ge 0 -and $lines[$i] -match '^\s*\}') {
            $jsonEndIdx = $i
            $jsonCandidate = ($lines[$jsonStartIdx..$jsonEndIdx] -join "`n").Trim()
            if ($jsonCandidate -match '"score"') {
                try {
                    $json = $jsonCandidate | ConvertFrom-Json
                    return $json
                } catch {
                    $jsonStartIdx = -1
                    $jsonEndIdx = -1
                }
            }
        }
    }

    # Fallback: regex extraction
    if ($Output -match '(?s)\{[^{}]*"score"\s*:\s*\d[^{}]*\}') {
        try {
            $json = $Matches[0] | ConvertFrom-Json
            return $json
        } catch {
            Write-Warning "Failed to parse extracted JSON: $_"
        }
    }

    # Return a default failure evaluation
    Write-Warning "Could not parse evaluation output."
    return [PSCustomObject]@{
        score         = 0
        accuracy      = 0
        completeness  = 0
        actionability = 0
        clarity       = 0
        reasoning     = "Failed to parse evaluation response from Copilot"
    }
}

#endregion

#region Main Logic

Write-Host ""
Write-Host ("=" * 60)
Write-Host "[EVAL] Evaluating Scenario: $ScenarioName"
Write-Host ("=" * 60)

$scenarioResultsDir = Join-Path $ResultsDir $ScenarioName $RunId

# Read expected output from scenario folder
if (-not $ScenariosBaseDir) {
    throw "ScenariosBaseDir is required."
}
if (-not [System.IO.Path]::IsPathRooted($ScenariosBaseDir)) {
    $ScenariosBaseDir = Join-Path $RepoRoot $ScenariosBaseDir
}
$scenarioBaseDir = Join-Path $ScenariosBaseDir $ScenarioName
$expectedFile = Join-Path $scenarioBaseDir "expected-output.md"
if (-not (Test-Path $expectedFile)) {
    throw "Expected output file not found: $expectedFile"
}
Write-Host "[INFO] Expected output loaded from: $expectedFile"

# Process each run type
$runTypes = @("vanilla", "skilled")
$evaluations = @{}

foreach ($runType in $runTypes) {
    $outputFile = Join-Path $scenarioResultsDir "${runType}-output.txt"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "[WARN] Output file not found for $runType run: $outputFile"
        $evaluations[$runType] = [PSCustomObject]@{
            score         = 0
            accuracy      = 0
            completeness  = 0
            actionability = 0
            clarity       = 0
            reasoning     = "Output file not found - run may have failed or was skipped"
        }
        continue
    }

    $actualOutput = Get-Content $outputFile -Raw
    Write-Host ""
    Write-Host "[EVAL] Evaluating $runType response ($($actualOutput.Length) chars)..."

    # Create a temp evaluation directory with the files Copilot needs to read
    $evalDir = Join-Path ([System.IO.Path]::GetTempPath()) "copilot-eval-${runType}-$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $evalDir | Out-Null

    try {
        # Write the expected output and actual response as files in the eval directory
        Copy-Item -Path $expectedFile -Destination (Join-Path $evalDir "expected-output.md")
        Copy-Item -Path $outputFile -Destination (Join-Path $evalDir "actual-response.txt")

        # Write the evaluation instructions
        $instructions = @"
# Evaluation Task

Read the two files in this directory:
1. **expected-output.md** - The ground truth / expected findings
2. **actual-response.txt** - The AI assistant's actual response

## Step 1: Checklist Scoring (Primary Metric)
If expected-output.md contains an "## Evaluation Checklist" section, score each checklist item:
- Read each checklist item carefully
- Check if the actual response correctly identifies and addresses that item
- Award 1 point for each item that is correctly identified AND addressed with a reasonable solution
- Award 0.5 points for items partially addressed (identified but wrong/vague fix, or fix without identification)
- Award 0 points for items not mentioned or completely wrong
- Calculate: checklist_score = points_earned, checklist_max = total_items

If there is no Evaluation Checklist section, set checklist_score and checklist_max to null.

## Step 2: Subjective Quality Rating (Secondary Metric)
Rate the actual response on a scale of 0-10 where:
- 0-2: Major errors, misidentification of problems, harmful suggestions
- 3-4: Partially correct, misses major issues, vague solutions
- 5-6: Correct identification of main issues, but missing some, generic solutions
- 7-8: Identifies most issues correctly with specific, actionable solutions
- 9-10: Identifies all issues, provides expert-level solutions with precise MSBuild concepts

Use the full range. A response that catches 5/7 issues with correct fixes is a 7, not a 4.

Rate each dimension independently on the same 0-10 scale:
1. **Accuracy** - Did it correctly identify the problems without false positives?
2. **Completeness** - Did it find all issues mentioned in expected output?
3. **Actionability** - Are the suggested solutions practical, correct, and specific?
4. **Clarity** - Is the explanation clear and well-organized?

## Response Format
Your response must be ONLY a JSON object. Do not include any other text, markdown formatting, or code fences.

{"score": <0-10>, "accuracy": <0-10>, "completeness": <0-10>, "actionability": <0-10>, "clarity": <0-10>, "checklist_score": <number|null>, "checklist_max": <number|null>, "reasoning": "<brief explanation of scoring decisions>"}
"@
        $instructions | Out-File -FilePath (Join-Path $evalDir "INSTRUCTIONS.md") -Encoding utf8

        # Build a short prompt that tells Copilot to read the files
        $evalPrompt = "Read the files in this directory: INSTRUCTIONS.md, expected-output.md, and actual-response.txt. Follow the instructions in INSTRUCTIONS.md to evaluate the actual response against the expected output. Your response must be ONLY a JSON object as specified in the instructions. Do not include any markdown code fences, explanatory text, or anything other than the raw JSON object."

        # Run evaluation with Copilot (vanilla - no plugins) with retry logic
        $maxRetries = 3
        $evaluation = $null

        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            Write-Host "[EVAL] Running Copilot evaluator for $runType (attempt $attempt/$maxRetries)..."
            $evalOutput = Invoke-EvaluationCopilot `
                -Prompt $evalPrompt `
                -WorkingDir $evalDir `
                -TimeoutSeconds $TimeoutSeconds

            if ($null -eq $evalOutput -or $evalOutput.Trim() -eq '') {
                Write-Warning "[EVAL] Attempt ${attempt}: Copilot returned no output (timeout or error)"
                # Wait before retry to avoid hitting API quota limits
                if ($attempt -lt $maxRetries) { Start-Sleep -Seconds 60 }
                continue
            }

            # Save raw evaluation output
            $evalRawFile = Join-Path $scenarioResultsDir "${runType}-eval-raw.txt"
            $evalOutput | Out-File -FilePath $evalRawFile -Encoding utf8

            # Parse evaluation
            $evaluation = Parse-EvaluationJson -Output $evalOutput

            # Check if parsing produced a valid result (reasoning field is only set
            # to the failure message when parsing fails)
            if ($evaluation.reasoning -ne "Failed to parse evaluation response from Copilot") {
                Write-Host "[EVAL] Successfully parsed evaluation on attempt $attempt"
                break
            }

            Write-Warning "[EVAL] Attempt ${attempt}: Failed to parse evaluation JSON"
            $evaluation = $null
            # Wait before retry to avoid hitting API quota limits
            if ($attempt -lt $maxRetries) { Start-Sleep -Seconds 60 }
        }

        if ($null -eq $evaluation) {
            Write-Warning "[EVAL] All $maxRetries attempts failed for $runType"
            $evaluation = [PSCustomObject]@{
                score         = $null
                accuracy      = $null
                completeness  = $null
                actionability = $null
                clarity       = $null
                reasoning     = "All evaluation attempts failed (timeout or parse error)"
            }
        }

        $evaluations[$runType] = $evaluation

        Write-Host "   Score: $($evaluation.score)/10"
        Write-Host "   Accuracy: $($evaluation.accuracy)/10"
        Write-Host "   Completeness: $($evaluation.completeness)/10"
        Write-Host "   Actionability: $($evaluation.actionability)/10"
        Write-Host "   Clarity: $($evaluation.clarity)/10"
        if ($null -ne $evaluation.checklist_score) {
            Write-Host "   Checklist: $($evaluation.checklist_score)/$($evaluation.checklist_max)"
        }
        Write-Host "   Reasoning: $($evaluation.reasoning)"
    }
    finally {
        Remove-Item -Path $evalDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Save combined evaluation results
$evalResult = @{
    scenario    = $ScenarioName
    timestamp   = (Get-Date -Format "o")
    evaluations = $evaluations
}

$evalFile = Join-Path $scenarioResultsDir "evaluation.json"
$evalResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $evalFile -Encoding utf8

Write-Host ""
Write-Host "[OK] Evaluation complete for $ScenarioName"
Write-Host "   Results saved to: $evalFile"

#endregion
