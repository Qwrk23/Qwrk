<#
.SYNOPSIS
    Phase 2C Black-Box Certification Harness for Qwrk Gateway.

.DESCRIPTION
    Runs deterministic happy-path + fuzz tests against the live Gateway endpoint.
    Tests are loaded from JSON files, executed sequentially, and results are
    captured in machine-readable CSV + human-readable findings report.

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
    Path to results output directory. Default: ./results
#>
param(
    [string]$GatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1",
    [string]$WorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
    [string]$CredentialString = $env:QWRK_GW_CREDENTIAL,
    [string]$TestDir = "$PSScriptRoot/tests",
    [string]$ResultDir = "$PSScriptRoot/results"
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

# --- Setup Directories ---
$rawDir = Join-Path $ResultDir "raw"
if (-not (Test-Path $rawDir)) {
    New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
}

# --- Runtime State ---
$RunTimestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$captured = @{ "WORKSPACE_ID" = $WorkspaceId }
$results = @()
$aborted = $false
$abortReason = ""
$observations = @()
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

    # Encode body as UTF-8 bytes to avoid PowerShell encoding issues
    # (em dashes and other non-ASCII chars break without explicit UTF-8)
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

        # Method 1: ErrorDetails (PS5 + PS7)
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $raw = $_.ErrorDetails.Message
        }

        # Method 2: Response stream fallback (PS5)
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

function Test-SystemicInvariant {
    param($response, [string]$testName)

    # Check artifact shapes in various response envelopes
    $artifact = $null
    if ($response.data -and $response.data.artifact) {
        $artifact = $response.data.artifact
    }

    if ($artifact) {
        if ($null -ne $artifact.extension -and $artifact.extension -is [string]) {
            return "SYSTEMIC FAILURE: extension returned as string in [$testName]"
        }
        if ($null -ne $artifact.tags -and $artifact.tags -is [string]) {
            return "SYSTEMIC FAILURE: tags returned as string in [$testName]"
        }
    }

    return $null
}

function Test-Assertions {
    param($testDef, $response)

    $notes = @()
    $pass = $true

    $expectedOk = $testDef.expected.ok
    $expectedError = $testDef.expected.error_code

    # Resolve actual ok value
    $actualOk = $response.ok
    if ($null -eq $actualOk) { $actualOk = $false }

    # Compare ok status
    if ([bool]$actualOk -ne [bool]$expectedOk) {
        $pass = $false
        $notes += "Expected ok=$expectedOk, got ok=$actualOk"
    }

    # Compare error code (only for expected-failure tests with specific code)
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

    # Validate error envelope shape on error responses
    if (-not [bool]$actualOk) {
        if (-not $response.error) {
            $notes += "WARN: error response missing 'error' object"
        }
        elseif (-not $response.error.code) {
            $notes += "WARN: error response missing 'error.code'"
        }
    }

    # --- T70: Rollup assertions ---

    # Rollup presence/absence
    if ($testDef.expected.PSObject.Properties.Name -contains "rollup_present") {
        $hasRollup = ($null -ne $response.data -and $null -ne $response.data.rollup)
        if ($testDef.expected.rollup_present -and -not $hasRollup) {
            $pass = $false; $notes += "Expected rollup present, not found"
        }
    }
    if ($testDef.expected.PSObject.Properties.Name -contains "rollup_absent") {
        $hasRollup = ($null -ne $response.data -and $null -ne $response.data.rollup)
        if ($testDef.expected.rollup_absent -and $hasRollup) {
            $pass = $false; $notes += "Expected rollup absent, found rollup"
        }
    }

    # Integer rollup fields (exact match)
    foreach ($field in @("completed_children_count", "total_active_children_count")) {
        if ($testDef.expected.PSObject.Properties.Name -contains $field) {
            $actual = $null
            if ($null -ne $response.data -and $null -ne $response.data.rollup) {
                $actual = $response.data.rollup.$field
            }
            $expected = $testDef.expected.$field
            if ($actual -ne $expected) {
                $pass = $false; $notes += "Expected $field=$expected, got=$actual"
            }
        }
    }

    # Completion ratio (tolerance-based for numeric precision)
    if ($testDef.expected.PSObject.Properties.Name -contains "completion_ratio") {
        $actual = $null
        if ($null -ne $response.data -and $null -ne $response.data.rollup) {
            $actual = $response.data.rollup.completion_ratio
        }
        $expected = $testDef.expected.completion_ratio
        if ($null -eq $expected -and $null -ne $actual) {
            $pass = $false; $notes += "Expected completion_ratio=null, got=$actual"
        }
        elseif ($null -ne $expected -and $null -eq $actual) {
            $pass = $false; $notes += "Expected completion_ratio=$expected, got=null"
        }
        elseif ($null -ne $expected -and $null -ne $actual) {
            $diff = [Math]::Abs([double]$actual - [double]$expected)
            if ($diff -gt 0.01) {
                $pass = $false; $notes += "Expected completion_ratio=$expected, got=$actual (diff=$diff)"
            }
        }
    }

    return @{ Pass = $pass; Notes = ($notes -join "; ") }
}

# ============================================================
# Main Execution
# ============================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Phase 2C Black-Box Certification Harness"   -ForegroundColor Cyan
Write-Host " Run: $RunTimestamp"                          -ForegroundColor Cyan
Write-Host " Gateway: $GatewayUrl"                        -ForegroundColor Cyan
Write-Host " Workspace: $WorkspaceId"                     -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Load test files sorted alphabetically (determines execution order)
$testFiles = Get-ChildItem -Path $TestDir -Filter "*.json" | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Error "No test files found in $TestDir"
    exit 1
}

Write-Host "Found $($testFiles.Count) test files." -ForegroundColor Yellow
Write-Host ""

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
    if ($resolvedPayload -match '\{\{[A-Z0-9_]+\}\}') {
        $missing = ([regex]::Matches($resolvedPayload, '\{\{([A-Z0-9_]+)\}\}') |
            ForEach-Object { $_.Groups[1].Value }) -join ", "
        $skipCount++
        Write-Host " [SKIP] Missing: $missing" -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            TestName = $testDef.name
            Expected = ($testDef.expected | ConvertTo-Json -Compress)
            Actual   = "SKIPPED"
            Pass     = "SKIP"
            Notes    = "Unresolved: $missing"
        }
        continue
    }

    # Execute Gateway call
    $callResult = Invoke-GatewayCall $resolvedPayload
    $response = $callResult.Body

    # Save raw response
    $rawFile = Join-Path $rawDir "$($file.BaseName).json"
    if ($callResult.Raw) {
        $callResult.Raw | Out-File $rawFile -Encoding utf8
    } else {
        $response | ConvertTo-Json -Depth 10 | Out-File $rawFile -Encoding utf8
    }

    # Systemic invariant check (abort-on-fail)
    $systemic = Test-SystemicInvariant $response $testDef.name
    if ($systemic) {
        $aborted = $true
        $abortReason = $systemic
        $failCount++
        Write-Host " [ABORT] $systemic" -ForegroundColor Red
        $results += [PSCustomObject]@{
            TestName = $testDef.name
            Expected = ($testDef.expected | ConvertTo-Json -Compress)
            Actual   = "SYSTEMIC_FAILURE"
            Pass     = "FAIL"
            Notes    = $systemic
        }
        continue
    }

    # Run assertions
    $assertResult = Test-Assertions $testDef $response

    if ($assertResult.Pass) {
        $passCount++
        Write-Host " [PASS]" -ForegroundColor Green
    }
    else {
        $failCount++
        Write-Host " [FAIL] $($assertResult.Notes)" -ForegroundColor Red
    }

    # Capture variables from response
    if ($testDef.capture) {
        foreach ($prop in $testDef.capture.PSObject.Properties) {
            $val = Get-ResponseField $response $prop.Value
            if ($val) {
                $captured[$prop.Name] = $val.ToString()
                Write-Host "         Captured $($prop.Name) = $val" -ForegroundColor DarkGray
            }
            else {
                Write-Host "         WARN: Could not capture $($prop.Name) from '$($prop.Value)'" -ForegroundColor Yellow
            }
        }
    }

    # Record result
    $actualOk = if ($null -ne $response.ok) { $response.ok } else { "null" }
    $actualError = if ($response.error -and $response.error.code) { $response.error.code } else { "none" }

    $results += [PSCustomObject]@{
        TestName = $testDef.name
        Expected = ($testDef.expected | ConvertTo-Json -Compress)
        Actual   = "ok=$actualOk error=$actualError"
        Pass     = if ($assertResult.Pass) { "PASS" } else { "FAIL" }
        Notes    = $assertResult.Notes
    }

    # Sequential discipline: brief pause between tests
    Start-Sleep -Milliseconds 500
}

# ============================================================
# Verification Queries
# ============================================================

Write-Host ""
Write-Host "--- Verification Queries ---" -ForegroundColor Cyan

$verifyTargets = @()
if ($captured.ContainsKey("JOURNAL_ID")) {
    $verifyTargets += @{ Name = "Journal (A01)"; Id = $captured["JOURNAL_ID"]; Type = "journal" }
}
if ($captured.ContainsKey("PROJECT_ID")) {
    $verifyTargets += @{ Name = "Project (A04)"; Id = $captured["PROJECT_ID"]; Type = "project" }
}
if ($captured.ContainsKey("SNAPSHOT_ID")) {
    $verifyTargets += @{ Name = "Snapshot (A11)"; Id = $captured["SNAPSHOT_ID"]; Type = "snapshot" }
}
if ($captured.ContainsKey("RESTART_ID")) {
    $verifyTargets += @{ Name = "Restart (A13)"; Id = $captured["RESTART_ID"]; Type = "restart" }
}
if ($captured.ContainsKey("FUZZ_JOURNAL_ID")) {
    $verifyTargets += @{ Name = "Fuzz Journal (B01)"; Id = $captured["FUZZ_JOURNAL_ID"]; Type = "journal" }
}
if ($captured.ContainsKey("FUZZ_PROJECT_ID")) {
    $verifyTargets += @{ Name = "Fuzz Project (B02)"; Id = $captured["FUZZ_PROJECT_ID"]; Type = "project" }
}

foreach ($target in $verifyTargets) {
    if ($aborted) {
        $skipCount++
        $results += [PSCustomObject]@{
            TestName = "VERIFY $($target.Name)"
            Expected = "extension=object, tags=array"
            Actual   = "ABORTED"
            Pass     = "SKIP"
            Notes    = $abortReason
        }
        continue
    }

    $totalTests++
    $shortId = $target.Id.Substring(0, 8)
    $verifyName = "VERIFY $($target.Name) [$shortId]"
    Write-Host "[$totalTests] $verifyName" -ForegroundColor White -NoNewline

    $queryPayload = @{
        gw_action      = "artifact.query"
        gw_workspace_id = $WorkspaceId
        artifact_type  = $target.Type
        artifact_id    = $target.Id
        selector       = @{ hydrate = $true }
    } | ConvertTo-Json -Depth 5

    $callResult = Invoke-GatewayCall $queryPayload
    $response = $callResult.Body

    # Save raw
    $safeName = $target.Name -replace '[^a-zA-Z0-9_]', '_'
    $rawFile = Join-Path $rawDir "VERIFY_$safeName.json"
    if ($callResult.Raw) {
        $callResult.Raw | Out-File $rawFile -Encoding utf8
    }

    # Extract artifact from response
    $artifact = $null
    if ($response.data -and $response.data.artifact) { $artifact = $response.data.artifact }
    elseif ($response.artifact) { $artifact = $response.artifact }

    $verifyPass = $true
    $verifyNotes = @()

    if (-not $artifact) {
        $verifyPass = $false
        $verifyNotes += "Artifact not found in response"
    }
    else {
        # CRITICAL: extension must be object or null, never string
        if ($null -ne $artifact.extension -and $artifact.extension -is [string]) {
            $verifyPass = $false
            $verifyNotes += "CRITICAL: extension is STRING"
            $aborted = $true
            $abortReason = "Extension returned as string on verify query"
        }
        elseif ($null -ne $artifact.extension) {
            $verifyNotes += "extension=object"
        }
        else {
            $verifyNotes += "extension=null"
        }

        # CRITICAL: tags must be array or null, never string
        if ($null -ne $artifact.tags -and $artifact.tags -is [string]) {
            $verifyPass = $false
            $verifyNotes += "CRITICAL: tags is STRING"
            $aborted = $true
            $abortReason = "Tags returned as string on verify query"
        }
        elseif ($null -ne $artifact.tags) {
            $tagCount = @($artifact.tags).Count
            $verifyNotes += "tags=array($tagCount)"
        }
        else {
            $verifyNotes += "tags=null"
        }

        # Observe version (informational)
        if ($artifact.version) {
            $verifyNotes += "v=$($artifact.version)"
            $observations += "$($target.Name): version=$($artifact.version)"
        }
    }

    if ($verifyPass) {
        $passCount++
        Write-Host " [PASS] $($verifyNotes -join ', ')" -ForegroundColor Green
    }
    else {
        $failCount++
        Write-Host " [FAIL] $($verifyNotes -join ', ')" -ForegroundColor Red
    }

    $results += [PSCustomObject]@{
        TestName = $verifyName
        Expected = "extension=object, tags=array"
        Actual   = ($verifyNotes -join "; ")
        Pass     = if ($verifyPass) { "PASS" } else { "FAIL" }
        Notes    = ""
    }

    Start-Sleep -Milliseconds 300
}

# ============================================================
# CSV Summary
# ============================================================

$csvFile = Join-Path $ResultDir "summary.csv"
$results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding utf8
Write-Host ""
Write-Host "CSV: $csvFile" -ForegroundColor Yellow

# ============================================================
# Findings Report
# ============================================================

$findingsFile = Join-Path $ResultDir "findings.md"
$conclusion = if ($failCount -eq 0 -and -not $aborted) { "PASS" } else { "FAIL" }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Phase 2C Certification Report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Field | Value |")
[void]$sb.AppendLine("|-------|-------|")
[void]$sb.AppendLine("| Timestamp | $RunTimestamp |")
[void]$sb.AppendLine("| Gateway URL | $GatewayUrl |")
[void]$sb.AppendLine("| Workspace | $WorkspaceId |")
[void]$sb.AppendLine("| Gateway Version | v58 |")
[void]$sb.AppendLine("| Save Version | v37 |")
[void]$sb.AppendLine("| Update Version | v36 |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Summary")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Metric | Count |")
[void]$sb.AppendLine("|--------|-------|")
[void]$sb.AppendLine("| Total Tests | $totalTests |")
[void]$sb.AppendLine("| Passed | $passCount |")
[void]$sb.AppendLine("| Failed | $failCount |")
[void]$sb.AppendLine("| Skipped | $skipCount |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Results")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| # | Test | Result | Notes |")
[void]$sb.AppendLine("|---|------|--------|-------|")

$i = 0
foreach ($r in $results) {
    $i++
    [void]$sb.AppendLine("| $i | $($r.TestName) | $($r.Pass) | $($r.Notes) |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Failures")
[void]$sb.AppendLine("")

$failures = $results | Where-Object { $_.Pass -eq "FAIL" }
if ($failures.Count -eq 0) {
    [void]$sb.AppendLine("None.")
}
else {
    foreach ($f in $failures) {
        [void]$sb.AppendLine("- **$($f.TestName)**: $($f.Notes)")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Observations")
[void]$sb.AppendLine("")

if ($observations.Count -eq 0 -and -not $aborted) {
    [void]$sb.AppendLine("None.")
}
else {
    foreach ($o in $observations) {
        [void]$sb.AppendLine("- $o")
    }
    if ($aborted) {
        [void]$sb.AppendLine("- **ABORT:** $abortReason")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Captured Artifact IDs")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Variable | Value |")
[void]$sb.AppendLine("|----------|-------|")

foreach ($key in ($captured.Keys | Sort-Object)) {
    if ($key -ne "WORKSPACE_ID") {
        [void]$sb.AppendLine("| $key | ``$($captured[$key])`` |")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Conclusion")
[void]$sb.AppendLine("")

if ($conclusion -eq "PASS") {
    [void]$sb.AppendLine("**PASS**")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("All tests passed. Extension objects and tag arrays preserved through full mutation lifecycle. Systemic coercion defenses (convertFieldsToString: false + Save v37 normalization) verified operational.")
}
else {
    [void]$sb.AppendLine("**FAIL**")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("One or more tests failed. Review failures above for remediation.")
}

$sb.ToString() | Out-File $findingsFile -Encoding utf8

Write-Host "Report: $findingsFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CONCLUSION: $conclusion" -ForegroundColor $(if ($conclusion -eq "PASS") { "Green" } else { "Red" })
Write-Host "============================================" -ForegroundColor Cyan
