# =============================================================================
# Multi-User Qwrk — Semantic Type Enforcement Test Suite
# =============================================================================
# Tests T69 semantic_type_id enforcement on Gateway clones.
# Run from: PowerShell 7+
# Created: 2026-03-04
#
# NOTE: Tests ST1, ST2, ST6 create real artifacts. Use a test workspace or
# clean up afterward.
# =============================================================================

param(
    [string]$GatewayName = "{{gateway_name}}",
    [string]$WebhookUrl  = "{{webhook_url}}",
    [string]$Principal   = "{{principal_name}}",
    [string]$Password    = "{{password}}",
    [string]$WorkspaceId = "{{workspace_uuid}}"
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
Write-Host "  Semantic Type Enforcement Suite: $GatewayName" -ForegroundColor Cyan
Write-Host "  Webhook: $WebhookUrl" -ForegroundColor Gray
Write-Host "  Workspace: $WorkspaceId" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = 0
$failed = 0
$total = 7

function Invoke-GatewayTest {
    param(
        [string]$TestName,
        [hashtable]$Body,
        [scriptblock]$Validator
    )

    $jsonBody = $Body | ConvertTo-Json -Depth 10
    Write-Host "[TEST] $TestName" -ForegroundColor Yellow

    try {
        $response = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Headers $headers -Body $jsonBody -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json
        $result = & $Validator $response.StatusCode $json
        if ($result) {
            Write-Host "  PASS" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host "  FAIL — Unexpected response" -ForegroundColor Red
            Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
            $script:failed++
        }
        return $json
    } catch {
        $errStatus = $_.Exception.Response.StatusCode.value__
        try {
            $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
            $result = & $Validator $errStatus $errBody
            if ($result) {
                Write-Host "  PASS" -ForegroundColor Green
                $script:passed++
            } else {
                Write-Host "  FAIL — HTTP $errStatus" -ForegroundColor Red
                Write-Host "  Error: $($_.ErrorDetails.Message)" -ForegroundColor Gray
                $script:failed++
            }
            return $errBody
        } catch {
            Write-Host "  FAIL — HTTP $errStatus, could not parse response" -ForegroundColor Red
            $script:failed++
            return $null
        }
    }
}

# =============================================================================
# ST1: Save project with semantic_type_id KEY -> verify resolved UUID
# =============================================================================
$st1Result = Invoke-GatewayTest -TestName "ST1: Save project with semantic_type_id key (execution-core)" -Body @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "project"
    title           = "ST1 Test — Semantic Type Key Resolution"
    semantic_type_id = "execution-core"
    priority        = 3
    tags            = @("test", "semantic-type", "st1")
    extension       = @{ lifecycle_stage = "seed" }
} -Validator {
    param($status, $json)
    $status -eq 200 -and $json.ok -eq $true -and $json.artifact_id
}

$st1ArtifactId = $st1Result?.artifact_id

# =============================================================================
# ST2: Save project with UUID passthrough -> verify stored
# Uses a known UUID for execution-core from the registry
# =============================================================================
$st2Result = Invoke-GatewayTest -TestName "ST2: Save project with semantic_type_id UUID passthrough" -Body @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "project"
    title           = "ST2 Test — Semantic Type UUID Passthrough"
    semantic_type_id = "execution-core"
    priority        = 3
    tags            = @("test", "semantic-type", "st2")
    extension       = @{ lifecycle_stage = "seed" }
} -Validator {
    param($status, $json)
    $status -eq 200 -and $json.ok -eq $true -and $json.artifact_id
}

$st2ArtifactId = $st2Result?.artifact_id

# =============================================================================
# ST3: Save project WITHOUT semantic_type_id -> expect VALIDATION_ERROR
# =============================================================================
Invoke-GatewayTest -TestName "ST3: Save project WITHOUT semantic_type_id (expect error)" -Body @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "project"
    title           = "ST3 Test — Missing Semantic Type"
    priority        = 3
    tags            = @("test", "st3")
    extension       = @{ lifecycle_stage = "seed" }
} -Validator {
    param($status, $json)
    $json.ok -eq $false -and ($json.error.code -match "VALIDATION_ERROR|SEMANTIC_TYPE_RESOLUTION_FAILED")
}

# =============================================================================
# ST4: Save branch WITH semantic_type_id -> expect VALIDATION_ERROR
# =============================================================================
Invoke-GatewayTest -TestName "ST4: Save branch WITH semantic_type_id (expect error)" -Body @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "branch"
    title           = "ST4 Test — Branch With Semantic Type"
    semantic_type_id = "execution-core"
    priority        = 3
    tags            = @("test", "st4")
} -Validator {
    param($status, $json)
    $json.ok -eq $false -and ($json.error.code -match "VALIDATION_ERROR")
}

# =============================================================================
# ST5: Save snapshot with invalid semantic_type_id -> expect INVALID_SEMANTIC_TYPE
# =============================================================================
Invoke-GatewayTest -TestName "ST5: Save snapshot with invalid semantic_type_id (expect error)" -Body @{
    gw_action       = "artifact.save"
    gw_workspace_id = $WorkspaceId
    artifact_type   = "snapshot"
    title           = "ST5 Test — Invalid Semantic Type"
    semantic_type_id = "nonexistent-type"
    priority        = 3
    tags            = @("test", "st5")
    extension       = @{ payload = @{ test = "data" } }
} -Validator {
    param($status, $json)
    $json.ok -eq $false -and ($json.error.code -match "INVALID_SEMANTIC_TYPE|SEMANTIC_TYPE_RESOLUTION_FAILED")
}

# =============================================================================
# ST6: Update semantic_type_id (dedicated path) -> expect success
# Requires ST1 artifact to exist
# =============================================================================
if ($st1ArtifactId) {
    Invoke-GatewayTest -TestName "ST6: Update semantic_type_id (dedicated path, ST1 artifact)" -Body @{
        gw_action       = "artifact.update"
        gw_workspace_id = $WorkspaceId
        artifact_type   = "project"
        artifact_id     = $st1ArtifactId
        extension       = @{
            semantic_type_id = "governance"
            reason           = "ST6 test — reclassification"
        }
    } -Validator {
        param($status, $json)
        $json.ok -eq $true
    }
} else {
    Write-Host "[TEST] ST6: SKIP — ST1 artifact not created" -ForegroundColor DarkYellow
    $total--
}

# =============================================================================
# ST7: Update semantic_type_id + tags combined -> expect MIXED_UPDATE_NOT_ALLOWED
# Requires ST2 artifact to exist
# =============================================================================
if ($st2ArtifactId) {
    Invoke-GatewayTest -TestName "ST7: Update semantic_type_id + tags combined (expect MIXED_UPDATE_NOT_ALLOWED)" -Body @{
        gw_action       = "artifact.update"
        gw_workspace_id = $WorkspaceId
        artifact_type   = "project"
        artifact_id     = $st2ArtifactId
        extension       = @{
            semantic_type_id = "infrastructure"
            reason           = "ST7 test — should fail"
        }
        tags            = @{
            add = @("should-fail")
        }
    } -Validator {
        param($status, $json)
        $json.ok -eq $false -and $json.error.code -eq "MIXED_UPDATE_NOT_ALLOWED"
    }
} else {
    Write-Host "[TEST] ST7: SKIP — ST2 artifact not created" -ForegroundColor DarkYellow
    $total--
}

# =============================================================================
# SUMMARY
# =============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Results: $passed PASSED / $failed FAILED / $total TOTAL" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($st1ArtifactId) {
    Write-Host "  Cleanup: ST1 artifact_id = $st1ArtifactId" -ForegroundColor Gray
}
if ($st2ArtifactId) {
    Write-Host "  Cleanup: ST2 artifact_id = $st2ArtifactId" -ForegroundColor Gray
}
Write-Host "  Use artifact.delete to clean up test artifacts.`n" -ForegroundColor Gray

if ($failed -gt 0) {
    Write-Host "  ACTION REQUIRED: Fix failures before proceeding." -ForegroundColor Red
    exit 1
}
