# =============================================================================
# Multi-User Qwrk — Gateway Clone Test Suite
# =============================================================================
# TEMPLATE — Replace {{placeholders}} with real values before execution.
# Run from: PowerShell 7+
# Created: 2026-02-17
# =============================================================================

param(
    [string]$GatewayName = "{{gateway_name}}",
    [string]$WebhookUrl  = "{{webhook_url}}",
    [string]$Principal   = "{{principal_name}}",
    [string]$Password    = "{{password}}",
    [string]$WorkspaceId = "{{workspace_uuid}}",
    [string]$WrongWorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"  # Joel's personal (wrong for clones)
)

# --- Auth Header ---
$pair = "${Principal}:${Password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Gateway Test Suite: $GatewayName" -ForegroundColor Cyan
Write-Host "  Webhook: $WebhookUrl" -ForegroundColor Gray
Write-Host "  Principal: $Principal" -ForegroundColor Gray
Write-Host "  Workspace: $WorkspaceId" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = 0
$failed = 0

# =============================================================================
# TEST 1: Allowed Workspace (Expect HTTP 200)
# =============================================================================
Write-Host "[TEST 1] Allowed Workspace — artifact.list (expect 200)" -ForegroundColor Yellow

$body1 = @{
    gw_action       = "artifact.list"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "project"
    selector        = @{
        limit  = 3
        offset = 0
    }
} | ConvertTo-Json -Depth 5

try {
    $response1 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body1 -UseBasicParsing
    $status1 = $response1.StatusCode
    $json1 = $response1.Content | ConvertFrom-Json

    if ($status1 -eq 200 -and $json1.ok -eq $true) {
        Write-Host "  PASS — HTTP $status1, ok: true" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL — HTTP $status1, ok: $($json1.ok)" -ForegroundColor Red
        Write-Host "  Response: $($response1.Content)" -ForegroundColor Gray
        $failed++
    }
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "  FAIL — HTTP $errStatus (expected 200)" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
    $failed++
}

# =============================================================================
# TEST 2: Wrong Workspace (Expect HTTP 403)
# =============================================================================
Write-Host "`n[TEST 2] Wrong Workspace — artifact.list (expect 403)" -ForegroundColor Yellow

$body2 = @{
    gw_action       = "artifact.list"
    gw_workspace_id = $WrongWorkspaceId
    artifact_type   = "project"
    selector        = @{
        limit  = 3
        offset = 0
    }
} | ConvertTo-Json -Depth 5

try {
    $response2 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body2 -UseBasicParsing
    # If we get here with 200, the test failed (should have been 403)
    Write-Host "  FAIL — HTTP $($response2.StatusCode) (expected 403)" -ForegroundColor Red
    Write-Host "  Response: $($response2.Content)" -ForegroundColor Gray
    $failed++
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    if ($errStatus -eq 403) {
        Write-Host "  PASS — HTTP 403 (correctly denied)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL — HTTP $errStatus (expected 403)" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
        $failed++
    }
}

# =============================================================================
# TEST 3: Malformed Request (Expect Error Response)
# =============================================================================
Write-Host "`n[TEST 3] Malformed Request — missing gw_action (expect error)" -ForegroundColor Yellow

$body3 = @{
    gw_workspace_id = $WorkspaceId
    artifact_type   = "project"
} | ConvertTo-Json -Depth 5

try {
    $response3 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body3 -UseBasicParsing
    $json3 = $response3.Content | ConvertFrom-Json

    if ($json3.ok -eq $false -and $json3.error.code -eq "VALIDATION_ERROR") {
        Write-Host "  PASS — VALIDATION_ERROR returned" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL — Expected VALIDATION_ERROR, got: $($json3.error.code)" -ForegroundColor Red
        Write-Host "  Response: $($response3.Content)" -ForegroundColor Gray
        $failed++
    }
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    # Some error responses come back as non-200, which PowerShell treats as exceptions
    try {
        $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errBody.ok -eq $false) {
            Write-Host "  PASS — Error response returned (HTTP $errStatus)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAIL — HTTP $errStatus, unexpected body" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  FAIL — HTTP $errStatus, could not parse response" -ForegroundColor Red
        $failed++
    }
}

# =============================================================================
# SUMMARY
# =============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Results: $passed PASSED / $failed FAILED / 3 TOTAL" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "  ACTION REQUIRED: Fix failures before proceeding." -ForegroundColor Red
    exit 1
}
