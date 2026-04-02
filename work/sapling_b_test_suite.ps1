<#
.SYNOPSIS
    Sapling B -- Gateway Strict Mode: Test Suite
    Tests Save v50 changes (7 branches)
.DESCRIPTION
    Group 1: Reject Unknown Extension Keys (Branch 1)
    Group 2: Reject Unknown Top-Level Fields (Branch 2)
    Group 3: Reject Empty Required Objects (Branch 3)
    Group 4: Snapshot for-q Auto-Injection (Branch 5)
    Group 5: Execution Status Auto-Default (Branch 6)
    Group 6: Enforce Parent Requirement (Branch 7)
    Group 7: Twig Content Completeness (Branch 8)
    Group 8: Non-Regression
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
                $detail = "Expected error code '$ExpectCode', got '$($resp.error.code)' - $($resp.error.message)"
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
Write-Host "`n=== GROUP 1: Reject Unknown Extension Keys (Branch 1) ===" -ForegroundColor Cyan
# ============================================================================

# 1.1 -- Project with unknown extension key rejected
Test-Case -Name "1.1 Project unknown ext key -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Test unknown ext key"
    semantic_type_id = "governance"
    extension = @{ lifecycle_stage = "seed"; bogus_field = "should fail" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $extErr = $errs | Where-Object { $_.field -eq "extension" }
    if ($extErr -and $extErr.rejected_keys) {
        @{ passed = $true; detail = "rejected_keys: $($extErr.rejected_keys -join ', ')" }
    } else {
        @{ passed = $false; detail = "no extension key rejection in errors" }
    }
}

# 1.2 -- Project with valid-only extension keys passes
$resp = Test-Case -Name "1.2 Project valid ext keys -> ok" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Test valid ext keys"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "ok"
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "project" } }

# 1.3 -- Branch with ANY extension key rejected (spine-only)
Test-Case -Name "1.3 Branch ext key -> rejected (spine-only)" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    title = "Test branch ext key"
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
    extension = @{ execution_status = "not_started" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $extErr = $errs | Where-Object { $_.field -eq "extension" }
    if ($extErr -and $extErr.allowed_keys -eq "(none -- spine-only type)") {
        @{ passed = $true; detail = "spine-only type correctly rejected" }
    } elseif ($extErr) {
        @{ passed = $true; detail = "rejected: $($extErr.rejected_keys -join ', ')" }
    } else {
        @{ passed = $false; detail = "no extension rejection found" }
    }
}

# 1.4 -- Snapshot with unknown extension key rejected
Test-Case -Name "1.4 Snapshot unknown ext key -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    title = "Test snapshot bad ext"
    semantic_type_id = "governance"
    extension = @{ payload = @{ data = "valid" }; extra_field = "should fail" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# ============================================================================
Write-Host "`n=== GROUP 2: Reject Unknown Top-Level Fields (Branch 2) ===" -ForegroundColor Cyan
# ============================================================================

# 2.1 -- Unknown top-level field rejected
Test-Case -Name "2.1 Unknown top-level field -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Test unknown field"
    semantic_type_id = "governance"
    extension = @{ entry_text = "valid" }
    bogus_top_level = "should be caught"
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $topErr = $errs | Where-Object { $_.field -eq "_top_level" }
    if ($topErr -and $topErr.rejected_fields) {
        @{ passed = $true; detail = "rejected: $($topErr.rejected_fields -join ', ')" }
    } else {
        @{ passed = $false; detail = "no top-level field rejection in errors" }
    }
}

# 2.2 -- Valid payload with no unknown fields passes
$resp = Test-Case -Name "2.2 Clean payload -> ok" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Test clean payload"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ entry_text = "valid clean payload" }
} -ExpectResult "ok"
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "journal" } }

# ============================================================================
Write-Host "`n=== GROUP 3: Reject Empty Required Objects (Branch 3) ===" -ForegroundColor Cyan
# ============================================================================

# 3.1 -- Snapshot with empty payload object rejected
Test-Case -Name "3.1 Snapshot empty payload {} -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    title = "Test empty payload"
    semantic_type_id = "governance"
    extension = @{ payload = @{} }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $payErr = $errs | Where-Object { $_.field -eq "extension.payload" -and $_.reason -match "must not be empty" }
    if ($payErr) {
        @{ passed = $true; detail = "empty payload rejected" }
    } else {
        @{ passed = $false; detail = "empty payload not specifically caught" }
    }
}

# 3.2 -- Snapshot with non-empty payload passes
$resp = Test-Case -Name "3.2 Snapshot valid payload -> ok" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    title = "Test valid snapshot"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ payload = @{ data = "valid content" } }
} -ExpectResult "ok"
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "snapshot" } }

# ============================================================================
Write-Host "`n=== GROUP 4: Snapshot for-q Auto-Injection (Branch 5) ===" -ForegroundColor Cyan
# ============================================================================

# 4.1 -- Qualifying snapshot (governance) gets for-q injected
$resp = Test-Case -Name "4.1 Governance snapshot -> for-q auto-injected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    title = "Test for-q injection"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b")
    extension = @{ payload = @{ test = "for-q injection" } }
} -ExpectResult "ok"

if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "snapshot" }
    # Query to verify for-q tag
    $query = Invoke-GW -Body @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_type = "snapshot"
        artifact_id = $resp.artifact_id
    }
    $tags = $query.data.artifact.tags
    if ($tags -match "for-q") {
        Write-Host "    VERIFIED: for-q tag present in persisted tags"
        $global:testResults += [PSCustomObject]@{ Test = "4.1a for-q in DB"; Status = "PASS"; Detail = "for-q confirmed in persisted tags" }
    } else {
        Write-Host "    FAILED: for-q tag NOT in persisted tags: $tags"
        $global:testResults += [PSCustomObject]@{ Test = "4.1a for-q in DB"; Status = "FAIL"; Detail = "for-q missing from: $tags" }
    }
}

# 4.2 -- Non-qualifying snapshot (exploratory) does NOT get for-q
$resp = Test-Case -Name "4.2 Exploratory snapshot -> no for-q" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    title = "Test no for-q injection"
    semantic_type_id = "exploratory"
    tags = @("test", "sapling-b")
    extension = @{ payload = @{ test = "no for-q" } }
} -ExpectResult "ok"

if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "snapshot" }
    $query = Invoke-GW -Body @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_type = "snapshot"
        artifact_id = $resp.artifact_id
    }
    $tags = $query.data.artifact.tags
    if ($tags -match "for-q") {
        Write-Host "    FAILED: for-q should NOT be present for exploratory"
        $global:testResults += [PSCustomObject]@{ Test = "4.2a no for-q in DB"; Status = "FAIL"; Detail = "for-q incorrectly injected" }
    } else {
        Write-Host "    VERIFIED: for-q correctly absent"
        $global:testResults += [PSCustomObject]@{ Test = "4.2a no for-q in DB"; Status = "PASS"; Detail = "for-q correctly absent" }
    }
}

# 4.3 -- Snapshot with for-q already present -> no duplicate
$resp = Test-Case -Name "4.3 Snapshot with existing for-q -> no duplicate" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "snapshot"
    title = "Test dedup for-q"
    semantic_type_id = "governance"
    tags = @("test", "for-q", "sapling-b")
    extension = @{ payload = @{ test = "dedup" } }
} -ExpectResult "ok"

if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "snapshot" }
    $query = Invoke-GW -Body @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_type = "snapshot"
        artifact_id = $resp.artifact_id
    }
    $tagsStr = $query.data.artifact.tags
    $forQCount = ([regex]::Matches($tagsStr, "for-q")).Count
    if ($forQCount -eq 1) {
        Write-Host "    VERIFIED: exactly one for-q (no duplicate)"
        $global:testResults += [PSCustomObject]@{ Test = "4.3a dedup check"; Status = "PASS"; Detail = "for-q count = 1" }
    } else {
        Write-Host "    FAILED: for-q count = $forQCount"
        $global:testResults += [PSCustomObject]@{ Test = "4.3a dedup check"; Status = "FAIL"; Detail = "for-q count = $forQCount" }
    }
}

# ============================================================================
Write-Host "`n=== GROUP 5: Execution Status Auto-Default (Branch 6) ===" -ForegroundColor Cyan
# ============================================================================

# 5.1 -- Branch without execution_status gets not_started
$resp = Test-Case -Name "5.1 Branch save -> auto-default not_started" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    title = "Test exec status default"
    tags = @("test", "sapling-b", "disposable")
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
} -ExpectResult "ok"

if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "branch" }
    $query = Invoke-GW -Body @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_type = "branch"
        artifact_id = $resp.artifact_id
    }
    $execStatus = $query.data.artifact.execution_status
    if ($execStatus -eq "not_started") {
        Write-Host "    VERIFIED: execution_status = not_started"
        $global:testResults += [PSCustomObject]@{ Test = "5.1a exec status in DB"; Status = "PASS"; Detail = "execution_status = not_started" }
    } else {
        Write-Host "    FAILED: execution_status = $execStatus"
        $global:testResults += [PSCustomObject]@{ Test = "5.1a exec status in DB"; Status = "FAIL"; Detail = "execution_status = $execStatus" }
    }
}

# 5.2 -- Project without execution_status stays null (non-execution type)
$resp = Test-Case -Name "5.2 Project save -> no auto-default" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Test no exec default for project"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "ok"

if ($resp.ok -and $resp.artifact_id) {
    $global:createdArtifacts += @{ id = $resp.artifact_id; type = "project" }
    $query = Invoke-GW -Body @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_type = "project"
        artifact_id = $resp.artifact_id
    }
    $execStatus = $query.data.artifact.execution_status
    if ($null -eq $execStatus -or $execStatus -eq "") {
        Write-Host "    VERIFIED: execution_status = null (correct for project)"
        $global:testResults += [PSCustomObject]@{ Test = "5.2a no default for project"; Status = "PASS"; Detail = "execution_status = null" }
    } else {
        Write-Host "    FAILED: execution_status = $execStatus (should be null)"
        $global:testResults += [PSCustomObject]@{ Test = "5.2a no default for project"; Status = "FAIL"; Detail = "execution_status = $execStatus" }
    }
}

# ============================================================================
Write-Host "`n=== GROUP 6: Enforce Parent Requirement (Branch 7) ===" -ForegroundColor Cyan
# ============================================================================

# 6.1 -- Branch without parent rejected
Test-Case -Name "6.1 Branch no parent -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    title = "Test orphan branch"
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $parentErr = $errs | Where-Object { $_.field -eq "parent_artifact_id" }
    if ($parentErr) {
        @{ passed = $true; detail = "parent_artifact_id required error present" }
    } else {
        @{ passed = $false; detail = "no parent_artifact_id error found" }
    }
}

# 6.2 -- Leaf without parent rejected
Test-Case -Name "6.2 Leaf no parent -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "leaf"
    title = "Test orphan leaf"
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# 6.3 -- Twig without parent rejected
Test-Case -Name "6.3 Twig no parent -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    title = "Test orphan twig"
    content = @{ idea = "test"; why_now = "test"; problem_touched = "test"; future_hook = "test" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# 6.4 -- Project without parent still allowed
$resp = Test-Case -Name "6.4 Project no parent -> ok" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Test project no parent ok"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "ok"
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "project" } }

# ============================================================================
Write-Host "`n=== GROUP 7: Twig Content Completeness (Branch 8) ===" -ForegroundColor Cyan
# ============================================================================

# 7.1 -- Twig with no content rejected
Test-Case -Name "7.1 Twig no content -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    title = "Test title-only twig"
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $contentErr = $errs | Where-Object { $_.field -eq "content" }
    if ($contentErr) {
        @{ passed = $true; detail = "content required error: $($contentErr.reason)" }
    } else {
        @{ passed = $false; detail = "no content error found" }
    }
}

# 7.2 -- Twig with partial content rejected (missing keys)
Test-Case -Name "7.2 Twig partial content -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    title = "Test partial twig"
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
    content = @{ idea = "has idea"; why_now = "has why" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $contentErr = $errs | Where-Object { $_.field -eq "content" -and $_.missing_keys }
    if ($contentErr -and $contentErr.missing_keys -contains "problem_touched") {
        @{ passed = $true; detail = "missing: $($contentErr.missing_keys -join ', ')" }
    } else {
        @{ passed = $false; detail = "missing_keys not reported correctly" }
    }
}

# 7.3 -- Twig with complete content passes
$resp = Test-Case -Name "7.3 Twig complete content -> ok" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    title = "Test complete twig"
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
    tags = @("test", "sapling-b", "disposable")
    content = @{
        idea = "Test idea"
        why_now = "Testing completeness"
        problem_touched = "Content validation"
        future_hook = "Enforcement pattern"
    }
} -ExpectResult "ok"
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "twig" } }

# 7.4 -- Twig with empty string value rejected
Test-Case -Name "7.4 Twig empty string value -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    title = "Test empty string twig"
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
    content = @{ idea = "valid"; why_now = "valid"; problem_touched = ""; future_hook = "valid" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# ============================================================================
Write-Host "`n=== GROUP 8: Non-Regression ===" -ForegroundColor Cyan
# ============================================================================

# 8.1 -- Normal journal save still works
$resp = Test-Case -Name "8.1 Journal save -> ok (non-regression)" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Non-regression test"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ entry_text = "Sapling B non-regression" }
} -ExpectResult "ok" -Validate {
    param($r)
    if ($r.version -ge 1 -and $r._gw_route -eq "ok") {
        @{ passed = $true; detail = "version=$($r.version), shape correct" }
    } else {
        @{ passed = $false; detail = "version=$($r.version), _gw_route=$($r._gw_route)" }
    }
}
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "journal" } }

# 8.2 -- Normal project save still works
$resp = Test-Case -Name "8.2 Project save -> ok (non-regression)" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    title = "Non-regression project"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ lifecycle_stage = "seed" }
} -ExpectResult "ok"
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "project" } }

# 8.3 -- Sapling A response shape still intact
Test-Case -Name "8.3 Response shape preserved (Sapling A)" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "journal"
    title = "Shape check"
    semantic_type_id = "governance"
    tags = @("test", "sapling-b", "disposable")
    extension = @{ entry_text = "Shape validation" }
} -ExpectResult "ok" -Validate {
    param($r)
    $checks = @()
    if ($r._gw_route -ne "ok") { $checks += "_gw_route missing" }
    if ($null -eq $r.version -or $r.version -lt 1) { $checks += "version missing or < 1" }
    if (-not $r.workspace_id) { $checks += "workspace_id missing" }
    if (-not $r.timestamp) { $checks += "timestamp missing" }
    $json = $r | ConvertTo-Json -Depth 5
    if ($json -match "_owner_source") { $checks += "_owner_source still present" }
    if ($json -match "_debug_warnings") { $checks += "_debug_warnings still present" }
    if ($checks.Count -eq 0) { @{ passed = $true; detail = "Sapling A shape intact" } }
    else { @{ passed = $false; detail = ($checks -join "; ") } }
}
if ($resp.ok -and $resp.artifact_id) { $global:createdArtifacts += @{ id = $resp.artifact_id; type = "journal" } }

# ============================================================================
Write-Host "`n=== GROUP 9: Edge Cases ===" -ForegroundColor Cyan
# ============================================================================

# 9.1 -- Multi-failure: unknown top-level + unknown extension + missing parent
Test-Case -Name "9.1 Multi-failure accumulation" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    title = "Multi-fail test"
    bogus_top = "unknown"
    extension = @{ bad_key = "unknown" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $fields = $errs | ForEach-Object { $_.field }
    $hasParent = $fields -contains "parent_artifact_id"
    $hasExt = $fields -contains "extension"
    $hasTop = $fields -contains "_top_level"
    $count = $errs.Count
    if ($hasParent -and $hasExt -and $hasTop) {
        @{ passed = $true; detail = "$count errors: parent + extension + top-level" }
    } else {
        @{ passed = $false; detail = "missing errors. fields: $($fields -join ', ')" }
    }
}

# 9.2 -- Twig whitespace-only value rejected
Test-Case -Name "9.2 Twig whitespace value -> rejected" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "twig"
    title = "Whitespace twig"
    parent_artifact_id = "fb5bccd0-1e64-4407-95d8-989b7e08aa17"
    content = @{ idea = "valid"; why_now = "valid"; problem_touched = "   "; future_hook = "valid" }
} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR" -Validate {
    param($r)
    $errs = $r.error.details.validation_errors
    $contentErr = $errs | Where-Object { $_.field -eq "content" -and $_.missing_keys }
    if ($contentErr -and $contentErr.missing_keys -contains "problem_touched") {
        @{ passed = $true; detail = "whitespace caught: problem_touched" }
    } else {
        @{ passed = $false; detail = "whitespace not caught" }
    }
}

# 9.3 -- Error contract structure validation
Test-Case -Name "9.3 Error contract structure" -Payload @{
    gw_action = "artifact.save"
    gw_workspace_id = $workspaceId
    artifact_type = "branch"
    title = "Error structure test"
} -ExpectResult "error" -Validate {
    param($r)
    $checks = @()
    if (-not $r.error) { $checks += "error object missing" }
    if (-not $r.error.code) { $checks += "error.code missing" }
    if (-not $r.error.message) { $checks += "error.message missing" }
    if (-not $r.error.details) { $checks += "error.details missing" }
    if (-not $r.error.details.validation_errors) { $checks += "validation_errors array missing" }
    if ($r.error.details.validation_errors -isnot [System.Array] -and $r.error.details.validation_errors -isnot [System.Object[]]) {
        $checks += "validation_errors not an array"
    }
    if ($checks.Count -eq 0) { @{ passed = $true; detail = "error contract intact" } }
    else { @{ passed = $false; detail = ($checks -join "; ") } }
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

if ($global:createdArtifacts.Count -gt 0) {
    Write-Host "`n--- Test Artifacts Created (cleanup needed) ---"
    $global:createdArtifacts | ForEach-Object { Write-Host "  $($_.type): $($_.id)" }
}
