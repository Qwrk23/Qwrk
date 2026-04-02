<#
.SYNOPSIS
    Sapling A -- Response & Error Integrity: Test Suite
    Tests Save v48 + Update T140 v2 changes
.DESCRIPTION
    Group 1: Save Response Shape (Branch 2)
    Group 2: Error Surfacing (Branch 1)
    Group 3: Extension Not Mutable (Branch 3)
    Group 4: Non-Regression
    Group 5: No-Op Update + Downstream Failure
#>

$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$cred = "qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($cred))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type"  = "application/json"
}

$global:testResults = @()
$global:createdArtifacts = @()

function Invoke-GW {
    param([hashtable]$Body)
    $json = $Body | ConvertTo-Json -Depth 10
    try {
        $resp = Invoke-RestMethod -Uri $gatewayUrl -Method POST -Body $json -ContentType "application/json" -Headers $headers
        return $resp
    } catch {
        return @{ ok = $false; error = @{ code = "HTTP_ERROR"; message = $_.Exception.Message } }
    }
}

function Test-Case {
    param(
        [string]$Name,
        [hashtable]$Payload,
        [string]$ExpectResult,
        [string]$ExpectCode,
        [scriptblock]$Validate
    )
    $resp = Invoke-GW -Body $Payload
    $passed = $false
    $detail = ""

    if ($ExpectResult -eq "ok") {
        if ($resp.ok -eq $true) {
            if ($Validate) {
                try {
                    $result = & $Validate $resp
                    $passed = $result.passed
                    $detail = $result.detail
                } catch { $detail = "Validate error: $_" }
            } else { $passed = $true }
        } else {
            $detail = "Expected ok:true, got ok:$($resp.ok). Error: $($resp.error.code) - $($resp.error.message)"
        }
    } elseif ($ExpectResult -eq "error") {
        if ($resp.ok -eq $false) {
            if ($ExpectCode -and $resp.error.code -ne $ExpectCode) {
                $detail = "Expected error code '$ExpectCode', got '$($resp.error.code)'"
            } elseif ($Validate) {
                try {
                    $result = & $Validate $resp
                    $passed = $result.passed
                    $detail = $result.detail
                } catch { $detail = "Validate error: $_" }
            } else { $passed = $true }
        } else {
            $detail = "Expected ok:false, got ok:$($resp.ok)"
        }
    }

    $status = if ($passed) { "PASS" } else { "FAIL" }
    $global:testResults += [PSCustomObject]@{ Test = $Name; Status = $status; Detail = $detail }
    Write-Host "  [$status] $Name$(if ($detail) { " -- $detail" })"
    return $resp
}

# ============================================================================
Write-Host "`n=== GROUP 1: Save Response Shape (Branch 2) ===" -ForegroundColor Cyan
# ============================================================================

# 1.1 -- Success response shape
$resp = Test-Case -Name "1.1 Save success shape -- all required fields" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Sapling A Test -- Response Shape"
    semantic_type_id = "governance"
    tags = @("test", "sapling-a", "disposable")
    extension = @{ entry_text = "Testing Save v48 response shape" }
} -ExpectResult "ok" -Validate {
    param($r)
    $checks = @()
    if ($null -eq $r.ok) { $checks += "ok missing" }
    if ($r._gw_route -ne "ok") { $checks += "_gw_route should be 'ok', got '$($r._gw_route)'" }
    if (-not $r.artifact_id) { $checks += "artifact_id missing" }
    if (-not $r.workspace_id) { $checks += "workspace_id missing" }
    if ($null -eq $r.version) { $checks += "version missing" }
    if ($r.version -lt 1) { $checks += "version should be >= 1, got $($r.version)" }
    if (-not $r.timestamp) { $checks += "timestamp missing" }
    if ($r.operation -ne "INSERT") { $checks += "operation should be INSERT" }
    # Removed fields
    $json = $r | ConvertTo-Json -Depth 5
    if ($json -match "_debug_warnings") { $checks += "_debug_warnings should be removed" }
    if ($json -match "_owner_source") { $checks += "_owner_source should be removed" }

    if ($checks.Count -eq 0) {
        @{ passed = $true; detail = "version=$($r.version), _gw_route=$($r._gw_route)" }
    } else {
        @{ passed = $false; detail = ($checks -join "; ") }
    }
}

if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "journal" }
    $testJournalId = $resp.artifact_id
    $testJournalVersion = $resp.version
}

# 1.2 -- Error response shape
Test-Case -Name "1.2 Save error shape -- missing title" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    semantic_type_id = "governance"
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $checks = @()
    if ($r._gw_route -ne "error") { $checks += "_gw_route should be 'error', got '$($r._gw_route)'" }
    # version must be PRESENT as a key (null value is expected and valid on error path)
    if (-not ($r.PSObject.Properties.Name -contains "version")) { $checks += "version key missing from response" }
    if (-not $r.workspace_id) { $checks += "workspace_id missing (should be standardized)" }
    if (-not $r.error.code) { $checks += "error.code missing" }
    if (-not $r.error.message) { $checks += "error.message missing" }
    if (-not $r.timestamp) { $checks += "timestamp missing" }
    if ($checks.Count -eq 0) { @{ passed = $true; detail = "error shape correct" } }
    else { @{ passed = $false; detail = ($checks -join "; ") } }
}

# 1.3 -- Forbidden: ok:true must not have error object
Test-Case -Name "1.3 Forbidden state -- ok:true has no error object" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Sapling A Test -- Forbidden State Check"
    semantic_type_id = "governance"
    tags = @("test", "sapling-a", "disposable")
    extension = @{ entry_text = "Checking ok:true has no error" }
} -ExpectResult "ok" -Validate {
    param($r)
    if ($r.ok -and $r.PSObject.Properties.Name -contains "error" -and $null -ne $r.error) {
        @{ passed = $false; detail = "FORBIDDEN: ok:true with error object present" }
    } else {
        @{ passed = $true; detail = "no error object on success" }
    }
}
if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "journal" }
}

# ============================================================================
Write-Host "`n=== GROUP 2: Error Surfacing (Branch 1) ===" -ForegroundColor Cyan
# ============================================================================

# 2.1 -- Semantic type error propagates
Test-Case -Name "2.1 Semantic type error propagation" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Test invalid semantic type"
    semantic_type_id = "nonexistent_type"
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "error" -ExpectCode "INVALID_SEMANTIC_TYPE"

# 2.2 -- Type validation: video is non-top-level, so semantic_type_id triggers
# VALIDATION_ERROR before Type_Registry_Guard is reached.
# (semantic_type_id is forbidden for non-top-level types)
Test-Case -Name "2.2 Non-top-level type with semantic_type_id -> VALIDATION_ERROR" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "video"
    title = "Test disabled type"
    semantic_type_id = "governance"
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# 2.3 -- Journal extension validation propagates
Test-Case -Name "2.3 Journal extension error propagation" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Test journal bad extension"
    semantic_type_id = "governance"
    extension = @{ entry_text = "valid"; unknown_field = "should fail" }
} -ExpectResult "error" -ExpectCode "JOURNAL_EXTENSION_INVALID"

# ============================================================================
Write-Host "`n=== GROUP 3: Extension Not Mutable (Branch 3) ===" -ForegroundColor Cyan
# ============================================================================

# Need real artifact IDs for update tests -- use existing Sapling A branches
$testBranchId = "1ed8973a-d841-4239-9764-453fac3cf26b"  # Deterministic Error Surfacing branch
$testLeafId = $null  # Will use a leaf we created
$testProjectId = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"  # Seed project

# First, find a twig to test against
$twigResp = Invoke-GW -Body @{
    gw_action = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    selector = @{ limit = 1 }
}
$testTwigId = if ($twigResp.data -and $twigResp.data.Count -gt 0) { $twigResp.data[0].artifact_id } else { $null }

# Find a leaf
$leafResp = Invoke-GW -Body @{
    gw_action = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type = "leaf"
    selector = @{ limit = 1 }
}
$testLeafId = if ($leafResp.data -and $leafResp.data.Count -gt 0) { $leafResp.data[0].artifact_id } else { $null }

# 3.1 -- Branch extension update rejected
# Check_Mutability_Rules (rule 6.7) catches non-execution_status extension keys
# on branch/limb/leaf/twig BEFORE Switch_Type_For_Update is reached.
# Valid test: send unknown key -> VALIDATION_ERROR (disallowed fields).
# EXTENSION_NOT_MUTABLE is a deeper backstop for edge cases.
Test-Case -Name "3.1 Branch extension with non-spine key -> rejected" -Payload @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    artifact_id = $testBranchId
    extension = @{ foo = "bar" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $checks = @()
    if ($r.error.details.artifact_type -ne "branch") { $checks += "artifact_type missing from details" }
    if (-not $r.error.details.disallowed_fields) { $checks += "disallowed_fields missing from details" }
    if ($r.error.details.allowed_fields -notcontains "execution_status") { $checks += "allowed_fields should list execution_status" }
    if ($checks.Count -eq 0) {
        @{ passed = $true; detail = "rejected with disallowed_fields, allowed=[execution_status]" }
    } else {
        @{ passed = $false; detail = ($checks -join "; ") }
    }
}

# 3.2 -- Leaf extension update rejected
if ($testLeafId) {
    Test-Case -Name "3.2 Leaf extension update -> EXTENSION_NOT_MUTABLE" -Payload @{
        gw_action = "artifact.update"
        gw_workspace_id = $workspaceId
        artifact_type = "leaf"
        artifact_id = $testLeafId
        extension = @{ foo = "bar" }
    } -ExpectResult "error" -ExpectCode "EXTENSION_NOT_MUTABLE"
} else {
    Write-Host "  [SKIP] 3.2 -- no leaf artifact found"
    $global:testResults += [PSCustomObject]@{ Test = "3.2 Leaf ext update"; Status = "SKIP"; Detail = "no leaf" }
}

# 3.3 -- TWIG extension update rejected (CRITICAL -- new routing)
if ($testTwigId) {
    Test-Case -Name "3.3 Twig extension update -> EXTENSION_NOT_MUTABLE (NEW)" -Payload @{
        gw_action = "artifact.update"
        gw_workspace_id = $workspaceId
        artifact_type = "twig"
        artifact_id = $testTwigId
        extension = @{ foo = "bar" }
    } -ExpectResult "error" -ExpectCode "EXTENSION_NOT_MUTABLE" -Validate {
        param($r)
        if ($r.error.details.artifact_type -eq "twig") {
            @{ passed = $true; detail = "twig correctly rejected with EXTENSION_NOT_MUTABLE" }
        } else {
            @{ passed = $false; detail = "artifact_type missing or wrong in error.details" }
        }
    }
} else {
    Write-Host "  [SKIP] 3.3 -- no twig artifact found"
    $global:testResults += [PSCustomObject]@{ Test = "3.3 Twig ext update"; Status = "SKIP"; Detail = "no twig" }
}

# 3.4 -- Project extension update still works
Test-Case -Name "3.4 Project extension update -> still succeeds" -Payload @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    artifact_id = $testProjectId
    extension = @{ operational_state = "active" }
} -ExpectResult "ok"

# ============================================================================
Write-Host "`n=== GROUP 4: Non-Regression ===" -ForegroundColor Cyan
# ============================================================================

# 4.1 -- Tag update still works
Test-Case -Name "4.1 Tag update -> ok" -Payload @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    artifact_id = $testBranchId
    tags = @{ add = @("sapling-a-test") }
} -ExpectResult "ok"

# Clean up test tag
Invoke-GW -Body @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    artifact_id = $testBranchId
    tags = @{ remove = @("sapling-a-test") }
} | Out-Null

# 4.2 -- Spine update still works
Test-Case -Name "4.2 Spine summary update -> ok" -Payload @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    artifact_id = $testProjectId
    summary = "Migrate mechanical behavioral rules from Q instruction compliance into deterministic enforcement at the Gateway and workflow layer to reduce drift, eliminate silent failure modes, and strengthen system reliability."
} -ExpectResult "ok"

# 4.3 -- Immutability still enforced
$snapshotResp = Invoke-GW -Body @{
    gw_action = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    selector = @{ limit = 1 }
}
$testSnapshotId = if ($snapshotResp.data -and $snapshotResp.data.Count -gt 0) { $snapshotResp.data[0].artifact_id } else { $null }

if ($testSnapshotId) {
    Test-Case -Name "4.3 Snapshot immutability enforced" -Payload @{
        gw_action = "artifact.update"
        gw_workspace_id = $workspaceId
        artifact_type = "snapshot"
        artifact_id = $testSnapshotId
        extension = @{ payload = @{ test = "should fail" } }
    } -ExpectResult "error"
} else {
    Write-Host "  [SKIP] 4.3 -- no snapshot found"
}

# ============================================================================
Write-Host "`n=== GROUP 5: No-Op + Downstream Failure ===" -ForegroundColor Cyan
# ============================================================================

# 5.1 -- No-op update: same execution_status twice
Test-Case -Name "5.1a First update -> not_started" -Payload @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    artifact_id = $testBranchId
    execution_status = "not_started"
} -ExpectResult "ok" -Validate {
    param($r)
    # First call may be NOOP or SPINE_FIELD_UPDATE depending on current state
    @{ passed = $true; detail = "operation=$($r.operation)" }
}

$noop = Test-Case -Name "5.1b Repeat same update -> NOOP (no silent mutation)" -Payload @{
    gw_action = "artifact.update"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    artifact_id = $testBranchId
    execution_status = "not_started"
} -ExpectResult "ok" -Validate {
    param($r)
    if ($r.operation -eq "NOOP") {
        @{ passed = $true; detail = "Correctly returned NOOP -- no silent mutation" }
    } else {
        @{ passed = $false; detail = "Expected NOOP, got operation=$($r.operation) -- may have silently mutated" }
    }
}

# 5.2 -- Version increments on actual mutation
# Save a test project, note version, update it, verify version incremented
$projSave = Invoke-GW -Body @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Sapling A Test -- Version Increment"
    semantic_type_id = "governance"
    tags = @("test", "sapling-a", "disposable")
    extension = @{ lifecycle_stage = "seed" }
}
if ($projSave.ok) {
    $global:createdArtifacts += @{ id = $projSave.artifact_id; type = "project" }
    $v1 = $projSave.version

    # Update summary to trigger mutation
    $projUpdate = Invoke-GW -Body @{
        gw_action = "artifact.update"
        gw_workspace_id = $workspaceId
        artifact_type = "project"
        artifact_id = $projSave.artifact_id
        summary = "Version increment test"
    }

    # Query to get actual version
    $projQuery = Invoke-GW -Body @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_type = "project"
        artifact_id = $projSave.artifact_id
    }
    $v2 = if ($projQuery.data.artifact) { $projQuery.data.artifact.version } else { $null }

    $passed = ($v2 -and $v1 -and ($v2 -gt $v1))
    $detail = "save_version=$v1, post_update_version=$v2"
    $status = if ($passed) { "PASS" } else { "FAIL" }
    $global:testResults += [PSCustomObject]@{ Test = "5.2 Version increments on mutation"; Status = $status; Detail = $detail }
    Write-Host "  [$status] 5.2 Version increments on mutation -- $detail"
} else {
    Write-Host "  [SKIP] 5.2 -- save failed: $($projSave.error.message)"
    $global:testResults += [PSCustomObject]@{ Test = "5.2 Version increment"; Status = "SKIP"; Detail = "save failed" }
}

# 5.3 -- Downstream failure: DB-level error (save with invalid FK)
Test-Case -Name "5.3 Downstream DB error -> correct error envelope" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Test DB failure envelope"
    semantic_type_id = "governance"
    parent_artifact_id = "00000000-0000-0000-0000-000000000000"
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "error" -Validate {
    param($r)
    $checks = @()
    if (-not $r.error) { $checks += "error object missing" }
    if (-not $r.error.code) { $checks += "error.code missing" }
    if (-not $r.error.message) { $checks += "error.message missing" }
    if ($r._gw_route -ne "error") { $checks += "_gw_route not 'error'" }
    if ($null -eq $r.timestamp) { $checks += "timestamp missing" }
    # Must not leak raw DB details at top level
    $json = $r | ConvertTo-Json -Depth 5
    if ($json -match "INSERT INTO") { $checks += "LEAKED: raw SQL in response" }
    if ($checks.Count -eq 0) {
        @{ passed = $true; detail = "error.code=$($r.error.code), envelope intact" }
    } else {
        @{ passed = $false; detail = ($checks -join "; ") }
    }
}

# ============================================================================
# RESULTS
# ============================================================================

Write-Host "`n=== RESULTS ===" -ForegroundColor Yellow
$pass = ($global:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$fail = ($global:testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$skip = ($global:testResults | Where-Object { $_.Status -eq "SKIP" }).Count
Write-Host "  PASS: $pass  FAIL: $fail  SKIP: $skip" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })

Write-Host "`n--- Full Results ---"
$global:testResults | Format-Table -AutoSize

# Cleanup list
if ($global:createdArtifacts.Count -gt 0) {
    Write-Host "`n--- Test Artifacts Created (cleanup needed) ---"
    $global:createdArtifacts | ForEach-Object { Write-Host "  $($_.type): $($_.id)" }
}
