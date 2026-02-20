# Batch tag update: add "personal" tag to 8 artifacts
# One-time execution script — session override granted by Joel

$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type" = "application/json"
}

$updates = @(
    @{ id = "d13e690d-eae1-49f0-8a5e-eb0d9472896c"; type = "journal"; title = "Year-End Vision 2026 - Relationships"; tags = @("reflection","vision","relationships","personal") },
    @{ id = "c8dc4eda-3cd9-4e24-91f6-ca43793767f3"; type = "journal"; title = "Year-End Vision 2026 - Qwrk and ADHD"; tags = @("reflection","vision","qwrk","adhd","personal") },
    @{ id = "76f00a98-2f18-4096-a7af-f69781bbafa8"; type = "journal"; title = "10-Year Family Anniversary"; tags = @("family","identity","havi","qwrk","purpose","coach qwrk","cqa1c","personal") },
    @{ id = "04ac158c-3c3f-4f3e-bebc-19b4790253f9"; type = "journal"; title = "Active Journaling - From Proving to Expressing"; tags = @("journal","reflection","identity","personal") },
    @{ id = "b5f14d41-340a-4351-8d07-2c3eb672c4b6"; type = "journal"; title = "Tuesday Strength Re-Entry"; tags = @("journal","fitness","tuesday","discipline","personal") },
    @{ id = "bb698d50-da2d-47be-bd95-e2052eeb75e6"; type = "journal"; title = "Reading Journal - Red October Part 2"; tags = @("reading-journal","book:red-october","season:old-bull","personal") },
    @{ id = "6ef36b70-6f77-4a19-a75b-ffa6a41162a8"; type = "journal"; title = "Reading Journal - Red October Part 1"; tags = @("reading-journal","book:red-october","season:old-bull","personal") },
    @{ id = "a52f402e-1b07-4e6e-bb44-a3bb776f87af"; type = "snapshot"; title = "Active Book Context - Red October"; tags = @("for-q","active-context","active-book","book:red-october","personal") }
)

$success = 0
$failed = 0

foreach ($u in $updates) {
    $body = @{
        gw_action = "artifact.update"
        gw_workspace_id = $workspaceId
        artifact_type = $u.type
        artifact_id = $u.id
        tags = $u.tags
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri $gatewayUrl -Method POST -Body $body -ContentType "application/json" -Headers $headers
        if ($response.ok -eq $true) {
            Write-Host "[OK] $($u.title)" -ForegroundColor Green
            $success++
        } else {
            Write-Host "[FAIL] $($u.title): $($response.error.message)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "[ERROR] $($u.title): $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Done: $success succeeded, $failed failed" -ForegroundColor Cyan
