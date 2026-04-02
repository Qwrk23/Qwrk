<#
.SYNOPSIS
    T51 Extension Update Surface Determinism — Certification Harness.

.DESCRIPTION
    Runs D-series tests validating T51 extension update determinism:
    - Per-type allowlist enforcement
    - Full-replace semantics (omitted fields reset)
    - Unknown key rejection
    - Lifecycle guardrail (promote-only)
    - Hydration symmetry
    Tests are loaded from JSON files (D*.json), executed sequentially.

.PARAMETER GatewayUrl
    Gateway webhook endpoint URL.

.PARAMETER WorkspaceId
    Target workspace UUID.

.PARAMETER CredentialString
    Basic auth credential in "user:pass" format.
    Falls back to QWRK_GW_CREDENTIAL environment variable.

.PARAMETER TestDir
    Path to test JSON files directory. Default: ./tests

.PARAMETER ResultDir
    Path to results output directory. Default: ./results/t51
#>
param(
    [string]$GatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2",
    [string]$WorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
    [string]$CredentialString = $env:QWRK_GW_CREDENTIAL,
    [string]$TestDir = "$PSScriptRoot/tests",
    [string]$ResultDir = "$PSScriptRoot/results/t51",
    [switch]$RetainArtifacts
)

# --- Credential Setup ---
if (-not $CredentialString) {
    Write-Host "No credential provided." -ForegroundColor Red
    Write-Host "Set QWRK_GW_CREDENTIAL env var or pass -CredentialString 'user:pass'" -ForegroundColor Yellow
    exit 1
}

$base64Cred = [System.Convert]::ToBase64String(
    [System.Text.Encoding]::ASCII.GetBytes($CredentialString)
)
$script:Headers = @{
    "Authorization" = "Basic $base64Cred"
    "Content-Type"  = "application/json"
}
$script:GatewayUrl = $GatewayUrl

# --- Setup Directories ---
$rawDir = Join-Path $ResultDir "raw"
if (-not (Test-Path $rawDir)) {
    New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
}

# --- Runtime State ---
$RunTimestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$RunId = "t51-cert-$RunTimestamp"
$captured = @{ "WORKSPACE_ID" = $WorkspaceId; "RUN_TAG" = "run:$RunId" }
$createdArtifactIds = @()
$results = @()
$aborted = $false
$abortReason = ""
$totalTests = 0
$passCount = 0
$failCount = 0
$skipCount = 0

# ============================================================
# Helper Functions
# ============================================================

function Resolve-Placeholders {
    param([string]$json, [hashtable]$vars)
    foreach ($key in $vars.Keys) {
        $json = $json.Replace("{{$key}}", $vars[$key])
    }
    return $json
}

function Invoke-GatewayCall {
    param([string]$jsonBody)
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
    $invokeParams = @{
        Uri             = $script:GatewayUrl
        Method          = 'POST'
        Body            = $bodyBytes
        ContentType     = 'application/json; charset=utf-8'
        Headers         = $script:Headers
        UseBasicParsing = $true
    }
    try {
        $resp = Invoke-WebRequest @invokeParams
        $parsed = $resp.Content | ConvertFrom-Json
        return @{
            StatusCode = [int]$resp.StatusCode
            Body       = $parsed
            Raw        = $resp.Content
            Error      = $null
        }
    }
    catch {
        $statusCode = 0
        $raw = ""
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $raw = $_.ErrorDetails.Message
        }
        if (-not $raw -and $_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $raw = $reader.ReadToEnd()
                $reader.Close()
            }
            catch { }
        }
        $parsed = $null
        if ($raw) {
            try { $parsed = $raw | ConvertFrom-Json }
            catch {
                $snippet = $raw.Substring(0, [Math]::Min(500, $raw.Length))
                $parsed = @{ ok = $false; error = @{ code = "PARSE_ERROR"; message = $snippet } }
            }
        }
        else {
            $parsed = @{ ok = $false; error = @{ code = "CONNECTION_ERROR"; message = $_.Exception.Message } }
            $raw = $_.Exception.Message
        }
        return @{
            StatusCode = $statusCode
            Body       = $parsed
            Raw        = $raw
            Error      = $_.Exception.Message
        }
    }
}

function Get-ResponseField {
    param($obj, [string]$fieldPath)
    foreach ($part in $fieldPath.Split(".")) {
        if ($null -eq $obj) { return $null }
        $obj = $obj.$part
    }
    return $obj
}

function Test-Assertions {
    param($testDef, $response)
    $notes = @()
    $pass = $true
    $expectedOk = $testDef.expected.ok
    $expectedError = $testDef.expected.error_code
    $actualOk = $response.ok
    if ($null -eq $actualOk) { $actualOk = $false }
    if ([bool]$actualOk -ne [bool]$expectedOk) {
        $pass = $false
        $notes += "Expected ok=$expectedOk, got ok=$actualOk"
    }
    if (-not $expectedOk -and $expectedError) {
        $actualError = $null
        if ($response.error -and $response.error.code) {
            $actualError = $response.error.code
        }
        if ($actualError -ne $expectedError) {
            $pass = $false
            $notes += "Expected error=$expectedError, got=$actualError"
        }
    }
    if (-not [bool]$actualOk) {
        if (-not $response.error) {
            $notes += "WARN: error response missing 'error' object"
        }
        elseif (-not $response.error.code) {
            $notes += "WARN: error response missing 'error.code'"
        }
    }
    return @{ Pass = $pass; Notes = ($notes -join "; ") }
}

# ============================================================
# Main Execution — D-series only
# ============================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " T51 Extension Update Surface Certification" -ForegroundColor Cyan
Write-Host " Run: $RunTimestamp"                          -ForegroundColor Cyan
Write-Host " Gateway: $GatewayUrl"                       -ForegroundColor Cyan
Write-Host " Workspace: $WorkspaceId"                    -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Load ONLY D-series test files (T51 tests)
$testFiles = Get-ChildItem -Path $TestDir -Filter "D*.json" | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Error "No D-series test files found in $TestDir"
    exit 1
}

Write-Host "Found $($testFiles.Count) T51 test files." -ForegroundColor Yellow
Write-Host ""

# Also check for A-series SNAPSHOT_ID dependency
# D08 needs SNAPSHOT_ID from A11 — create a snapshot if needed
$needsSnapshot = $testFiles | Where-Object { $_.Name -like "*snapshot*" }
if ($needsSnapshot) {
    Write-Host "[SETUP] Creating snapshot for D08 dependency..." -ForegroundColor DarkGray
    $snapshotPayload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "snapshot"
        title = "[T51-CERT] Snapshot for immutability test"
        tags = @("t51-cert")
        extension = @{
            payload = @{ purpose = "T51 immutability verification" }
        }
    } | ConvertTo-Json -Depth 10
    $snapshotResp = Invoke-GatewayCall $snapshotPayload
    if ($snapshotResp.Body.ok) {
        $captured["SNAPSHOT_ID"] = $snapshotResp.Body.artifact_id
        $createdArtifactIds += $snapshotResp.Body.artifact_id.ToString()
        Write-Host "  Snapshot created: $($captured['SNAPSHOT_ID'])" -ForegroundColor DarkGreen
    }
    else {
        Write-Host "  WARN: Could not create snapshot. D08 may fail." -ForegroundColor Yellow
    }
    Write-Host ""
}

foreach ($file in $testFiles) {
    if ($aborted) {
        $skipCount++
        Write-Host "  [ABORT] Skipping $($file.Name)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            TestName = $file.BaseName
            Expected = "SKIPPED"
            Actual   = "ABORTED"
            Pass     = "SKIP"
            Notes    = $abortReason
        }
        continue
    }

    $totalTests++

    # Load test definition
    $testJson = Get-Content $file.FullName -Raw
    $testDef = $testJson | ConvertFrom-Json

    Write-Host "[$totalTests] $($testDef.name)" -ForegroundColor White -NoNewline

    # Serialize payload and resolve placeholders
    $payloadStr = $testDef.payload | ConvertTo-Json -Depth 10
    $resolvedPayload = Resolve-Placeholders $payloadStr $captured

    # Check for unresolved placeholders
    if ($resolvedPayload -match '\{\{[A-Z_]+\}\}') {
        $missing = ([regex]::Matches($resolvedPayload, '\{\{([A-Z_]+)\}\}') |
            ForEach-Object { $_.Groups[1].Value }) -join ", "
        $skipCount++
        Write-Host " [SKIP] Missing: $missing" -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            TestName = $testDef.name
            Expected = ($testDef.expected | ConvertTo-Json -Compress)
            Actual   = "SKIP"
            Pass     = "SKIP"
            Notes    = "Missing variables: $missing"
        }
        continue
    }

    # Execute
    $resp = Invoke-GatewayCall $resolvedPayload

    # Save raw response
    $rawPath = Join-Path $rawDir "$($file.BaseName).json"
    $resp.Raw | Set-Content -Path $rawPath -Encoding UTF8

    # Assertions
    $assertResult = Test-Assertions $testDef $resp.Body

    # Capture variables
    if ($testDef.capture -and $assertResult.Pass) {
        $capObj = $testDef.capture
        foreach ($prop in $capObj.PSObject.Properties) {
            $val = Get-ResponseField $resp.Body $prop.Value
            if ($val) {
                $captured[$prop.Name] = $val.ToString()
                if ($prop.Value -eq "artifact_id") {
                    $createdArtifactIds += $val.ToString()
                }
            }
        }
    }

    # Record result
    $actualSummary = "ok=$($resp.Body.ok) error=$(if ($resp.Body.error) { $resp.Body.error.code } else { 'none' })"

    if ($assertResult.Pass) {
        $passCount++
        Write-Host " [PASS]" -ForegroundColor Green
        if ($assertResult.Notes) {
            Write-Host "    $($assertResult.Notes)" -ForegroundColor DarkGray
        }
    }
    else {
        $failCount++
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    $($assertResult.Notes)" -ForegroundColor Red
    }

    $results += [PSCustomObject]@{
        TestName = $testDef.name
        Expected = ($testDef.expected | ConvertTo-Json -Compress)
        Actual   = $actualSummary
        Pass     = if ($assertResult.Pass) { "PASS" } else { "FAIL" }
        Notes    = $assertResult.Notes
    }
}

# ============================================================
# T51-Specific Verification Phase
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " T51 Verification Phase"                     -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$verifyTargets = @()
if ($captured["D_PROJECT_ID"]) {
    $verifyTargets += @{ Name = "Project (D01)"; Id = $captured["D_PROJECT_ID"]; Type = "project" }
}
if ($captured["D_JOURNAL_ID"]) {
    $verifyTargets += @{ Name = "Journal (D06)"; Id = $captured["D_JOURNAL_ID"]; Type = "journal" }
}
if ($captured["D_IPACK_ID"]) {
    $verifyTargets += @{ Name = "Instruction Pack (D12)"; Id = $captured["D_IPACK_ID"]; Type = "instruction_pack" }
}

foreach ($target in $verifyTargets) {
    $queryPayload = @{
        gw_action       = "artifact.query"
        gw_workspace_id = $WorkspaceId
        artifact_type   = $target.Type
        artifact_id     = $target.Id
        selector        = @{ hydrate = $true }
    } | ConvertTo-Json -Depth 5

    $qResp = Invoke-GatewayCall $queryPayload

    if ($qResp.Body.ok -or $qResp.Body.data) {
        $artifact = if ($qResp.Body.data -and $qResp.Body.data.artifact) { $qResp.Body.data.artifact } else { $qResp.Body }

        $extType = if ($null -ne $artifact.extension) { $artifact.extension.GetType().Name } else { "null" }
        $tagsType = if ($null -ne $artifact.tags) { $artifact.tags.GetType().Name } else { "null" }
        $version = $artifact.version

        $verifyPass = $true
        $verifyNotes = @()

        # Type invariants
        if ($null -ne $artifact.extension -and $artifact.extension -is [string]) {
            $verifyPass = $false
            $verifyNotes += "SYSTEMIC: extension is string"
        }
        if ($null -ne $artifact.tags -and $artifact.tags -is [string]) {
            $verifyPass = $false
            $verifyNotes += "SYSTEMIC: tags is string"
        }

        # T51 Full-replace verification for project
        if ($target.Type -eq "project") {
            # After D10 (send only summary), expect:
            # - operational_state = 'active' (DEFAULT reset)
            # - state_reason = null (nullable reset)
            if ($null -ne $artifact.operational_state -and $artifact.operational_state -ne "active") {
                $verifyNotes += "WARN: operational_state='$($artifact.operational_state)' (expected 'active' after full-replace)"
            }
            if ($null -ne $artifact.state_reason) {
                $verifyNotes += "WARN: state_reason='$($artifact.state_reason)' (expected null after full-replace)"
            }
            # Verify summary was written
            if ($null -ne $artifact.summary) {
                $verifyNotes += "summary present: '$($artifact.summary.Substring(0, [Math]::Min(50, $artifact.summary.Length)))...'"
            }
        }

        $statusStr = if ($verifyPass) { "PASS" } else { "FAIL" }
        $notesStr = if ($verifyNotes.Count -gt 0) { $verifyNotes -join "; " } else { "" }
        $shortId = $target.Id.Substring(0, 8)

        Write-Host "VERIFY $($target.Name) [$shortId] " -NoNewline
        Write-Host "ext=$extType; tags=$tagsType; v=$version " -NoNewline -ForegroundColor DarkGray
        if ($notesStr) { Write-Host "| $notesStr " -NoNewline -ForegroundColor DarkYellow }
        Write-Host "[$statusStr]" -ForegroundColor $(if ($verifyPass) { "Green" } else { "Red" })

        $results += [PSCustomObject]@{
            TestName = "VERIFY $($target.Name)"
            Expected = "type_invariants"
            Actual   = "ext=$extType; tags=$tagsType; v=$version"
            Pass     = $statusStr
            Notes    = $notesStr
        }
        if ($verifyPass) { $passCount++ } else { $failCount++ }
        $totalTests++
    }
    else {
        Write-Host "VERIFY $($target.Name) [FAIL] Could not query" -ForegroundColor Red
        $failCount++
        $totalTests++
    }
}

# ============================================================
# Cleanup Phase — Soft-Delete Test Artifacts
# ============================================================

if (-not $RetainArtifacts) {
    Write-Host ""
    Write-Host "--- Cleanup Phase ---" -ForegroundColor Cyan

    if ($createdArtifactIds.Count -eq 0) {
        Write-Host "  No artifacts to clean up." -ForegroundColor DarkGray
    }
    else {
        Write-Host "  Cleaning up $($createdArtifactIds.Count) test artifacts..." -ForegroundColor Yellow
        $cleanupPass = 0
        $cleanupFail = 0

        foreach ($artifactId in $createdArtifactIds) {
            $deletePayload = @{
                gw_action       = "artifact.delete"
                gw_workspace_id = $WorkspaceId
                artifact_id     = $artifactId
            } | ConvertTo-Json -Depth 5

            $deleteResult = Invoke-GatewayCall $deletePayload

            if ($deleteResult.Body.ok) {
                $cleanupPass++
                $shortId = $artifactId.Substring(0, 8)
                Write-Host "    [DEL] $shortId" -ForegroundColor DarkGray
            }
            else {
                $cleanupFail++
                $errCode = if ($deleteResult.Body.error) { $deleteResult.Body.error.code } else { "UNKNOWN" }
                $shortId = $artifactId.Substring(0, 8)
                Write-Host "    [FAIL] $shortId ($errCode)" -ForegroundColor Red
            }

            Start-Sleep -Milliseconds 300
        }

        Write-Host "  [CLEANUP] Primary cleanup complete: $cleanupPass artifacts deleted" -ForegroundColor $(
            if ($cleanupFail -eq 0) { "Green" } else { "Yellow" }
        )
        if ($cleanupFail -gt 0) {
            Write-Host "  [CLEANUP] Primary cleanup failures: $cleanupFail" -ForegroundColor Yellow
        }
    }

    # --- Fallback Cleanup by RUN_TAG ---
    Write-Host ""
    Write-Host "  --- Fallback Cleanup (RUN_TAG sweep) ---" -ForegroundColor Cyan

    $runTag = $captured["RUN_TAG"]
    $fallbackTypes = @("journal", "project", "snapshot", "instruction_pack")
    $fallbackDeleted = 0
    $fallbackErrors = 0

    foreach ($aType in $fallbackTypes) {
        $listPayload = @{
            gw_action       = "artifact.list"
            gw_workspace_id = $WorkspaceId
            artifact_type   = $aType
            selector        = @{
                tags  = @($runTag)
                limit = 100
            }
        } | ConvertTo-Json -Depth 5

        $listResult = Invoke-GatewayCall $listPayload

        # Extract artifacts from response (handle both envelope shapes)
        $artifacts = @()
        if ($listResult.Body.data -and $listResult.Body.data.artifacts) {
            $artifacts = @($listResult.Body.data.artifacts)
        }
        elseif ($listResult.Body.artifacts) {
            $artifacts = @($listResult.Body.artifacts)
        }

        foreach ($art in $artifacts) {
            $artId = if ($art.artifact_id) { $art.artifact_id.ToString() } else { $null }
            if (-not $artId) { continue }

            $deletePayload = @{
                gw_action       = "artifact.delete"
                gw_workspace_id = $WorkspaceId
                artifact_id     = $artId
            } | ConvertTo-Json -Depth 5

            $deleteResult = Invoke-GatewayCall $deletePayload

            if ($deleteResult.Body.ok) {
                $fallbackDeleted++
                $shortId = $artId.Substring(0, 8)
                Write-Host "    [FALLBACK-DEL] $shortId ($aType)" -ForegroundColor DarkYellow
            }
            else {
                $fallbackErrors++
                $errCode = if ($deleteResult.Body.error) { $deleteResult.Body.error.code } else { "UNKNOWN" }
                if ($errCode -eq "ALREADY_DELETED" -or $errCode -eq "NOT_FOUND") {
                    $fallbackErrors--
                }
                else {
                    $shortId = $artId.Substring(0, 8)
                    Write-Host "    [FALLBACK-FAIL] $shortId ($errCode)" -ForegroundColor Red
                }
            }

            Start-Sleep -Milliseconds 200
        }
    }

    if ($fallbackDeleted -eq 0) {
        Write-Host "  [CLEANUP] Fallback: no residual artifacts found" -ForegroundColor Green
    }
    else {
        Write-Host "  [CLEANUP] Fallback removed $fallbackDeleted additional artifacts" -ForegroundColor DarkYellow
        if ($fallbackErrors -gt 0) {
            Write-Host "  [CLEANUP] Fallback errors: $fallbackErrors" -ForegroundColor Red
        }
    }
}
else {
    Write-Host ""
    Write-Host "--- Cleanup SKIPPED (-RetainArtifacts) ---" -ForegroundColor Yellow
    Write-Host "  Run tag: $($captured['RUN_TAG'])" -ForegroundColor DarkGray
}

# ============================================================
# Results Summary
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " T51 Results Summary"                        -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total:   $totalTests" -ForegroundColor White
Write-Host "Passed:  $passCount"  -ForegroundColor Green
Write-Host "Failed:  $failCount"  -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "Skipped: $skipCount"  -ForegroundColor $(if ($skipCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

# --- Write CSV ---
$csvPath = Join-Path $ResultDir "t51_summary.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "CSV: $csvPath" -ForegroundColor DarkGray

# --- Write Findings ---
$findingsPath = Join-Path $ResultDir "t51_findings.md"
$findings = @"
# T51 Extension Update Surface — Certification Findings

**Run:** $RunTimestamp
**Gateway:** $GatewayUrl
**Workspace:** $WorkspaceId

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | $totalTests |
| Passed | $passCount |
| Failed | $failCount |
| Skipped | $skipCount |

## Results

| # | Test | Result | Notes |
|---|------|--------|-------|
"@

$i = 1
foreach ($r in $results) {
    $findings += "`n| $i | $($r.TestName) | $($r.Pass) | $($r.Notes) |"
    $i++
}

$findings += @"

## Captured Artifact IDs

| Variable | Value |
|----------|-------|
"@

foreach ($key in ($captured.Keys | Sort-Object)) {
    $findings += "`n| $key | ``$($captured[$key])`` |"
}

$conclusion = if ($failCount -eq 0 -and $skipCount -eq 0) { "PASS" } else { "FAIL" }
$findings += @"

## Conclusion

**$conclusion** — $passCount/$totalTests tests passed.
"@

$findings | Set-Content -Path $findingsPath -Encoding UTF8
Write-Host "Findings: $findingsPath" -ForegroundColor DarkGray
Write-Host ""

if ($failCount -eq 0 -and $skipCount -eq 0) {
    Write-Host "T51 CERTIFICATION: PASS" -ForegroundColor Green
}
else {
    Write-Host "T51 CERTIFICATION: FAIL" -ForegroundColor Red
}
