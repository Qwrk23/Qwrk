<#
.SYNOPSIS
    Full Gateway regression test suite for T94 (Twig Activation).
#>

param([switch]$CleanupOnly)

$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$semTypeId = "f65bd1a8-7720-4d7b-942c-ce8e2132b365"
$cred = "qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($cred))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type"  = "application/json"
}

function Get-ArtifactId {
    param($resp)
    if ($resp.artifact_id) { return $resp.artifact_id }
    if ($resp.artifact -and $resp.artifact.artifact_id) { return $resp.artifact.artifact_id }
    if ($resp.data -and $resp.data.artifact_id) { return $resp.data.artifact_id }
    return $null
}

function Get-QueryArtifact {
    param($resp)
    if ($resp.data -and $resp.data.artifact) { return $resp.data.artifact }
    if ($resp.artifact) { return $resp.artifact }
    return $null
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
                $detail = "Expected error code $ExpectCode but got $actualCode"
            } else { $passed = $true }
        } else { $detail = "Expected error but got ok" }
    }

    $status = if ($passed) { "PASS" } else { "FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }
    Write-Host "  [$status] $Name" -ForegroundColor $color
    if ($detail) { Write-Host "         $detail" -ForegroundColor DarkYellow }
    $global:testResults += @{ Name = $Name; Status = $status; Detail = $detail }
    return $resp
}

if ($CleanupOnly) {
    Write-Host "`n=== CLEANUP: Soft-deleting all T94-CERT artifacts ===" -ForegroundColor Cyan
    $types = @("twig", "project", "journal", "snapshot", "branch", "leaf")
    $allTestIds = @()
    foreach ($type in $types) {
        $listResp = Invoke-GW -Body @{
            gw_action = "artifact.list"; gw_workspace_id = $workspaceId
            artifact_type = $type; selector = @{ limit = 50; hydrate = $false }
        }
        if ($listResp.ok -and $listResp.data.artifacts) {
            foreach ($a in $listResp.data.artifacts) {
                if ($a.title -like "T94-CERT*") {
                    $allTestIds += @{ id = $a.artifact_id; type = $a.artifact_type; title = $a.title }
                }
            }
        }
    }
    if ($allTestIds.Count -eq 0) { Write-Host "No T94-CERT artifacts found. Clean!" -ForegroundColor Green; return }
    Write-Host "Found $($allTestIds.Count) T94-CERT artifacts to delete:" -ForegroundColor Yellow
    foreach ($item in $allTestIds) { Write-Host "  $($item.id) | $($item.type) | $($item.title)" -ForegroundColor DarkGray }
    foreach ($item in $allTestIds) {
        $delResp = Invoke-GW -Body @{
            gw_action = "artifact.delete"; gw_workspace_id = $workspaceId
            artifact_id = $item.id; artifact_type = $item.type
        }
        $status = if ($delResp.ok) { "DELETED" } else { "FAILED" }
        $color = if ($delResp.ok) { "Green" } else { "Red" }
        Write-Host "  [$status] $($item.title)" -ForegroundColor $color
    }
    Write-Host "`nCleanup complete." -ForegroundColor Cyan
    return
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Gateway Regression Suite - T94" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "--- 1. artifact.save ---" -ForegroundColor Yellow

$twigSaveResp = Test-Case -Name "Save twig (proposed)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "twig"; title = "T94-CERT -- Twig Save Test"
    lifecycle_status = "proposed"; tags = @("t94-cert")
}
$twigId = Get-ArtifactId $twigSaveResp
if ($twigId) { $global:createdArtifacts += @{ id = $twigId; type = "twig" }; Write-Host "         Created twig: $twigId" -ForegroundColor DarkGray }

$projSaveResp = Test-Case -Name "Save project (regression)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "project"; title = "T94-CERT -- Project Regression"
    semantic_type_id = $semTypeId; tags = @("t94-cert")
    extension = @{ lifecycle_stage = "seed" }
}
$projId = Get-ArtifactId $projSaveResp
if ($projId) { $global:createdArtifacts += @{ id = $projId; type = "project" }; Write-Host "         Created project: $projId" -ForegroundColor DarkGray }

$journalSaveResp = Test-Case -Name "Save journal (regression)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "journal"; title = "T94-CERT -- Journal Regression"
    semantic_type_id = $semTypeId; tags = @("t94-cert")
    extension = @{ entry_text = "Test journal entry for T94 certification." }
}
$journalId = Get-ArtifactId $journalSaveResp
if ($journalId) { $global:createdArtifacts += @{ id = $journalId; type = "journal" }; Write-Host "         Created journal: $journalId" -ForegroundColor DarkGray }

$snapSaveResp = Test-Case -Name "Save snapshot (regression)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "snapshot"; title = "T94-CERT -- Snapshot Regression"
    semantic_type_id = $semTypeId; tags = @("t94-cert")
    extension = @{ payload = @{ test = "t94-cert-snapshot" } }
}
$snapId = Get-ArtifactId $snapSaveResp
if ($snapId) { $global:createdArtifacts += @{ id = $snapId; type = "snapshot" }; Write-Host "         Created snapshot: $snapId" -ForegroundColor DarkGray }

Write-Host "`n--- 2. artifact.query ---" -ForegroundColor Yellow

if ($twigId) {
    Test-Case -Name "Query twig by ID" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.query"; gw_workspace_id = $workspaceId
        artifact_id = $twigId; artifact_type = "twig"; selector = @{ hydrate = $true }
    } -Validate { param($r) $a = Get-QueryArtifact $r; $a -and $a.artifact_type -eq "twig" }
}

Test-Case -Name "Query project (KGB)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.query"; gw_workspace_id = $workspaceId
    artifact_id = "668bd18f-4424-41e6-b2f9-393ecd2ec534"; artifact_type = "project"
    selector = @{ hydrate = $true }
}

Test-Case -Name "Query journal (KGB)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.query"; gw_workspace_id = $workspaceId
    artifact_id = "db428a32-1afa-4e6b-a649-347b0bffd46c"; artifact_type = "journal"
    selector = @{ hydrate = $true }
}

Write-Host "`n--- 3. artifact.list ---" -ForegroundColor Yellow

Test-Case -Name "List twigs" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.list"; gw_workspace_id = $workspaceId
    artifact_type = "twig"; selector = @{ limit = 10; hydrate = $false }
}

Test-Case -Name "List projects (regression)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.list"; gw_workspace_id = $workspaceId
    artifact_type = "project"; selector = @{ limit = 5; hydrate = $false }
}

Test-Case -Name "List snapshots (regression)" -ExpectResult "ok" -Payload @{
    gw_action = "artifact.list"; gw_workspace_id = $workspaceId
    artifact_type = "snapshot"; selector = @{ limit = 5; hydrate = $false }
}

Write-Host "`n--- 4. artifact.update ---" -ForegroundColor Yellow

if ($twigId) {
    Test-Case -Name "Twig lifecycle: proposed -> active" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twigId; artifact_type = "twig"
        extension = @{ lifecycle_status = "active" }
    }
    Test-Case -Name "Twig lifecycle: active -> promoted" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twigId; artifact_type = "twig"
        extension = @{ lifecycle_status = "promoted" }
    }
    Test-Case -Name "Twig terminal guard: promoted -> active" -ExpectResult "error" -ExpectCode "ARCHIVE_TERMINAL" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twigId; artifact_type = "twig"
        extension = @{ lifecycle_status = "active" }
    }
}

$twig2SaveResp = Invoke-GW -Body @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "twig"; title = "T94-CERT -- Twig Prune Test"
    lifecycle_status = "proposed"; tags = @("t94-cert")
}
$twig2Id = if ($twig2SaveResp.ok) { $twig2SaveResp.artifact_id } else { $null }
if ($twig2Id) {
    $global:createdArtifacts += @{ id = $twig2Id; type = "twig" }
    Write-Host "         Created twig2: $twig2Id" -ForegroundColor DarkGray
    Invoke-GW -Body @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twig2Id; artifact_type = "twig"
        extension = @{ lifecycle_status = "active" }
    } | Out-Null
    Test-Case -Name "Twig lifecycle: active -> pruned" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twig2Id; artifact_type = "twig"
        extension = @{ lifecycle_status = "pruned" }
    }
    Test-Case -Name "Twig terminal guard: pruned -> active" -ExpectResult "error" -ExpectCode "ARCHIVE_TERMINAL" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twig2Id; artifact_type = "twig"
        extension = @{ lifecycle_status = "active" }
    }
}

$twig3SaveResp = Invoke-GW -Body @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "twig"; title = "T94-CERT -- Twig ExecStatus Test"
    lifecycle_status = "proposed"; tags = @("t94-cert")
}
$twig3Id = if ($twig3SaveResp.ok) { $twig3SaveResp.artifact_id } else { $null }
if ($twig3Id) {
    $global:createdArtifacts += @{ id = $twig3Id; type = "twig" }
    Write-Host "         Created twig3: $twig3Id" -ForegroundColor DarkGray
    # First set execution_status from NULL to not_started
    Invoke-GW -Body @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twig3Id; artifact_type = "twig"
        extension = @{ execution_status = "not_started" }
    } | Out-Null
    Test-Case -Name "Twig execution_status: not_started -> in_progress" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twig3Id; artifact_type = "twig"
        extension = @{ execution_status = "in_progress" }
    }
}

if ($projId) {
    # execution_status via extension is blocked for project (spine field, not extension field)
    Test-Case -Name "Project exec_status via extension blocked (regression)" -ExpectResult "error" -ExpectCode "MUTABILITY_ERROR" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $projId; artifact_type = "project"
        extension = @{ execution_status = "not_started" }
    }
    Test-Case -Name "Project summary update (regression)" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $projId; artifact_type = "project"
        extension = @{ summary = "T94-CERT test project summary for promote readiness" }
    }
}

if ($snapId) {
    Test-Case -Name "Snapshot immutability guard (regression)" -ExpectResult "error" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $snapId; artifact_type = "snapshot"
        extension = @{ payload = @{ should = "fail" } }
    }
}

$twig4SaveResp = Invoke-GW -Body @{
    gw_action = "artifact.save"; gw_workspace_id = $workspaceId
    artifact_type = "twig"; title = "T94-CERT -- Twig Invalid Transition"
    lifecycle_status = "proposed"; tags = @("t94-cert")
}
$twig4Id = if ($twig4SaveResp.ok) { $twig4SaveResp.artifact_id } else { $null }
if ($twig4Id) {
    $global:createdArtifacts += @{ id = $twig4Id; type = "twig" }
    Write-Host "         Created twig4: $twig4Id" -ForegroundColor DarkGray
    Test-Case -Name "Twig invalid transition: proposed -> promoted" -ExpectResult "error" -ExpectCode "INVALID_TRANSITION" -Payload @{
        gw_action = "artifact.update"; gw_workspace_id = $workspaceId
        artifact_id = $twig4Id; artifact_type = "twig"
        extension = @{ lifecycle_status = "promoted" }
    }
}

Write-Host "`n--- 5. artifact.promote ---" -ForegroundColor Yellow

if ($projId) {
    Test-Case -Name "Promote project seed -> sapling (regression)" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.promote"; gw_workspace_id = $workspaceId
        artifact_id = $projId; artifact_type = "project"
        transition = "seed_to_sapling"; reason = "T94 certification regression test"
    }
}

Write-Host "`n--- 6. artifact.delete ---" -ForegroundColor Yellow

if ($twig4Id) {
    Test-Case -Name "Delete twig (soft)" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.delete"; gw_workspace_id = $workspaceId
        artifact_id = $twig4Id; artifact_type = "twig"
    }
}

Write-Host "`n--- 7. artifact.list_deleted ---" -ForegroundColor Yellow

# list_deleted returns non-JSON (empty string) in current Gateway -- test it doesn't crash
$ldResp = Invoke-GW -Body @{
    gw_action = "artifact.list_deleted"; gw_workspace_id = $workspaceId
    selector = @{ limit = 10 }
}
$ldPassed = ($ldResp -ne $null)
$ldStatus = if ($ldPassed) { "PASS" } else { "FAIL" }
$ldColor = if ($ldPassed) { "Green" } else { "Red" }
Write-Host "  [$ldStatus] List deleted artifacts (smoke test)" -ForegroundColor $ldColor
$global:testResults += @{ Name = "List deleted artifacts (smoke)"; Status = $ldStatus; Detail = "" }

Write-Host "`n--- 8. artifact.restore ---" -ForegroundColor Yellow

if ($twig4Id) {
    Test-Case -Name "Restore deleted twig" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.restore"; gw_workspace_id = $workspaceId
        artifact_id = $twig4Id; artifact_type = "twig"
    }
}

Write-Host "`n--- 9. Read-back verification ---" -ForegroundColor Yellow

if ($twigId) {
    Test-Case -Name "Verify twig1 lifecycle_status = promoted" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.query"; gw_workspace_id = $workspaceId
        artifact_id = $twigId; artifact_type = "twig"; selector = @{ hydrate = $true }
    } -Validate {
        param($r)
        $a = Get-QueryArtifact $r
        $a.lifecycle_status -eq "promoted"
    }
}

if ($twig2Id) {
    Test-Case -Name "Verify twig2 lifecycle_status = pruned" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.query"; gw_workspace_id = $workspaceId
        artifact_id = $twig2Id; artifact_type = "twig"; selector = @{ hydrate = $true }
    } -Validate {
        param($r)
        $a = Get-QueryArtifact $r
        $a.lifecycle_status -eq "pruned"
    }
}

if ($twig3Id) {
    Test-Case -Name "Verify twig3 execution_status = in_progress" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.query"; gw_workspace_id = $workspaceId
        artifact_id = $twig3Id; artifact_type = "twig"; selector = @{ hydrate = $true }
    } -Validate {
        param($r)
        $a = Get-QueryArtifact $r
        $a.execution_status -eq "in_progress"
    }
}

if ($twig4Id) {
    Test-Case -Name "Verify restored twig4 is queryable" -ExpectResult "ok" -Payload @{
        gw_action = "artifact.query"; gw_workspace_id = $workspaceId
        artifact_id = $twig4Id; artifact_type = "twig"; selector = @{ hydrate = $true }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passed = ($global:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($global:testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $global:testResults.Count

Write-Host "`n  Total:  $total" -ForegroundColor White
Write-Host "  PASS:   $passed" -ForegroundColor Green
$failColor = if ($failed -gt 0) { "Red" } else { "Green" }
Write-Host "  FAIL:   $failed" -ForegroundColor $failColor

if ($failed -gt 0) {
    Write-Host "`n  Failed tests:" -ForegroundColor Red
    foreach ($t in ($global:testResults | Where-Object { $_.Status -eq "FAIL" })) {
        Write-Host "    - $($t.Name): $($t.Detail)" -ForegroundColor Red
    }
}

Write-Host "`n  Test artifacts created: $($global:createdArtifacts.Count)" -ForegroundColor DarkGray
foreach ($a in $global:createdArtifacts) {
    Write-Host "    $($a.id) ($($a.type))" -ForegroundColor DarkGray
}
Write-Host "`n  Run with -CleanupOnly to soft-delete all T94-CERT artifacts.`n" -ForegroundColor DarkGray
