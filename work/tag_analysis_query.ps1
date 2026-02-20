# Tag Analysis Queries for Backfill Planning
# DO NOT EXECUTE ANY UPDATES - READ ONLY

$gateway = 'https://n8n.halosparkai.com/webhook/nqxb/gateway/v1'
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$workspace = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'

$headers = @{
    'Authorization' = "Basic $cred"
    'Content-Type' = 'application/json'
}

function Invoke-GatewayList {
    param(
        [string]$ArtifactType,
        [int]$Limit = 100,
        [bool]$Hydrate = $false
    )

    $body = @{
        gw_action = 'artifact.list'
        gw_workspace_id = $workspace
        artifact_type = $ArtifactType
        selector = @{
            limit = $Limit
            hydrate = $Hydrate
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $gateway -Method POST -Headers $headers -Body $body
    return $response
}

Write-Host "=== TAG BACKFILL ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get counts for each artifact type
Write-Host "=== ARTIFACT TYPE COUNTS ===" -ForegroundColor Yellow

$types = @('project', 'journal', 'snapshot', 'restart', 'instruction_pack')
$summary = @{}

foreach ($type in $types) {
    $result = Invoke-GatewayList -ArtifactType $type -Limit 500
    if ($result.ok) {
        $count = $result.data.Count
        $summary[$type] = $count
        Write-Host "$type : $count" -ForegroundColor Green
    } else {
        Write-Host "$type : ERROR - $($result.error.message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Total artifacts: $($summary.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum)" -ForegroundColor Cyan
Write-Host ""

# Sample titles from each type
Write-Host "=== SAMPLE TITLES BY TYPE ===" -ForegroundColor Yellow

foreach ($type in $types) {
    Write-Host ""
    Write-Host "--- $($type.ToUpper()) ---" -ForegroundColor Cyan
    $result = Invoke-GatewayList -ArtifactType $type -Limit 50 -Hydrate $false
    if ($result.ok -and $result.data.Count -gt 0) {
        $result.data | ForEach-Object {
            $title = $_.title
            $lifecycle = if ($_.lifecycle_status) { " [$($_.lifecycle_status)]" } else { "" }
            $tags = if ($_.tags -and $_.tags.Count -gt 0) { " tags: $($_.tags -join ', ')" } else { " (no tags)" }
            Write-Host "  - $title$lifecycle$tags" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "=== TITLE PATTERN ANALYSIS ===" -ForegroundColor Yellow

# Analyze title patterns
$allArtifacts = @()
foreach ($type in $types) {
    $result = Invoke-GatewayList -ArtifactType $type -Limit 500 -Hydrate $false
    if ($result.ok) {
        foreach ($item in $result.data) {
            $allArtifacts += [PSCustomObject]@{
                artifact_id = $item.artifact_id
                artifact_type = $type
                title = $item.title
                lifecycle_status = $item.lifecycle_status
                tags = $item.tags
                parent_artifact_id = $item.parent_artifact_id
            }
        }
    }
}

# Pattern detection
$patterns = @{
    'BUG-' = ($allArtifacts | Where-Object { $_.title -match 'BUG-\d+' }).Count
    'Seed —' = ($allArtifacts | Where-Object { $_.title -match 'Seed\s*[—–-]' }).Count
    'RESTART' = ($allArtifacts | Where-Object { $_.title -match 'RESTART|Restart' }).Count
    'SNAPSHOT' = ($allArtifacts | Where-Object { $_.title -match 'SNAPSHOT|Snapshot' }).Count
    'KGB' = ($allArtifacts | Where-Object { $_.title -match 'KGB' }).Count
    'Gateway' = ($allArtifacts | Where-Object { $_.title -match 'Gateway' }).Count
    'Test' = ($allArtifacts | Where-Object { $_.title -match '\bTest\b' }).Count
    'PRD' = ($allArtifacts | Where-Object { $_.title -match 'PRD' }).Count
    'North Star' = ($allArtifacts | Where-Object { $_.title -match 'North\s*Star' }).Count
    'Session' = ($allArtifacts | Where-Object { $_.title -match '\bSession\b' }).Count
    'Journal' = ($allArtifacts | Where-Object { $_.title -match '\bJournal\b' }).Count
    'Morning' = ($allArtifacts | Where-Object { $_.title -match '\bMorning\b' }).Count
    'Briefing' = ($allArtifacts | Where-Object { $_.title -match '\bBriefing\b' }).Count
    'Telegram' = ($allArtifacts | Where-Object { $_.title -match '\bTelegram\b' }).Count
    'Moltbot' = ($allArtifacts | Where-Object { $_.title -match '\bMoltbot\b' }).Count
}

Write-Host ""
foreach ($pattern in $patterns.GetEnumerator() | Sort-Object Value -Descending) {
    Write-Host "  Pattern '$($pattern.Key)': $($pattern.Value) matches" -ForegroundColor White
}

Write-Host ""
Write-Host "=== LIFECYCLE STATUS DISTRIBUTION (Projects) ===" -ForegroundColor Yellow
$projects = $allArtifacts | Where-Object { $_.artifact_type -eq 'project' }
$lifecycleGroups = $projects | Group-Object -Property lifecycle_status
foreach ($group in $lifecycleGroups) {
    Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== EXISTING TAGS CHECK ===" -ForegroundColor Yellow
$withTags = $allArtifacts | Where-Object { $_.tags -and $_.tags.Count -gt 0 }
Write-Host "  Artifacts with existing tags: $($withTags.Count)" -ForegroundColor White
$withoutTags = $allArtifacts | Where-Object { -not $_.tags -or $_.tags.Count -eq 0 }
Write-Host "  Artifacts without tags: $($withoutTags.Count)" -ForegroundColor White

if ($withTags.Count -gt 0) {
    Write-Host ""
    Write-Host "  Existing tag values:" -ForegroundColor Cyan
    $allTags = $withTags | ForEach-Object { $_.tags } | Where-Object { $_ } | ForEach-Object { $_ }
    $tagCounts = $allTags | Group-Object | Sort-Object Count -Descending
    foreach ($tag in $tagCounts) {
        Write-Host "    '$($tag.Name)': $($tag.Count)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=== PARENT RELATIONSHIP CHECK ===" -ForegroundColor Yellow
$withParent = $allArtifacts | Where-Object { $_.parent_artifact_id }
Write-Host "  Artifacts with parent_artifact_id: $($withParent.Count)" -ForegroundColor White
$withoutParent = $allArtifacts | Where-Object { -not $_.parent_artifact_id }
Write-Host "  Artifacts without parent: $($withoutParent.Count)" -ForegroundColor White

Write-Host ""
Write-Host "=== ANALYSIS COMPLETE ===" -ForegroundColor Green
