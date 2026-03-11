# T69 Assert_Semantic_UUID Verification Suite
# Validates the last-mile UUID assertion guard in Save workflow
# Execute via: powershell -File "scripts/t69_assert_suite.ps1"
#
# A1: Top-level with text key "governance" -> PASS (UUID resolved upstream; assert passes)
# A2: Top-level with direct UUID -> PASS (UUID passthrough; assert passes)
# A3: Non-top-level (branch) without semantic_type_id -> PASS (null; assert passes)
# A4: Non-top-level (branch) WITH semantic_type_id -> FAIL (VALIDATION_ERROR upstream)
# Note: A4 tests Validate_Request rejection, not Assert directly. Assert is defense-in-depth.

param(
    [string]$Test = "all"  # all, A1, A2, A3, A4
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
$a1ArtifactId = $null

# ============================================================
# A1 -- Top-level with text key "governance" (positive test -- CREATES SNAPSHOT)
# Expected: ok:true (UUID resolved by Guard_Semantic_Type, Assert passes)
# ============================================================
if ($Test -eq "all" -or $Test -eq "A1") {
    Write-Host "`n=== A1: Top-level with text key (governance) ===" -ForegroundColor Cyan
    Write-Host "  NOTE: This test CREATES a snapshot artifact" -ForegroundColor DarkYellow

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "snapshot"
        title = "T69 Assert Suite -- A1 (text key governance)"
        semantic_type_id = "governance"
        extension = @{
            payload = @{
                test_suite = "t69_assert_semantic_uuid"
                test_id = "A1"
                purpose = "Validate text key resolves to UUID and passes assertion"
            }
        }
    } | ConvertTo-Json -Depth 5

    Write-Host "  Payload:" -ForegroundColor DarkGray
    Write-Host "  $payload" -ForegroundColor DarkGray

    $resp = Invoke-GW -JsonBody $payload
    Write-Host "  Response:" -ForegroundColor Yellow
    Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

    $a1ArtifactId = $resp.artifact_id
    $pass = ($resp.ok -eq $true) -and ($null -ne $a1ArtifactId)

    Write-Host "  ok: $($resp.ok)"
    Write-Host "  artifact_id: $a1ArtifactId"
    Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

    $results += [PSCustomObject]@{
        Test = "A1"; Description = "Top-level text key"
        ErrorCode = if ($pass) { "N/A (ok)" } else { $resp.error.code }
        ExpectedCode = "ok:true"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# A2 -- Top-level with direct UUID (positive test -- CREATES SNAPSHOT)
# Depends on A1: queries A1 artifact to extract resolved UUID
# Expected: ok:true (UUID passthrough, Assert passes)
# ============================================================
if ($Test -eq "all" -or $Test -eq "A2") {
    Write-Host "`n=== A2: Top-level with direct UUID ===" -ForegroundColor Cyan

    $resolvedUuid = $null

    if ($a1ArtifactId) {
        $queryPayload = @{
            gw_action = "artifact.query"
            gw_workspace_id = $WorkspaceId
            artifact_type = "snapshot"
            artifact_id = $a1ArtifactId
            selector = @{ hydrate = $true }
        } | ConvertTo-Json -Depth 5

        $queryResp = Invoke-GW -JsonBody $queryPayload
        $resolvedUuid = $queryResp.data.artifact.semantic_type_id
        Write-Host "  Resolved UUID from A1 artifact: $resolvedUuid" -ForegroundColor DarkGray
    }

    if ($resolvedUuid) {
        Write-Host "  NOTE: This test CREATES a snapshot artifact" -ForegroundColor DarkYellow

        $payload = @{
            gw_action = "artifact.save"
            gw_workspace_id = $WorkspaceId
            artifact_type = "snapshot"
            title = "T69 Assert Suite -- A2 (direct UUID)"
            semantic_type_id = $resolvedUuid
            extension = @{
                payload = @{
                    test_suite = "t69_assert_semantic_uuid"
                    test_id = "A2"
                    purpose = "Validate direct UUID passthrough passes assertion"
                    source_uuid = $resolvedUuid
                }
            }
        } | ConvertTo-Json -Depth 5

        Write-Host "  Payload:" -ForegroundColor DarkGray
        Write-Host "  $payload" -ForegroundColor DarkGray

        $resp = Invoke-GW -JsonBody $payload
        Write-Host "  Response:" -ForegroundColor Yellow
        Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

        $a2ArtifactId = $resp.artifact_id
        $pass = ($resp.ok -eq $true) -and ($null -ne $a2ArtifactId)

        Write-Host "  ok: $($resp.ok)"
        Write-Host "  artifact_id: $a2ArtifactId"
        Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

        $results += [PSCustomObject]@{
            Test = "A2"; Description = "Top-level direct UUID"
            ErrorCode = if ($pass) { "N/A (ok)" } else { $resp.error.code }
            ExpectedCode = "ok:true"
            Result = if ($pass) { "PASS" } else { "FAIL" }
        }
    } else {
        Write-Host "  SKIP: A1 did not produce a resolvable UUID" -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            Test = "A2"; Description = "Top-level direct UUID"
            ErrorCode = "N/A"; ExpectedCode = "ok:true"
            Result = "SKIP"
        }
    }
}

# ============================================================
# A3 -- Non-top-level (branch) without semantic_type_id (positive test -- CREATES BRANCH)
# Expected: ok:true (semantic_type_id is null; Assert allows null for non-top-level)
# ============================================================
if ($Test -eq "all" -or $Test -eq "A3") {
    Write-Host "`n=== A3: Non-top-level without semantic_type_id ===" -ForegroundColor Cyan
    Write-Host "  NOTE: This test CREATES a branch artifact" -ForegroundColor DarkYellow

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "branch"
        title = "T69 Assert Suite -- A3 (branch, no semantic_type_id)"
        parent_artifact_id = $KgbProjectId
    } | ConvertTo-Json -Depth 5

    Write-Host "  Payload:" -ForegroundColor DarkGray
    Write-Host "  $payload" -ForegroundColor DarkGray

    $resp = Invoke-GW -JsonBody $payload
    Write-Host "  Response:" -ForegroundColor Yellow
    Write-Host "  $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor Yellow

    $a3ArtifactId = $resp.artifact_id
    $pass = ($resp.ok -eq $true) -and ($null -ne $a3ArtifactId)

    Write-Host "  ok: $($resp.ok)"
    Write-Host "  artifact_id: $a3ArtifactId"
    Write-Host "  RESULT: $(if ($pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($pass) { 'Green' } else { 'Red' })

    $results += [PSCustomObject]@{
        Test = "A3"; Description = "Non-top-level (no semantic_type_id)"
        ErrorCode = if ($pass) { "N/A (ok)" } else { $resp.error.code }
        ExpectedCode = "ok:true"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# A4 -- Non-top-level (branch) WITH semantic_type_id (rejection test -- no mutation)
# Expected: VALIDATION_ERROR (Validate_Request rejects semantic_type_id on non-top-level)
# Note: This tests defense-in-depth. Validate_Request catches it first.
# If Validate_Request were bypassed, Assert would catch it with SEMANTIC_TYPE_RESOLUTION_FAILED.
# ============================================================
if ($Test -eq "all" -or $Test -eq "A4") {
    Write-Host "`n=== A4: Non-top-level WITH semantic_type_id ===" -ForegroundColor Cyan

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = "branch"
        title = "A4 Test -- should be rejected"
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
        Test = "A4"; Description = "Non-top-level WITH semantic_type_id"
        ErrorCode = $errorCode; ExpectedCode = "VALIDATION_ERROR"
        Result = if ($pass) { "PASS" } else { "FAIL" }
    }
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host "`n============================================================" -ForegroundColor White
Write-Host "ASSERT_SEMANTIC_UUID VERIFICATION SUMMARY" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White

$results | Format-Table -AutoSize

$passCount = ($results | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($results | Where-Object { $_.Result -eq "FAIL" }).Count
$skipCount = ($results | Where-Object { $_.Result -eq "SKIP" }).Count

Write-Host "PASS: $passCount  FAIL: $failCount  SKIP: $skipCount" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })

if ($failCount -eq 0) {
    Write-Host "`nCERTIFICATION: PASS (Assert_Semantic_UUID validated)" -ForegroundColor Green
} else {
    Write-Host "`nCERTIFICATION: FAIL" -ForegroundColor Red
}
