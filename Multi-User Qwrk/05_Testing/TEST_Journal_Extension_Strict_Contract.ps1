# =============================================================================
# Journal Extension Strict Contract — Test Suite
# =============================================================================
# Tests the JOURNAL_EXTENSION_INVALID validation gate on Save sub-workflow.
# Requires: Gateway webhook with Basic Auth credentials.
# Run from: PowerShell 7+
# Created: 2026-02-19
# =============================================================================

param(
    [string]$WebhookUrl  = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1",
    [string]$Principal   = "qwrk-gateway",
    [string]$Password    = "",
    [string]$WorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
)

if (-not $Password) {
    Write-Host "ERROR: -Password parameter is required." -ForegroundColor Red
    Write-Host "Usage: .\TEST_Journal_Extension_Strict_Contract.ps1 -Password '<password>'" -ForegroundColor Yellow
    exit 1
}

# --- Auth Header ---
$pair = "${Principal}:${Password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Journal Extension Strict Contract Tests" -ForegroundColor Cyan
Write-Host "  Webhook: $WebhookUrl" -ForegroundColor Gray
Write-Host "  Workspace: $WorkspaceId" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = 0
$failed = 0
$total = 4

# =============================================================================
# TEST 1: Valid Journal Roundtrip
# Save journal with entry_text → Query → Assert hydrated extension matches
# =============================================================================
Write-Host "[TEST 1] Valid Journal Save with entry_text (expect ok: true)" -ForegroundColor Yellow

$body1 = @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "journal"
    title           = "Test - Journal Extension Strict Contract Validation"
    priority        = 3
    tags            = @("test", "journal-extension-strict")
    extension       = @{
        entry_text = "This is a valid journal entry for strict contract testing."
    }
} | ConvertTo-Json -Depth 5

try {
    $response1 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body1 -UseBasicParsing
    $json1 = $response1.Content | ConvertFrom-Json

    if ($json1.ok -eq $true -or $json1.data.artifact.artifact_id) {
        $savedId = $json1.data.artifact.artifact_id
        Write-Host "  PASS — Journal saved successfully (artifact_id: $savedId)" -ForegroundColor Green

        # Query to verify hydrated extension
        $queryBody = @{
            gw_action       = "artifact.query"
            gw_workspace_id = $WorkspaceId
            artifact_type   = "journal"
            artifact_id     = $savedId
        } | ConvertTo-Json -Depth 5

        $queryResp = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $queryBody -UseBasicParsing
        $queryJson = $queryResp.Content | ConvertFrom-Json
        $hydrated = $queryJson.data.artifact.extension.entry_text

        if ($hydrated -eq "This is a valid journal entry for strict contract testing.") {
            Write-Host "  PASS — Hydrated entry_text matches input" -ForegroundColor Green
        } else {
            Write-Host "  WARN — entry_text mismatch: '$hydrated'" -ForegroundColor Yellow
        }
        $passed++
    } else {
        Write-Host "  FAIL — Unexpected response: $($response1.Content)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL — Exception: $($_.Exception.Message)" -ForegroundColor Red
    try { Write-Host "  Body: $($_.ErrorDetails.Message)" -ForegroundColor Gray } catch {}
    $failed++
}

# =============================================================================
# TEST 2: Invalid Field Rejection (extension.entry instead of entry_text)
# =============================================================================
Write-Host "`n[TEST 2] Invalid field: extension.entry (expect JOURNAL_EXTENSION_INVALID)" -ForegroundColor Yellow

$body2 = @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "journal"
    title           = "Test - Invalid Extension Key"
    priority        = 3
    tags            = @("test", "should-fail")
    extension       = @{
        entry = "This uses the wrong key and should be rejected."
    }
} | ConvertTo-Json -Depth 5

try {
    $response2 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body2 -UseBasicParsing
    $json2 = $response2.Content | ConvertFrom-Json

    if ($json2.ok -eq $false -and $json2.error.code -eq "JOURNAL_EXTENSION_INVALID") {
        Write-Host "  PASS — JOURNAL_EXTENSION_INVALID returned" -ForegroundColor Green
        $passed++
    } elseif ($json2.ok -eq $false) {
        Write-Host "  PARTIAL — Rejected but wrong code: $($json2.error.code)" -ForegroundColor Yellow
        Write-Host "  Message: $($json2.error.message)" -ForegroundColor Gray
        $failed++
    } else {
        Write-Host "  FAIL — Save succeeded (should have been rejected)" -ForegroundColor Red
        Write-Host "  Response: $($response2.Content)" -ForegroundColor Gray
        $failed++
    }
} catch {
    try {
        $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errBody.ok -eq $false -and $errBody.error.code -eq "JOURNAL_EXTENSION_INVALID") {
            Write-Host "  PASS — JOURNAL_EXTENSION_INVALID returned" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAIL — Error but wrong code: $($errBody.error.code)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  FAIL — Exception: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

# =============================================================================
# TEST 3: Empty entry_text Rejection
# =============================================================================
Write-Host "`n[TEST 3] Empty entry_text (expect JOURNAL_EXTENSION_INVALID)" -ForegroundColor Yellow

$body3 = @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "journal"
    title           = "Test - Empty Entry Text"
    priority        = 3
    tags            = @("test", "should-fail")
    extension       = @{
        entry_text = ""
    }
} | ConvertTo-Json -Depth 5

try {
    $response3 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body3 -UseBasicParsing
    $json3 = $response3.Content | ConvertFrom-Json

    if ($json3.ok -eq $false -and $json3.error.code -eq "JOURNAL_EXTENSION_INVALID") {
        Write-Host "  PASS — JOURNAL_EXTENSION_INVALID returned for empty entry_text" -ForegroundColor Green
        $passed++
    } elseif ($json3.ok -eq $false) {
        Write-Host "  PARTIAL — Rejected but wrong code: $($json3.error.code)" -ForegroundColor Yellow
        $failed++
    } else {
        Write-Host "  FAIL — Save succeeded with empty entry_text (should have been rejected)" -ForegroundColor Red
        $failed++
    }
} catch {
    try {
        $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errBody.ok -eq $false -and $errBody.error.code -eq "JOURNAL_EXTENSION_INVALID") {
            Write-Host "  PASS — JOURNAL_EXTENSION_INVALID returned for empty entry_text" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAIL — Error but wrong code: $($errBody.error.code)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  FAIL — Exception: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

# =============================================================================
# TEST 4: Non-Journal Artifacts Unaffected (Snapshot)
# =============================================================================
Write-Host "`n[TEST 4] Snapshot save unaffected by journal validation (expect ok: true)" -ForegroundColor Yellow

$body4 = @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "snapshot"
    title           = "Test - Snapshot Unaffected by Journal Validation"
    priority        = 3
    tags            = @("test", "journal-extension-strict")
    extension       = @{
        payload = @{
            test = $true
            note = "This snapshot should succeed regardless of journal validation."
        }
    }
} | ConvertTo-Json -Depth 5

try {
    $response4 = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $body4 -UseBasicParsing
    $json4 = $response4.Content | ConvertFrom-Json

    if ($json4.ok -eq $true -or $json4.data.artifact.artifact_id) {
        Write-Host "  PASS — Snapshot saved successfully (no journal validation interference)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL — Snapshot rejected unexpectedly: $($response4.Content)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL — Exception: $($_.Exception.Message)" -ForegroundColor Red
    try { Write-Host "  Body: $($_.ErrorDetails.Message)" -ForegroundColor Gray } catch {}
    $failed++
}

# =============================================================================
# SUMMARY
# =============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Results: $passed PASSED / $failed FAILED / $total TOTAL" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "  ACTION REQUIRED: Fix failures before proceeding." -ForegroundColor Red
    exit 1
} else {
    Write-Host "  All journal extension strict contract tests passed." -ForegroundColor Green
    exit 0
}
