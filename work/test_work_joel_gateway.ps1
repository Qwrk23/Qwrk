# Test suite for NQxb_Gateway_v1__Work_Joel
# Temporary file — delete after testing

$webhookUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$principal = "qwrk-gw-work"
$password = "ufwpjNF0PEMq4R92ST6zKQM5eeVs7BnM"
$workspaceId = "635bb8d7-7b93-4bea-8ca6-ee2c924c9557"
$wrongWorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"

$pair = "${principal}:${password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

Write-Host "`n========================================"
Write-Host "  Gateway Test: NQxb_Gateway_v1__Work_Joel"
Write-Host "  URL: $webhookUrl"
Write-Host "  Principal: $principal"
Write-Host "  Workspace: $workspaceId"
Write-Host "========================================`n"

$passed = 0
$failed = 0

# --- TEST 1: Allowed Workspace (expect 200) ---
Write-Host "[TEST 1] Allowed Workspace - artifact.list (expect 200)" -ForegroundColor Yellow

$body1 = @{
    gw_action       = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type   = "snapshot"
    selector        = @{ limit = 1 }
} | ConvertTo-Json -Depth 5

try {
    $response1 = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body1 -UseBasicParsing
    $status1 = $response1.StatusCode
    $json1 = $response1.Content | ConvertFrom-Json

    if ($status1 -eq 200 -and $json1.ok -eq $true) {
        Write-Host "  PASS - HTTP $status1, ok: true" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - HTTP $status1, ok: $($json1.ok)" -ForegroundColor Red
        Write-Host "  Response: $($response1.Content)" -ForegroundColor Gray
        $failed++
    }
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "  FAIL - HTTP $errStatus (expected 200)" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
    $failed++
}

# --- TEST 2: Wrong Workspace (expect 403) ---
Write-Host "`n[TEST 2] Wrong Workspace - artifact.list (expect 403)" -ForegroundColor Yellow

$body2 = @{
    gw_action       = "artifact.list"
    gw_workspace_id = $wrongWorkspaceId
    artifact_type   = "snapshot"
    selector        = @{ limit = 1 }
} | ConvertTo-Json -Depth 5

try {
    $response2 = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body2 -UseBasicParsing
    Write-Host "  FAIL - HTTP $($response2.StatusCode) (expected 403)" -ForegroundColor Red
    Write-Host "  Response: $($response2.Content)" -ForegroundColor Gray
    $failed++
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    if ($errStatus -eq 403) {
        Write-Host "  PASS - HTTP 403 (correctly denied)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - HTTP $errStatus (expected 403)" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
        $failed++
    }
}

# --- TEST 3: Malformed Request (expect error) ---
Write-Host "`n[TEST 3] Malformed Request - missing gw_action (expect error)" -ForegroundColor Yellow

$body3 = @{
    gw_workspace_id = $workspaceId
} | ConvertTo-Json -Depth 5

try {
    $response3 = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body3 -UseBasicParsing
    $json3 = $response3.Content | ConvertFrom-Json

    if ($json3.ok -eq $false -and $json3.error.code -eq "VALIDATION_ERROR") {
        Write-Host "  PASS - VALIDATION_ERROR returned" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Expected VALIDATION_ERROR, got: $($json3.error.code)" -ForegroundColor Red
        Write-Host "  Response: $($response3.Content)" -ForegroundColor Gray
        $failed++
    }
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    try {
        $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errBody.ok -eq $false) {
            Write-Host "  PASS - Error response returned (HTTP $errStatus)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAIL - HTTP $errStatus, unexpected body" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  FAIL - HTTP $errStatus, could not parse response" -ForegroundColor Red
        $failed++
    }
}

# --- SUMMARY ---
Write-Host "`n========================================"
Write-Host "  Results: $passed PASSED / $failed FAILED / 3 TOTAL" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n"
