# T69 Save Contract B Test Suite
# Validates dual-mode semantic_type_id resolution in Save workflow
# Execute via: powershell -File "scripts/t69_save_suite.ps1"
#
# S1: Text key "governance" -> resolve and save (CREATES ARTIFACT)
# S2: Direct UUID -> pass through and save (CREATES ARTIFACT, depends on S1)
# S3: Bad text key -> INVALID_SEMANTIC_TYPE (rejection, no mutation)
# S4: Random UUID not in registry -> INVALID_SEMANTIC_TYPE (rejection, no mutation)
# S5: SKIP (no inactive registry entries)
# S6: Non-top-level with semantic_type_id -> VALIDATION_ERROR (rejection)

param(
    [string]$Test = "all"  # all, S1, S2, S3, S4, S5, S6
)

$GatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$WorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$Credential = [System.Convert]::ToBase64String(
    [System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l")
)
$Headers = @{
    "Authorization" = "Basic $Credential"
    "Content-Type"  = "application/json; charset=utf-8"
}

# KGB project for parent_artifact_id references
$KgbProjectId = "668bd18f-4424-41e6-b2f9-393ecd2ec534"

function Invoke-GW {
    param([string]$JsonBody)
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($JsonBody)
    try {
        $resp = Invoke-WebRequest -Uri $GatewayUrl -Method POST -Body $bodyBytes `
            -Headers $Headers -ContentType "application/json; charset=utf-8" -UseBasicParsing
        return ($resp.Content | ConvertFrom-Json)
    }
    catch {
        $raw = ""
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $raw = $_.ErrorDetails.Message
        }
        if ($raw) {
            try { return ($raw | ConvertFrom-Json) } catch { return @{ _raw_error = $raw } }
        }
        return @{ _exception = $_.Exception.Message }
    }
}

$results = @()
$s1ArtifactId = $null

# ============================================================
# S3 -- Bad text key (rejection test -- no mutation)
# Expected: INVALID_SEMANTIC_TYPE
# ============================================================
if ($Test -eq "all" -or $Test -eq "S3") {
    Write-Host "`n=== S3: Bad text key ===" -ForegroundColor Cyan

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "snapshot"
        title = "S3 Test -- should be rejected"
        semantic_type_id = "nonexistent-fake-type"
        extension = @{
            payload = @{ test = "S3" }
        }
    } | ConvertTo-Json -Depth 5

    Write-Host "  Payload:" -ForegroundColor DarkGray
    Write-Host "  $payload" -ForegroundColor DarkGray

    $resp = Invoke-GW -JsonBody $payload
    Write-Host "  Response:" -ForegroundColor Yellow
    Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

    $errorCode = $resp.error.code
    $pass = ($errorCode -eq "INVALID_SEMANTIC_TYPE") -and ($resp.ok -eq $false)

    Write-Host "  Error code: $errorCode"
    Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

    $results += [PSCustomObject]@{
        Test = "S3"; Description = "Bad text key"
        ErrorCode = $errorCode; ExpectedCode = "INVALID_SEMANTIC_TYPE"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# S4 -- Random UUID not in registry (rejection test -- no mutation)
# Expected: INVALID_SEMANTIC_TYPE
# ============================================================
if ($Test -eq "all" -or $Test -eq "S4") {
    Write-Host "`n=== S4: Random UUID not in registry ===" -ForegroundColor Cyan

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "snapshot"
        title = "S4 Test -- should be rejected"
        semantic_type_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        extension = @{
            payload = @{ test = "S4" }
        }
    } | ConvertTo-Json -Depth 5

    Write-Host "  Payload:" -ForegroundColor DarkGray
    Write-Host "  $payload" -ForegroundColor DarkGray

    $resp = Invoke-GW -JsonBody $payload
    Write-Host "  Response:" -ForegroundColor Yellow
    Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

    $errorCode = $resp.error.code
    $pass = ($errorCode -eq "INVALID_SEMANTIC_TYPE") -and ($resp.ok -eq $false)

    Write-Host "  Error code: $errorCode"
    Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

    $results += [PSCustomObject]@{
        Test = "S4"; Description = "Random UUID not in registry"
        ErrorCode = $errorCode; ExpectedCode = "INVALID_SEMANTIC_TYPE"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# S5 -- SKIP (no inactive registry entries)
# ============================================================
if ($Test -eq "all" -or $Test -eq "S5") {
    Write-Host "`n=== S5: Inactive type ===" -ForegroundColor Yellow
    Write-Host "  All 9 bootstrap semantic types are active." -ForegroundColor DarkYellow
    Write-Host "  RESULT: SKIP (no inactive registry entry available)" -ForegroundColor Yellow

    $results += [PSCustomObject]@{
        Test = "S5"; Description = "Inactive type"
        ErrorCode = "N/A"; ExpectedCode = "SEMANTIC_TYPE_INACTIVE"
        Result = "SKIP"
    }
}

# ============================================================
# S6 -- Non-top-level with semantic_type_id (rejection test -- no mutation)
# Expected: VALIDATION_ERROR (Validate_Request rejects semantic_type_id on non-top-level)
# ============================================================
if ($Test -eq "all" -or $Test -eq "S6") {
    Write-Host "`n=== S6: Non-top-level with semantic_type_id ===" -ForegroundColor Cyan

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "branch"
        title = "S6 Test -- should be rejected"
        semantic_type_id = "governance"
        parent_artifact_id = $KgbProjectId
    } | ConvertTo-Json -Depth 5

    Write-Host "  Payload:" -ForegroundColor DarkGray
    Write-Host "  $payload" -ForegroundColor DarkGray

    $resp = Invoke-GW -JsonBody $payload
    Write-Host "  Response:" -ForegroundColor Yellow
    Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

    $errorCode = $resp.error.code
    $pass = ($errorCode -eq "VALIDATION_ERROR") -and ($resp.ok -eq $false)

    Write-Host "  Error code: $errorCode"
    Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

    $results += [PSCustomObject]@{
        Test = "S6"; Description = "Non-top-level with semantic_type_id"
        ErrorCode = $errorCode; ExpectedCode = "VALIDATION_ERROR"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# S1 -- Text key "governance" (positive test -- CREATES SNAPSHOT)
# Expected: ok:true with artifact_id
# ============================================================
if ($Test -eq "all" -or $Test -eq "S1") {
    Write-Host "`n=== S1: Text key resolution (governance) ===" -ForegroundColor Cyan
    Write-Host "  NOTE: This test CREATES a snapshot artifact" -ForegroundColor DarkYellow

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "snapshot"
        title = "T69 Save Contract B -- S1 Test (text key)"
        semantic_type_id = "governance"
        extension = @{
            payload = @{
                test_suite = "t69_save_contract_b"
                test_id = "S1"
                purpose = "Validate text key -> UUID resolution"
            }
        }
    } | ConvertTo-Json -Depth 5

    Write-Host "  Payload:" -ForegroundColor DarkGray
    Write-Host "  $payload" -ForegroundColor DarkGray

    $resp = Invoke-GW -JsonBody $payload
    Write-Host "  Response:" -ForegroundColor Yellow
    Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

    $s1ArtifactId = $resp.artifact_id
    $pass = ($resp.ok -eq $true) -and ($null -ne $s1ArtifactId)

    Write-Host "  ok: $($resp.ok)"
    Write-Host "  artifact_id: $s1ArtifactId"
    Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

    $results += [PSCustomObject]@{
        Test = "S1"; Description = "Text key resolution"
        ErrorCode = if ($pass) { "N/A (ok)" } else { $resp.error.code }
        ExpectedCode = "ok:true"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# S2 -- Direct UUID (positive test -- CREATES SNAPSHOT)
# Depends on S1: queries S1 artifact to extract resolved UUID
# Expected: ok:true with artifact_id
# ============================================================
if ($Test -eq "all" -or $Test -eq "S2") {
    Write-Host "`n=== S2: Direct UUID resolution ===" -ForegroundColor Cyan

    $resolvedUuid = $null

    if ($s1ArtifactId) {
        # Query S1 artifact to get the resolved semantic_type_id UUID
        $queryPayload = @{
            gw_action = "artifact.query"
            gw_workspace_id = $WorkspaceId
            artifact_type = "snapshot"
            artifact_id = $s1ArtifactId
            selector = @{ hydrate = $true }
        } | ConvertTo-Json -Depth 5

        $queryResp = Invoke-GW -JsonBody $queryPayload
        $resolvedUuid = $queryResp.data.artifact.semantic_type_id
        Write-Host "  Resolved UUID from S1 artifact: $resolvedUuid" -ForegroundColor DarkGray
    }

    if ($resolvedUuid) {
        Write-Host "  NOTE: This test CREATES a snapshot artifact" -ForegroundColor DarkYellow

        $payload = @{
            gw_action = "artifact.save"
            gw_workspace_id = $WorkspaceId
            artifact_type = "snapshot"
            title = "T69 Save Contract B -- S2 Test (direct UUID)"
            semantic_type_id = $resolvedUuid
            extension = @{
                payload = @{
                    test_suite = "t69_save_contract_b"
                    test_id = "S2"
                    purpose = "Validate direct UUID passthrough"
                    source_uuid = $resolvedUuid
                }
            }
        } | ConvertTo-Json -Depth 5

        Write-Host "  Payload:" -ForegroundColor DarkGray
        Write-Host "  $payload" -ForegroundColor DarkGray

        $resp = Invoke-GW -JsonBody $payload
        Write-Host "  Response:" -ForegroundColor Yellow
        Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

        $s2ArtifactId = $resp.artifact_id
        $pass = ($resp.ok -eq $true) -and ($null -ne $s2ArtifactId)

        Write-Host "  ok: $($resp.ok)"
        Write-Host "  artifact_id: $s2ArtifactId"
        Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

        $results += [PSCustomObject]@{
            Test = "S2"; Description = "Direct UUID resolution"
            ErrorCode = if ($pass) { "N/A (ok)" } else { $resp.error.code }
            ExpectedCode = "ok:true"
            Result = if ($pass) { "PASS" } else { "FAIL" }
        }
    } else {
        Write-Host "  SKIP: S1 did not produce a resolvable UUID" -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            Test = "S2"; Description = "Direct UUID resolution"
            ErrorCode = "N/A"; ExpectedCode = "ok:true"
            Result = "SKIP"
        }
    }
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host "`n============================================================" -ForegroundColor White
Write-Host "SAVE CONTRACT B SUMMARY" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White

$results | Format-Table -AutoSize

$passCount = ($results | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($results | Where-Object { $_.Result -eq "FAIL" }).Count
$skipCount = ($results | Where-Object { $_.Result -eq "SKIP" }).Count

Write-Host "PASS: $passCount  FAIL: $failCount  SKIP: $skipCount" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })

if ($failCount -eq 0) {
    Write-Host "`nCERTIFICATION: PASS (Save Contract B validated)" -ForegroundColor Green
} else {
    Write-Host "`nCERTIFICATION: FAIL" -ForegroundColor Red
}
