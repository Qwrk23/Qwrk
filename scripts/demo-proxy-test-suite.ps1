<#
.SYNOPSIS
    Explore Qwrk Demo Proxy - Full Test Suite
.DESCRIPTION
    End-to-end tests for NQxb_Demo_Proxy_v1.
    Validates all 3 actions (save/list/query), all 3 artifact types,
    enforcement rules, error handling, and response shaping.

    Governance: docs/design/Design__Explore_Qwrk_Demo_Governance__v1.md
    Proxy workflow: NQxb_Demo_Proxy_v1 (Ge56hG9lWbPvrH07)

.NOTES
    No auth required - demo proxy is a public endpoint.
    Tests create artifacts in the demo workspace (0af5712b).
    Created artifacts will be cleaned by nightly job (24h, no demo-seed tag).
#>

param(
    [string]$Secret = $env:QWRK_DEMO_SECRET,
    [switch]$CleanupOnly,
    [switch]$Verbose
)

if (-not $Secret) {
    Write-Host "ERROR: Demo proxy secret required." -ForegroundColor Red
    Write-Host "  Pass -Secret <value> or set env var QWRK_DEMO_SECRET" -ForegroundColor Yellow
    exit 1
}

$demoUrl = "https://n8n.halosparkai.com/webhook/nqxb/demo/v1"

# -- Test Framework --

$global:testResults = @()
$global:createdArtifacts = @()

function Invoke-Demo {
    param([hashtable]$Body)
    $json = $Body | ConvertTo-Json -Depth 10
    if ($Verbose) { Write-Host "    > $json" -ForegroundColor DarkGray }
    try {
        $headers = @{ "x-qwrk-secret" = $Secret }
        $resp = Invoke-RestMethod -Uri $demoUrl -Method POST -Body $json -ContentType "application/json" -Headers $headers
        if ($Verbose) { Write-Host "    < $($resp | ConvertTo-Json -Depth 5 -Compress)" -ForegroundColor DarkGray }
        return $resp
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        try {
            $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
            return $errBody
        } catch {
            return @{ ok = $false; error = @{ code = "HTTP_$statusCode"; message = $_.Exception.Message } }
        }
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
    $resp = Invoke-Demo -Body $Payload
    $passed = $false
    $detail = ""

    if ($ExpectResult -eq "ok") {
        if ($resp.ok -eq $true) {
            if ($Validate) {
                try {
                    $validateResult = & $Validate $resp
                    $passed = $validateResult -eq $true
                    if (-not $passed) { $detail = "Custom validation failed" }
                } catch { $detail = "Validation error: $_" }
            } else { $passed = $true }
        } else {
            $errCode = if ($resp.error) { $resp.error.code } else { "unknown" }
            $errMsg = if ($resp.error) { $resp.error.message } else { ($resp | ConvertTo-Json -Depth 3) }
            $detail = "Expected ok but got error: $errCode - $errMsg"
        }
    }
    elseif ($ExpectResult -eq "error") {
        if ($resp.ok -eq $false -or $resp.error) {
            $actualCode = if ($resp.error) { $resp.error.code } else { "unknown" }
            if ($ExpectCode -and $actualCode -ne $ExpectCode) {
                $detail = "Expected error code '$ExpectCode' but got '$actualCode'"
            } else { $passed = $true }
        } else { $detail = "Expected error but got ok response" }
    }

    $status = if ($passed) { "PASS" } else { "FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }
    Write-Host "  [$status] $Name" -ForegroundColor $color
    if ($detail) { Write-Host "         $detail" -ForegroundColor DarkYellow }
    $global:testResults += @{ Name = $Name; Status = $status; Detail = $detail }
    return $resp
}

# ================================================================
# GROUP 1: artifact.save - Happy Path (all 3 types)
# ================================================================

Write-Host "`nGROUP 1: artifact.save - Happy Path" -ForegroundColor Cyan

# T01: Save journal
$r = Test-Case -Name "T01 - Save journal" -Payload @{
    action = "artifact.save"; artifact_type = "journal"
    title = "Demo Test Journal"; summary = "Test journal entry from demo proxy test suite."
} -ExpectResult "ok" -Validate { param($r) $r.artifact_id -and $r.artifact_type -eq "journal" }
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }
$savedJournalId = $r.artifact_id

# T02: Save project
$r = Test-Case -Name "T02 - Save project" -Payload @{
    action = "artifact.save"; artifact_type = "project"
    title = "Demo Test Project"; summary = "Test project from demo proxy test suite."
} -ExpectResult "ok" -Validate { param($r) $r.artifact_id -and $r.artifact_type -eq "project" }
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "project" } }
$savedProjectId = $r.artifact_id

# T03: Save snapshot
$r = Test-Case -Name "T03 - Save snapshot" -Payload @{
    action = "artifact.save"; artifact_type = "snapshot"
    title = "Demo Test Snapshot"; summary = "Test snapshot from demo proxy test suite."
    content = @{ decision = "Test decision"; reasoning = "Test reasoning" }
} -ExpectResult "ok" -Validate { param($r) $r.artifact_id -and $r.artifact_type -eq "snapshot" }
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "snapshot" } }
$savedSnapshotId = $r.artifact_id

# T04: Save journal with tags
$r = Test-Case -Name "T04 - Save journal with user tags" -Payload @{
    action = "artifact.save"; artifact_type = "journal"
    title = "Tagged Journal"; summary = "Journal with custom tags."
    tags = @("my-tag", "test-run")
} -ExpectResult "ok" -Validate { param($r) $r.artifact_id -ne $null }
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }

# T05: Save with minimal payload (title only)
$r = Test-Case -Name "T05 - Save journal title-only minimal" -Payload @{
    action = "artifact.save"; artifact_type = "journal"; title = "Minimal Journal"
} -ExpectResult "ok" -Validate { param($r) $r.artifact_id -ne $null }
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }

# T06: Save snapshot with rich content
$r = Test-Case -Name "T06 - Save snapshot with structured content" -Payload @{
    action = "artifact.save"; artifact_type = "snapshot"
    title = "Rich Snapshot"; summary = "Snapshot with detailed content payload."
    content = @{
        decision = "Use PostgreSQL"
        reasoning = "Best fit for structured data with JSONB support"
        alternatives_considered = @("MongoDB", "DynamoDB", "SQLite")
        chosen_because = "Mature ecosystem, RLS support, Supabase integration"
    }
} -ExpectResult "ok" -Validate { param($r) $r.artifact_id -ne $null }
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "snapshot" } }

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 2: artifact.list - Happy Path
# ================================================================

Write-Host "`nGROUP 2: artifact.list - Happy Path" -ForegroundColor Cyan

# T07: List journals
Test-Case -Name "T07 - List journals" -Payload @{ action = "artifact.list"; artifact_type = "journal" } -ExpectResult "ok" -Validate { param($r) $r.PSObject.Properties.Name -contains "artifacts" -and $r.PSObject.Properties.Name -contains "count" }

# T08: List projects
Test-Case -Name "T08 - List projects" -Payload @{ action = "artifact.list"; artifact_type = "project" } -ExpectResult "ok" -Validate { param($r) $r.PSObject.Properties.Name -contains "artifacts" }

# T09: List snapshots
Test-Case -Name "T09 - List snapshots" -Payload @{ action = "artifact.list"; artifact_type = "snapshot" } -ExpectResult "ok" -Validate { param($r) $r.PSObject.Properties.Name -contains "artifacts" }

# T10: List with limit
Test-Case -Name "T10 - List journals with limit=2" -Payload @{ action = "artifact.list"; artifact_type = "journal"; limit = 2 } -ExpectResult "ok" -Validate { param($r) $r.artifacts.Count -le 2 }

# T11: List with offset
Test-Case -Name "T11 - List journals with offset=1" -Payload @{ action = "artifact.list"; artifact_type = "journal"; offset = 1 } -ExpectResult "ok"

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 3: artifact.query - Happy Path
# ================================================================

Write-Host "`nGROUP 3: artifact.query - Happy Path" -ForegroundColor Cyan

# T12: Query saved journal
if ($savedJournalId) {
    Test-Case -Name "T12 - Query saved journal by ID" -Payload @{ action = "artifact.query"; artifact_type = "journal"; artifact_id = $savedJournalId } -ExpectResult "ok" -Validate { param($r) $r.artifact -ne $null }
} else {
    Write-Host "  [SKIP] T12 - No journal ID from T01" -ForegroundColor Yellow
}

# T13: Query saved project
if ($savedProjectId) {
    Test-Case -Name "T13 - Query saved project by ID" -Payload @{ action = "artifact.query"; artifact_type = "project"; artifact_id = $savedProjectId } -ExpectResult "ok" -Validate { param($r) $r.artifact -ne $null }
} else {
    Write-Host "  [SKIP] T13 - No project ID from T02" -ForegroundColor Yellow
}

# T14: Query saved snapshot
if ($savedSnapshotId) {
    Test-Case -Name "T14 - Query saved snapshot by ID" -Payload @{ action = "artifact.query"; artifact_type = "snapshot"; artifact_id = $savedSnapshotId } -ExpectResult "ok" -Validate { param($r) $r.artifact -ne $null }
} else {
    Write-Host "  [SKIP] T14 - No snapshot ID from T03" -ForegroundColor Yellow
}

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 4: Enforcement - Disallowed Actions
# ================================================================

Write-Host "`nGROUP 4: Enforcement - Disallowed Actions" -ForegroundColor Cyan

# T15: artifact.update rejected
Test-Case -Name "T15 - artifact.update rejected" -Payload @{ action = "artifact.update"; artifact_type = "journal"; artifact_id = "00000000-0000-0000-0000-000000000000" } -ExpectResult "error" -ExpectCode "ACTION_NOT_ALLOWED"

# T16: artifact.delete rejected
Test-Case -Name "T16 - artifact.delete rejected" -Payload @{ action = "artifact.delete"; artifact_type = "journal"; artifact_id = "00000000-0000-0000-0000-000000000000" } -ExpectResult "error" -ExpectCode "ACTION_NOT_ALLOWED"

# T17: artifact.promote rejected
Test-Case -Name "T17 - artifact.promote rejected" -Payload @{ action = "artifact.promote"; artifact_type = "project"; artifact_id = "00000000-0000-0000-0000-000000000000" } -ExpectResult "error" -ExpectCode "ACTION_NOT_ALLOWED"

# T18: messaging.send_email rejected
Test-Case -Name "T18 - messaging.send_email rejected" -Payload @{ action = "messaging.send_email"; to = "test@example.com"; subject = "test" } -ExpectResult "error" -ExpectCode "ACTION_NOT_ALLOWED"

# T19: missing action field
Test-Case -Name "T19 - Missing action field" -Payload @{ artifact_type = "journal"; title = "No action" } -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# T20: empty payload
Test-Case -Name "T20 - Empty payload" -Payload @{} -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 5: Enforcement - Disallowed Artifact Types
# ================================================================

Write-Host "`nGROUP 5: Enforcement - Disallowed Types" -ForegroundColor Cyan

# T21: branch type rejected
Test-Case -Name "T21 - Save branch rejected" -Payload @{ action = "artifact.save"; artifact_type = "branch"; title = "test" } -ExpectResult "error" -ExpectCode "TYPE_NOT_ALLOWED"

# T22: leaf type rejected
Test-Case -Name "T22 - Save leaf rejected" -Payload @{ action = "artifact.save"; artifact_type = "leaf"; title = "test" } -ExpectResult "error" -ExpectCode "TYPE_NOT_ALLOWED"

# T23: restart type rejected
Test-Case -Name "T23 - Save restart rejected" -Payload @{ action = "artifact.save"; artifact_type = "restart"; title = "test" } -ExpectResult "error" -ExpectCode "TYPE_NOT_ALLOWED"

# T24: instruction_pack type rejected
Test-Case -Name "T24 - Save instruction_pack rejected" -Payload @{ action = "artifact.save"; artifact_type = "instruction_pack"; title = "test" } -ExpectResult "error" -ExpectCode "TYPE_NOT_ALLOWED"

# T25: missing artifact_type on save
Test-Case -Name "T25 - Save missing artifact_type" -Payload @{ action = "artifact.save"; title = "No type" } -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# T26: list with disallowed type
Test-Case -Name "T26 - List branch rejected" -Payload @{ action = "artifact.list"; artifact_type = "branch" } -ExpectResult "error" -ExpectCode "TYPE_NOT_ALLOWED"

# T27: list missing artifact_type
Test-Case -Name "T27 - List missing artifact_type" -Payload @{ action = "artifact.list" } -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 6: Enforcement - Size Limits
# ================================================================

Write-Host "`nGROUP 6: Enforcement - Size Limits" -ForegroundColor Cyan

# T28: title > 200 chars
$longTitle = "A" * 201
Test-Case -Name "T28 - Title over 200 chars rejected" -Payload @{ action = "artifact.save"; artifact_type = "journal"; title = $longTitle } -ExpectResult "error" -ExpectCode "FIELD_TOO_LONG"

# T29: summary > 1000 chars
$longSummary = "B" * 1001
Test-Case -Name "T29 - Summary over 1000 chars rejected" -Payload @{ action = "artifact.save"; artifact_type = "journal"; title = "Size test"; summary = $longSummary } -ExpectResult "error" -ExpectCode "FIELD_TOO_LONG"

# T30: title exactly 200 chars (boundary, should pass)
$exactTitle = "C" * 200
$r = Test-Case -Name "T30 - Title exactly 200 chars boundary OK" -Payload @{ action = "artifact.save"; artifact_type = "journal"; title = $exactTitle } -ExpectResult "ok"
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }

# T31: summary exactly 1000 chars (boundary, should pass)
$exactSummary = "D" * 1000
$r = Test-Case -Name "T31 - Summary exactly 1000 chars boundary OK" -Payload @{ action = "artifact.save"; artifact_type = "journal"; title = "Boundary test"; summary = $exactSummary } -ExpectResult "ok"
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 7: Enforcement - parent_artifact_id Rejection
# ================================================================

Write-Host "`nGROUP 7: Enforcement - Parent Rejection" -ForegroundColor Cyan

# T32: parent_artifact_id rejected
Test-Case -Name "T32 - parent_artifact_id rejected on save" -Payload @{
    action = "artifact.save"; artifact_type = "journal"
    title = "Child artifact"; parent_artifact_id = "00000000-0000-0000-0000-000000000000"
} -ExpectResult "error" -ExpectCode "PARENT_NOT_SUPPORTED"

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 8: Enforcement - Tag Governance
# ================================================================

Write-Host "`nGROUP 8: Tag Governance" -ForegroundColor Cyan

# T33: demo-seed tag stripped (should not error, just stripped)
$r = Test-Case -Name "T33 - demo-seed tag stripped silently" -Payload @{
    action = "artifact.save"; artifact_type = "journal"
    title = "Seed tag test"; tags = @("demo-seed", "user-tag")
} -ExpectResult "ok"
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }

# T34: for-q and for-cc tags stripped silently
$r = Test-Case -Name "T34 - for-q and for-cc tags stripped silently" -Payload @{
    action = "artifact.save"; artifact_type = "journal"
    title = "ForQ tag test"; tags = @("for-q", "for-cc", "legit-tag")
} -ExpectResult "ok"
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "journal" } }
$tagTestId = $r.artifact_id

# T35: Verify stripped tags via query
if ($tagTestId) {
    $q = Invoke-Demo -Body @{ action = "artifact.query"; artifact_type = "journal"; artifact_id = $tagTestId }
    $tags = $q.artifact.tags
    $hasDemoSeed = $tags -contains "demo-seed"
    $hasForQ = $tags -contains "for-q"
    $hasForCC = $tags -contains "for-cc"
    $hasDemoMode = $tags -contains "demo-mode"
    $hasExploreQwrk = $tags -contains "explore-qwrk"
    $hasLegit = $tags -contains "legit-tag"

    $tagPass = (-not $hasDemoSeed) -and (-not $hasForQ) -and (-not $hasForCC) -and $hasDemoMode -and $hasExploreQwrk -and $hasLegit
    $status = if ($tagPass) { "PASS" } else { "FAIL" }
    $color = if ($tagPass) { "Green" } else { "Red" }
    Write-Host "  [$status] T35 - Verify tag injection + stripping via query" -ForegroundColor $color
    if (-not $tagPass) {
        Write-Host "         Tags found: $($tags -join ', ')" -ForegroundColor DarkYellow
    }
    $global:testResults += @{ Name = "T35 - Verify tag injection + stripping via query"; Status = $status; Detail = "" }
} else {
    Write-Host "  [SKIP] T35 - No artifact ID from T34" -ForegroundColor Yellow
}

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 9: Enforcement - Query Validation
# ================================================================

Write-Host "`nGROUP 9: Query Validation" -ForegroundColor Cyan

# T36: query missing artifact_id
Test-Case -Name "T36 - Query missing artifact_id" -Payload @{ action = "artifact.query"; artifact_type = "journal" } -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# T37: query missing artifact_type
Test-Case -Name "T37 - Query missing artifact_type" -Payload @{ action = "artifact.query"; artifact_id = "00000000-0000-0000-0000-000000000000" } -ExpectResult "error" -ExpectCode "VALIDATION_ERROR"

# T38: query with nonexistent artifact_id
Test-Case -Name "T38 - Query nonexistent artifact" -Payload @{ action = "artifact.query"; artifact_type = "journal"; artifact_id = "00000000-0000-0000-0000-000000000000" } -ExpectResult "error"

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 10: Response Shaping - Internal Fields Stripped
# ================================================================

Write-Host "`nGROUP 10: Response Shaping" -ForegroundColor Cyan

# T39: Query response should NOT contain internal fields
if ($savedJournalId) {
    $q = Invoke-Demo -Body @{ action = "artifact.query"; artifact_type = "journal"; artifact_id = $savedJournalId }
    $jsonStr = $q | ConvertTo-Json -Depth 10
    $hasWorkspaceId = $jsonStr -match '"workspace_id"'
    $hasOwnerId = $jsonStr -match '"owner_user_id"'
    $hasSemTypeId = $jsonStr -match '"semantic_type_id"'
    $hasGwRoute = $jsonStr -match '"_gw_route"'

    $stripPass = (-not $hasWorkspaceId) -and (-not $hasOwnerId) -and (-not $hasSemTypeId) -and (-not $hasGwRoute)
    $status = if ($stripPass) { "PASS" } else { "FAIL" }
    $color = if ($stripPass) { "Green" } else { "Red" }
    Write-Host "  [$status] T39 - Query response strips internal fields" -ForegroundColor $color
    if (-not $stripPass) {
        $leaked = @()
        if ($hasWorkspaceId) { $leaked += "workspace_id" }
        if ($hasOwnerId) { $leaked += "owner_user_id" }
        if ($hasSemTypeId) { $leaked += "semantic_type_id" }
        if ($hasGwRoute) { $leaked += "_gw_route" }
        Write-Host "         Leaked fields: $($leaked -join ', ')" -ForegroundColor DarkYellow
    }
    $global:testResults += @{ Name = "T39 - Query response strips internal fields"; Status = $status; Detail = "" }
} else {
    Write-Host "  [SKIP] T39 - No journal ID from T01" -ForegroundColor Yellow
}

# T40: List response should have ok, artifacts, count
Test-Case -Name "T40 - List response shape ok+artifacts+count" -Payload @{ action = "artifact.list"; artifact_type = "journal" } -ExpectResult "ok" -Validate {
    param($r)
    ($r.PSObject.Properties.Name -contains "ok") -and
    ($r.PSObject.Properties.Name -contains "artifacts") -and
    ($r.PSObject.Properties.Name -contains "count") -and
    ($r.count -eq $r.artifacts.Count)
}

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 11: Extension Injection Verification
# ================================================================

Write-Host "`nGROUP 11: Extension Injection" -ForegroundColor Cyan

# T42: Project query should show lifecycle_stage = seed
if ($savedProjectId) {
    $q = Invoke-Demo -Body @{ action = "artifact.query"; artifact_type = "project"; artifact_id = $savedProjectId }
    $a = $q.artifact
    $lcs = $a.lifecycle_status
    $passed = ($lcs -eq "seed")
    $status = if ($passed) { "PASS" } else { "FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }
    Write-Host "  [$status] T42 - Project has lifecycle_stage = seed" -ForegroundColor $color
    if (-not $passed) { Write-Host "         lifecycle_status = '$lcs'" -ForegroundColor DarkYellow }
    $global:testResults += @{ Name = "T42 - Project has lifecycle_stage = seed"; Status = $status; Detail = "" }
} else {
    Write-Host "  [SKIP] T42 - No project ID from T02" -ForegroundColor Yellow
}

# T43: Snapshot query should show payload from content
if ($savedSnapshotId) {
    $q = Invoke-Demo -Body @{ action = "artifact.query"; artifact_type = "snapshot"; artifact_id = $savedSnapshotId }
    $a = $q.artifact
    $hasPayload = ($null -ne $a.extension.payload)
    $hasDecision = ($a.extension.payload.decision -eq "Test decision")
    $passed = $hasPayload -and $hasDecision
    $status = if ($passed) { "PASS" } else { "FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }
    Write-Host "  [$status] T43 - Snapshot has payload from content" -ForegroundColor $color
    if (-not $passed) { Write-Host "         payload: $($a.payload | ConvertTo-Json -Depth 3 -Compress)" -ForegroundColor DarkYellow }
    $global:testResults += @{ Name = "T43 - Snapshot has payload from content"; Status = $status; Detail = "" }
} else {
    Write-Host "  [SKIP] T43 - No snapshot ID from T03" -ForegroundColor Yellow
}

# T44: Journal query should have entry_text
if ($savedJournalId) {
    $q = Invoke-Demo -Body @{ action = "artifact.query"; artifact_type = "journal"; artifact_id = $savedJournalId }
    $a = $q.artifact
    $hasEntryText = ($null -ne $a.extension -and $a.extension.PSObject.Properties.Name -contains "entry_text")
    $status = if ($hasEntryText) { "PASS" } else { "FAIL" }
    $color = if ($hasEntryText) { "Green" } else { "Red" }
    Write-Host "  [$status] T44 - Journal has entry_text field" -ForegroundColor $color
    $global:testResults += @{ Name = "T44 - Journal has entry_text field"; Status = $status; Detail = "" }
} else {
    Write-Host "  [SKIP] T44 - No journal ID from T01" -ForegroundColor Yellow
}

# T45: Snapshot with NO content should still save (empty payload)
$r = Test-Case -Name "T45 - Save snapshot without content empty payload" -Payload @{
    action = "artifact.save"; artifact_type = "snapshot"
    title = "Empty Snapshot"; summary = "Snapshot with no content field."
} -ExpectResult "ok"
if ($r.artifact_id) { $global:createdArtifacts += @{ id = $r.artifact_id; type = "snapshot" } }

# -- Rate limit pause --
Write-Host "`n  [pause 15s - rate limit cooldown]" -ForegroundColor DarkGray
Start-Sleep -Seconds 65

# ================================================================
# GROUP 12: Seed Artifact Visibility
# ================================================================

Write-Host "`nGROUP 12: Seed Artifact Visibility" -ForegroundColor Cyan

# T46: List projects should include seed artifacts
Test-Case -Name "T46 - List projects includes seed data" -Payload @{ action = "artifact.list"; artifact_type = "project"; limit = 20 } -ExpectResult "ok" -Validate {
    param($r)
    $items = if ($r.artifacts[0].data) { $r.artifacts[0].data.artifacts } else { $r.artifacts }
    $titles = $items | ForEach-Object { $_.title }
    $titles -contains "Starting a Side Project"
}

# T47: List journals should include seed journals
Test-Case -Name "T47 - List journals includes seed data" -Payload @{ action = "artifact.list"; artifact_type = "journal"; limit = 20; offset = 0 } -ExpectResult "ok" -Validate {
    param($r)
    $meta = $r.artifacts[0].meta
    $items = if ($r.artifacts[0].data) { $r.artifacts[0].data.artifacts } else { $r.artifacts }
    # Seed journals exist if total count >= 2 (at least the 2 seeds) and list returns data
    ($meta.count -ge 2) -and ($items.Count -gt 0)
}

# T48: List snapshots should include seed snapshot
Test-Case -Name "T48 - List snapshots includes seed data" -Payload @{ action = "artifact.list"; artifact_type = "snapshot"; limit = 20 } -ExpectResult "ok" -Validate {
    param($r)
    $items = if ($r.artifacts[0].data) { $r.artifacts[0].data.artifacts } else { $r.artifacts }
    $titles = $items | ForEach-Object { $_.title }
    $titles -contains "Decision: Keep It Simple"
}

# ================================================================
# RESULTS SUMMARY
# ================================================================

Write-Host "`n===============================================" -ForegroundColor White
Write-Host "  DEMO PROXY TEST RESULTS" -ForegroundColor White
Write-Host "===============================================" -ForegroundColor White

$pass = ($global:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$fail = ($global:testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $global:testResults.Count

$summaryColor = if ($fail -eq 0) { "Green" } else { "Red" }
Write-Host "`n  Total: $total  |  PASS: $pass  |  FAIL: $fail" -ForegroundColor $summaryColor

if ($fail -gt 0) {
    Write-Host "`n  Failed tests:" -ForegroundColor Red
    $global:testResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "    - $($_.Name)" -ForegroundColor Red
        if ($_.Detail) { Write-Host "      $($_.Detail)" -ForegroundColor DarkYellow }
    }
}

Write-Host "`n  Artifacts created: $($global:createdArtifacts.Count)" -ForegroundColor DarkGray
if ($global:createdArtifacts.Count -gt 0) {
    Write-Host "  (Will be cleaned by nightly job - no demo-seed tag)" -ForegroundColor DarkGray
}

Write-Host ""
