# Evaluation Stability Improvements

## Problem Statement

The current evaluation pipeline produces undifferentiated results between vanilla and skilled runs. After running all 12 scenarios and multiple stability iterations, two root causes are clear: **ceiling effect from the 1–5 scale** and **testcases too easy for the base model**. Scores are stable (not random), but the system cannot measure the incremental value skills provide.

### Full Evaluation — All 12 Scenarios

| Scenario | Vanilla | Skilled | Delta | Skills Activated | Activation Type |
|----------|---------|---------|-------|-----------------|-----------------|
| bin-obj-clash | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | check-bin-obj-clash | skill tool |
| build-errors-cs | 4 (4/4/5/5) | 4 (4/4/5/5) | **0** | ⚠️ **NONE** | — |
| build-errors-nuget | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | binlog-generation | skill tool |
| build-errors-sdk | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | sdk-workload-resolution | skill tool |
| eval-heavy | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | eval-performance | skill tool |
| generated-files | 4 (5/3/5/4) | 4 (5/4/5/4) | **0** | binlog-generation, binlog-failure-analysis, msbuild-including-generated-files | skill tool |
| incremental-broken | 4 (5/4/5/5) | 5 (5/5/5/5) | **+1** ✅ | incremental-build | skill tool |
| legacy-project | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | msbuild-modernization | skill tool |
| multitarget | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | binlog-generation, multitarget-tfm-issues | skill tool |
| parallel-bottleneck | 5 (5/5/5/5) | 5 (5/5/5/5) | **0** | binlog-generation, build-parallelism | skill tool |
| perf-analyzers | 5 (5/5/5/5) | 3 (4/3/3/5) | **-2** ❌ | binlog-generation | skill tool |
| style-issues | 4 (5/4/5/5) | 4 (5/4/4/5) | **0** | msbuild-code-review | subagent |

*Scores: overall (accuracy/completeness/actionability/clarity). Format: n/5.*

### Stability Test — Repeated Iterations

| Iteration | Scenario | Vanilla | Skilled | Delta |
|-----------|----------|---------|---------|-------|
| 1 | build-errors-cs | 4 (4/4/5/5) | 4 (4/4/5/5) | 0 |
| 2 | build-errors-cs | 4 (4/4/5/5) | 4 (4/4/5/5) | 0 |
| 3 | build-errors-cs | 4 (4/4/5/5) | 4 (4/4/5/5) | 0 |
| 1 | style-issues | 4 (5/4/5/5) | 4 (5/4/4/5) | 0 |
| 2 | style-issues | 4 (4/4/5/5) | 4 (4/4/4/5) | 0 |

### Key Findings

1. **Ceiling effect is the #1 problem**: 7 of 12 scenarios score 5/5 on BOTH vanilla and skilled. The 1–5 scale has no room to reward the incremental improvements skills provide when the base model already produces good responses.

2. **Skill activation is near-universal**: 11 of 12 scenarios successfully activate skills (via the `skill` tool or `subagent` delegation). Only `build-errors-cs` fails to invoke any skill — the model solves it from general knowledge.

3. **Skills can hurt**: `perf-analyzers` scored **-2** with skills. The skilled response used `binlog-generation` to gather data but missed key expected solutions (`RunAnalyzers=false`, `EnforceCodeStyleInBuild=false`), instead suggesting removing/consolidating analyzers — a valid but non-matching approach.

4. **Skills can help clearly**: `incremental-broken` scored **+1** with skills. The `incremental-build` skill led the model to find BOTH expected issues (missing `Inputs/Outputs` AND `FileWrites`), while vanilla only found one.

5. **Scores are perfectly stable — this is a ceiling problem, not a stability problem**: 5 repeated iterations across 2 scenarios produced identical scores every time. The evaluation pipeline is deterministic enough; the problem is entirely lack of discriminative power from the 1–5 scale and overly simple testcases.

6. **Skill activation has two mechanisms**: Most scenarios use the `skill` tool (function call), while `style-issues` uses `subagent` delegation to the `msbuild-code-review` agent. Both must be checked when verifying activation.

---

## Improvement Recommendations

### 1. Switch to 0–10 Granular Scoring Scale

**Priority: HIGH** | **Impact: HIGH** | **Effort: LOW**

The current 1–5 scale collapses all "good" responses into 4/5 and all "great" responses into 5/5. With claude-opus-4.5 as the base model, vanilla responses are already good enough to score 4/5, leaving no room to reward the incremental improvements skills provide.

**Changes needed:**
- Update `evaluate-response.ps1`: Change INSTRUCTIONS.md template from `1-5` to `0-10`
- Update `generate-summary.ps1`: Change all `/5` references to `/10`, update delta thresholds
- Update `dashboard.js`: Change `suggestedMax: 5` to `suggestedMax: 10`

**Proposed rubric (in INSTRUCTIONS.md):**

```
Rate on a scale of 0-10 where:
- 0-2: Major errors, misidentification of problems, harmful suggestions
- 3-4: Partially correct, misses major issues, vague solutions
- 5-6: Correct identification of main issues, but missing some, generic solutions
- 7-8: Identifies most issues correctly with specific, actionable solutions
- 9-10: Identifies all issues, provides expert-level solutions with precise MSBuild concepts

Use the full range. A response that catches 5/7 issues with correct fixes is a 7, not a 4.
```

### 2. Add Checklist-Based Scoring to Expected Output

**Priority: HIGH** | **Impact: HIGH** | **Effort: MEDIUM**

Instead of relying on the LLM evaluator's subjective judgment, add a structured checklist to each `expected-output.md` that the evaluator must score against. This creates deterministic, reproducible scoring.

**Proposed format (add to each expected-output.md):**

```markdown
## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified CS0246 error in MissingReference
- [ ] Mentioned System.Text.Json as missing package
- [ ] Mentioned Microsoft.Extensions.Logging.Abstractions as missing package
- [ ] Provided correct PackageReference XML for both packages
- [ ] Identified CS0029 in TypeMismatch (type conversion)
- [ ] Identified CS8600 in TypeMismatch (nullable)
- [ ] Explained root cause (string-to-int assignment)
- [ ] Provided correct code fix for type mismatch
- [ ] Mentioned PackageReference as the mechanism to resolve missing types
- [ ] All solutions preserve existing code logic

Total: __/10
```

**Changes to evaluate-response.ps1:**
- Update the evaluation prompt to instruct the evaluator to score each checklist item as found/not-found
- Parse the checklist score as a deterministic metric alongside the subjective scores
- **The checklist score is the primary comparison metric** (deterministic, reproducible). The 0–10 subjective score from recommendation #1 becomes a secondary "qualitative color" metric. Report both in the summary table, but use checklist score for delta comparison and pass/fail decisions

### 3. Verify Skill Activation via Session Logs

**Priority: HIGH** | **Impact: HIGH** | **Effort: MEDIUM**

Session logs at `~/.copilot/session-state/<session-id>/events.jsonl` record every tool call and agent delegation. There are **two activation mechanisms** that both must be checked:

1. **Skill tool calls**: `tool.execution_start` events with `toolName == "skill"` and `arguments.skill` containing the skill name (e.g., `binlog-generation`)
2. **Subagent delegation**: `subagent.started` events with `agentName` (e.g., `msbuild-skills/msbuild-code-review`)

**Findings from this investigation — Skill activation map (all 12 scenarios):**

| Scenario | Skills Activated | Mechanism | Expected? |
|----------|-----------------|-----------|-----------|
| bin-obj-clash | check-bin-obj-clash | skill tool | ✅ Yes |
| build-errors-cs | ⚠️ **NONE** | — | ❌ Expected common-build-errors |
| build-errors-nuget | binlog-generation | skill tool | ⚠️ Partial — expected `nuget-restore-failures`. Update skill description to match NuGet prompts more strongly. |
| build-errors-sdk | sdk-workload-resolution | skill tool | ✅ Yes |
| eval-heavy | eval-performance | skill tool | ✅ Yes |
| generated-files | binlog-generation, binlog-failure-analysis, msbuild-including-generated-files | skill tool | ✅ Yes |
| incremental-broken | incremental-build | skill tool | ✅ Yes |
| legacy-project | msbuild-modernization | skill tool | ✅ Yes |
| multitarget | binlog-generation, multitarget-tfm-issues | skill tool | ✅ Yes |
| parallel-bottleneck | binlog-generation, build-parallelism | skill tool | ✅ Yes |
| perf-analyzers | binlog-generation | skill tool | ⚠️ Partial — used binlog but missed perf-specific skills |
| style-issues | msbuild-code-review | subagent | ✅ Yes |

**Implementation approach:**

```powershell
# After each skilled run, check the most recent session for skill activation
function Get-SkillActivation {
    $sessionDir = Get-ChildItem "$env:USERPROFILE\.copilot\session-state" -Directory |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $eventsFile = Join-Path $sessionDir.FullName "events.jsonl"
    $lines = Get-Content $eventsFile
    $skills = @()
    $agents = @()

    foreach ($line in $lines) {
        $event = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
        # Check for skill tool calls
        if ($event.type -eq "tool.execution_start" -and $event.data.toolName -eq "skill") {
            $skills += $event.data.arguments.skill
        }
        # Check for subagent delegation
        if ($event.type -eq "subagent.started") {
            $agents += $event.data.agentName
        }
    }

    return @{
        Skills = ($skills | Select-Object -Unique)
        Agents = ($agents | Select-Object -Unique)
        AnyActivated = ($skills.Count -gt 0 -or $agents.Count -gt 0)
    }
}
```

**What to record:**
- Which skills were invoked via `skill` tool (list names)
- Which agents were invoked via `subagent` delegation (list names)
- Whether **any** skill or agent was activated (boolean)
- Save as `skilled-activations.json` in the scenario results directory

**How to use in evaluation:**
- Add "Skills Activated" and "Activation Type" columns to the summary table
- If a skilled run produced the same score as vanilla AND no skills were activated, flag it as **"⚠️ Skills Not Used"** rather than "Tie"
- Optionally make it a test failure if expected skills were not activated (configurable per scenario)
- Compare activated skills against expected skills to detect wrong-skill-activated scenarios

**Per-scenario expected skill config (add to each expected-output.md):**

```markdown
## Expected Skills
- check-bin-obj-clash
```

### 4. Make Scenarios Harder to Differentiate Skill Value

**Priority: HIGH** | **Impact: HIGH** | **Effort: MEDIUM**

7 of 12 scenarios hit the 5/5 ceiling on both vanilla and skilled. These scenarios are all solvable by the base model without skills. Each needs specific hardening to create measurable skill advantage.

#### Per-Scenario Hardening Recommendations

| Scenario | Current Score (V/S) | Problem | Hardening Strategy |
|----------|-------------------|---------|-------------------|
| **bin-obj-clash** | 5/5 | Too simple — 3 obvious clashing paths | Add 6+ projects with subtle conditional OutputPath clashes that depend on Configuration/TFM combos. Add red herrings (non-clashing dirs that look suspicious). Require understanding of `BaseIntermediateOutputPath` vs `IntermediateOutputPath` precedence. |
| **build-errors-cs** | 4/4 | No skills invoked — model solves from general knowledge | Replace trivial CS0246/CS0029 with MSBuild-specific errors: implicit usings conflicts, source generator type mismatches, conditional compilation failures across TFMs. The errors should require MSBuild domain knowledge, not just C# knowledge. |
| **build-errors-nuget** | 5/5 | Standard NuGet restore failures are well-known | Add transitive dependency conflicts across `ProjectReference` chains, version range incompatibilities with `CentralPackageManagement`, and `nuget.config` source priority issues. |
| **build-errors-sdk** | 5/5 | Simple SDK/workload resolution | Add scenarios with multiple `global.json` files at different directory levels, SDK rollforward policy conflicts, workload manifest version pinning, and runtime identifier graph issues. |
| **eval-heavy** | 5/5 | Property evaluation perf is a small domain | Add complex `Directory.Build.props` import chains (5+ levels), property functions with expensive string operations, wildcard glob patterns in large directory trees, and item transforms that materialize late. |
| **generated-files** | 4/4 | Almost differentiating — completeness differs | Add source generators that fail silently (output empty files), generators that conflict with each other, and multi-step generation pipelines where output of one generator is input to another. |
| **incremental-broken** | 4/5 ✅ | Already differentiates — keep and expand | Add more subtle incrementality breaks: targets with `BeforeTargets`/`AfterTargets` that prevent caching, missing `Inputs` on targets that read environment variables, and `Copy` tasks without proper `SkipUnchangedFiles`. |
| **legacy-project** | 5/5 | Legacy-to-SDK-style is well-documented | Add projects with COM references, WCF service references, T4 templates, and `packages.config` with binding redirects — migration paths that require specific MSBuild knowledge beyond standard documentation. |
| **multitarget** | 5/5 | Simple multi-TFM scenario | Add conditional `PackageReference` items that conflict across TFMs, platform-specific API usage without proper `#if` guards, and TFM-specific warnings treated as errors on some targets. |
| **parallel-bottleneck** | 5/5 | Build parallelism is straightforward to diagnose | Add scenarios with graph-based build (`-graph:true`) failures, `BuildInParallel` metadata conflicts, and race conditions in custom targets that write to shared files. |
| perf-analyzers | 5/3 ❌ | Skills hurt — missed expected solutions | **Dual fix needed:** (1) Update `expected-output.md` to accept BOTH `RunAnalyzers=false` AND removal/consolidation as valid approaches (multi-path acceptance). (2) Update `build-perf-diagnostics` skill content to explicitly mention `RunAnalyzers=false` so the model doesn't miss it during binlog-based analysis. Also add analyzer packages that interact (e.g., StyleCop + .editorconfig enforcement). |
| **style-issues** | 4/4 | Agent invoked but no score improvement | Add deeply nested property import chains where style violations come from inherited properties, and require the response to trace the style issue back to its `Directory.Build.props` origin. |

#### General Hardening Strategies

**a. Multi-layer problems**: Each scenario should have 3+ issues at different difficulty levels — easy (model knows), medium (needs MSBuild context), hard (needs skill knowledge).

**b. Red herrings**: Add misleading symptoms (a build error that looks like a missing package but is actually an SDK version mismatch). The skill should help cut through these.

**c. Project graph complexity**: Increase to 6–10 projects with `ProjectReference` chains, `Directory.Build.props`/`.targets` at multiple levels, and conditional imports.

**d. Require multi-step reasoning**: Problems where fixing issue A reveals issue B. Skills should guide the model through the full diagnostic chain.

**e. Checklist depth**: Each hardened scenario should have 10+ checklist items in its `expected-output.md`, creating a wider scoring range.

### 5. Use Multiple Evaluation Runs with Aggregation

**Priority: MEDIUM** | **Impact: MEDIUM** | **Effort: LOW**

Even with a 0–10 scale, LLM-as-judge evaluations have inherent variance. Run the evaluation step 3 times per response and take the median (or mean with outlier rejection).

**Changes to evaluate-response.ps1:**

```powershell
$evaluationRuns = 3
$scores = @()

for ($i = 0; $i -lt $evaluationRuns; $i++) {
    $evalOutput = Invoke-EvaluationCopilot ...
    $evaluation = Parse-EvaluationJson -Output $evalOutput
    $scores += $evaluation
}

# Take median score
$medianScore = ($scores | Sort-Object { $_.score })[[math]::Floor($scores.Count / 2)]
```

**Trade-off:** 3x the evaluation cost/time, but much more stable scoring. Consider making this configurable (`-EvalRuns 3`).

### 6. Pin Evaluator Model and Temperature

**Priority: MEDIUM** | **Impact: MEDIUM** | **Effort: LOW**

The evaluator currently uses `--model claude-opus-4.5` but doesn't set temperature. If the Copilot CLI API supports temperature, set it to 0 for deterministic evaluation.

Additionally, consider using a different, faster model for evaluation (e.g., `claude-sonnet-4.5`) since the evaluator task is simpler than the scenario task. This would:
- Reduce evaluation cost
- Potentially improve consistency (simpler models may be more deterministic for structured scoring tasks)

### 7. Structured JSON Output for Evaluator

**Priority: LOW** | **Impact: MEDIUM** | **Effort: LOW**

The current evaluator prompt asks for a JSON response, but the evaluator sometimes wraps it in markdown code fences or adds text. The `Parse-EvaluationJson` function handles this with regex fallbacks, but this introduces fragility.

**Improvements:**
- Add stronger instructions: "Your response must be ONLY a JSON object. Do not include any other text, markdown formatting, or code fences."
- Consider using the `--silent` flag for evaluation calls to reduce noise
- Add retry logic: if JSON parsing fails, re-run the evaluation (up to 2 retries)

### 8. Add Response Quality Dimensions Specific to Skills

**Priority: MEDIUM** | **Impact: MEDIUM** | **Effort: LOW**

The current evaluation dimensions (Accuracy, Completeness, Actionability, Clarity) are generic. Add dimensions that specifically measure what skills should improve:

```json
{
  "score": 8,
  "accuracy": 8,
  "completeness": 7,
  "actionability": 9,
  "clarity": 9,
  "msbuild_depth": 7,
  "error_code_specificity": 8,
  "fix_correctness": 9,
  "reasoning": "..."
}
```

**New dimensions:**
- **MSBuild Depth**: Does the response reference specific MSBuild concepts (Inputs/Outputs, evaluation vs execution phase, property functions, etc.)?
- **Error Code Specificity**: Are specific error codes (CS0246, NETSDK1045, NU1605) mentioned and correctly explained?
- **Fix Correctness**: Are the proposed fixes syntactically correct XML/C# that would actually resolve the issue?

These dimensions specifically reward the kind of knowledge that skills provide, making it easier to detect skill impact.

### 9. Add Pairwise Comparison Evaluation Mode

**Priority: LOW** | **Impact: HIGH** | **Effort: MEDIUM**

Instead of scoring vanilla and skilled independently (which introduces evaluator bias toward consistency), show both responses to the evaluator side-by-side and ask "which is better and why?"

**Prompt template:**

```
You are evaluating two AI responses to the same MSBuild problem.

Response A and Response B are in the files response-a.txt and response-b.txt.
The expected output is in expected-output.md.

Compare the two responses and answer:
1. Which response better addresses the expected findings? (A/B/Tie)
2. What does the better response include that the other misses?
3. Score each response on a 0-10 scale.

Respond as JSON:
{"winner": "A|B|Tie", "score_a": <0-10>, "score_b": <0-10>, "reasoning": "..."}
```

**Benefits:**
- Forces the evaluator to actively compare, surfacing subtle differences
- Eliminates absolute scoring bias (everything isn't just "4/5" anymore)
- The winner field provides a clean signal even if scores are close

**Implementation note:** Randomly assign vanilla/skilled to A/B to prevent ordering bias.

**Relationship to independent scoring (#1/#2):** This is an experimental validation mode, not a replacement. Independent + checklist scoring is the primary workhorse. Run pairwise in parallel during Phase 5 to compare signal quality. Pairwise catches subtle differences checklists might miss.

### 10. Track and Save Session IDs for Reproducibility

**Priority: LOW** | **Impact: MEDIUM** | **Effort: LOW**

The Copilot CLI session state at `~/.copilot/session-state/<session-id>/` contains full event logs. Record the session ID for each run and save it in the results, enabling:
- Post-hoc debugging of what the model actually did
- Replaying sessions with `copilot --resume <session-id>`
- Extracting detailed tool-call traces for analysis
- Verifying skill activation without additional scraping

**Recommended approach — `--config-dir`** (tested, parallel-safe):

The `--config-dir <directory>` flag redirects all session state (including `session-state/`) to a custom directory. By pointing each copilot invocation at a per-scenario config directory, the session is automatically isolated — no directory-diffing or CWD-matching needed:

```powershell
# In run-scenario.ps1, create a per-run config directory
$sessionConfigDir = Join-Path $ResultsDir "${ScenarioName}-${RunType}-config"
New-Item -ItemType Directory -Path $sessionConfigDir -Force | Out-Null

# Add --config-dir to the copilot arguments
$copilotArgs = "-p `"$Prompt`" --model claude-opus-4.5 --allow-all-tools --allow-all-paths --no-ask-user --config-dir `"$sessionConfigDir`""

# After the run, the session is at:
#   $sessionConfigDir/session-state/<session-id>/events.jsonl
# Since there's exactly one session per config dir, just grab it:
$sessionDir = Get-ChildItem (Join-Path $sessionConfigDir "session-state") -Directory | Select-Object -First 1
$eventsFile = Join-Path $sessionDir.FullName "events.jsonl"
```

**Why this is the best approach:**
- **Parallel-safe**: Each run gets its own config directory, so concurrent evaluations never interfere
- **Deterministic**: Exactly one session per config directory — no ambiguity
- **Zero overhead**: No before/after snapshots, no post-hoc searching
- **Full data**: The events.jsonl contains all skill activations, tool calls, and session metadata

**Integration into `run-scenario.ps1`:**
- Add `--config-dir` to the copilot invocation with a per-scenario path under the results directory
- After the run, read the single session from `{config-dir}/session-state/*/events.jsonl`
- Extract skill activations and save to `{vanilla|skilled}-activations.json`
- Save the session ID to `{vanilla|skilled}-session.json`
- The skill activation check (#3) reads from these files directly

**Alternative approaches (validated but less convenient):**

<details>
<summary>Approach A — Before/after directory diff (sequential only)</summary>

```powershell
$beforeIds = Get-ChildItem "$env:USERPROFILE\.copilot\session-state" -Directory |
    Select-Object -ExpandProperty Name
# ... run copilot ...
$afterIds = Get-ChildItem "$env:USERPROFILE\.copilot\session-state" -Directory |
    Select-Object -ExpandProperty Name
$sessionId = $afterIds | Where-Object { $_ -notin $beforeIds }
```
Not safe for parallel runs.
</details>

<details>
<summary>Approach B — CWD matching (parallel-safe, post-hoc)</summary>

The `session.start` event records `context.cwd` matching the temp dir pattern `copilot-eval/{scenario}-{runtype}-{random}`:
```powershell
foreach ($sd in (Get-ChildItem "$env:USERPROFILE\.copilot\session-state" -Directory)) {
    $ef = Join-Path $sd.FullName "events.jsonl"
    if ((Test-Path $ef) -and (Select-String -Path $ef -Pattern $scenarioName -Quiet)) {
        $e = (Get-Content $ef -TotalCount 1) | ConvertFrom-Json
        return @{ SessionId = $sd.Name; Cwd = $e.data.context.cwd }
    }
}
```
Works but requires scanning all sessions.
</details>

---

## Recommended Implementation Order

| Phase | Items | Rationale |
|-------|-------|-----------|
| **Phase 1** (Quick wins) | #1 (0–10 scale), #2 (checklist scoring), #7 (JSON output) | Low-medium effort, immediately improves discriminative power |
| **Phase 2** (Skill verification) | #3 (skill activation logs), #10 (session IDs) | Catches "skills installed but not used" and "wrong skills activated" problems |
| **Phase 3** (Scenario hardening) | #4 (harder scenarios per table above) | Increases quality delta — the biggest lever for long-term evaluation value |
| **Phase 4** (Evaluator tuning) | #6 (pin evaluator model), #8 (new dimensions) | Makes scoring more deterministic and skill-sensitive |
| **Phase 5** (Statistical rigor) | #5 (multi-run aggregation), #9 (pairwise comparison) | Final polish for publication-quality results |

### Expected Impact

With phases 1–3 implemented, the evaluation should be able to detect skill value across all 12 scenarios:
- **0 of 12** scenarios currently show meaningful skill differentiation (on the 1–5 scale)
- **Target: 8+ of 12** scenarios showing measurable skill improvement on a 0–10 checklist scale with hardened testcases

### Applicability to `dotnet-unittest-skills`

Recommendations #1 (0–10 scale), #2 (checklist scoring), #3 (skill activation logs), #5 (multi-run aggregation), #7 (JSON output), and #10 (session IDs) are framework-level improvements that apply to both `msbuild-skills` and `dotnet-unittest-skills` evaluation pipelines. Recommendation #4 (scenario hardening) requires separate per-scenario analysis for the unittest testcases.

---

## Appendix: Session Log Structure

Copilot CLI stores session data at `~/.copilot/session-state/<session-id>/`:

```
<session-id>/
├── events.jsonl      # Complete event log (JSONL format)
├── workspace.yaml    # Session workspace metadata
├── checkpoints       # Checkpoint data
└── files             # Modified files tracking
```

**Key event types in `events.jsonl`:**

| Event Type | Description | Useful Fields |
|------------|-------------|---------------|
| `session.start` | Session initialization | `sessionId`, `selectedModel`, `context.cwd` |
| `user.message` | User prompt | `content` |
| `assistant.message` | Model response | `content`, `toolRequests[]` |
| `tool.execution_start` | Tool call begins | `toolName`, `arguments` |
| `tool.execution_complete` | Tool call ends | `success`, `result` |
| `subagent.started` | **Agent delegated** | `agentName`, `agentDisplayName`, `agentDescription` |
| `subagent.completed` | Agent finished | `agentName` |

### Skill Activation Detection

There are **two distinct mechanisms** for skill activation. Both must be checked:

**1. Skill tool calls** (most common — 10 of 11 activated scenarios use this):
```json
{
  "type": "tool.execution_start",
  "data": {
    "toolName": "skill",
    "arguments": { "skill": "binlog-generation" }
  }
}
```

**2. Subagent delegation** (used by agent-type skills like `msbuild-code-review`):
```json
{
  "type": "subagent.started",
  "data": {
    "toolCallId": "tooluse_yWC0wouPwwHxFAfeiBNfPC",
    "agentName": "msbuild-skills/msbuild-code-review",
    "agentDisplayName": "msbuild-code-review",
    "agentDescription": "Agent that reviews MSBuild project files..."
  }
}
```

### Detection Script

```powershell
function Get-SkillActivation {
    param([int]$SessionIndex = 0)  # 0 = most recent

    $sessionDir = Get-ChildItem "$env:USERPROFILE\.copilot\session-state" -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip $SessionIndex -First 1

    $eventsFile = Join-Path $sessionDir.FullName "events.jsonl"
    $lines = Get-Content $eventsFile
    $skills = @(); $agents = @()

    foreach ($line in $lines) {
        $e = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $e) { continue }
        if ($e.type -eq "tool.execution_start" -and $e.data.toolName -eq "skill") {
            $skills += $e.data.arguments.skill
        }
        if ($e.type -eq "subagent.started") {
            $agents += $e.data.agentName
        }
    }

    return @{
        SessionId = $sessionDir.Name
        Skills    = ($skills | Select-Object -Unique)
        Agents    = ($agents | Select-Object -Unique)
        Activated = ($skills.Count -gt 0 -or $agents.Count -gt 0)
    }
}
```
