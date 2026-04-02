# A3 Branch Count Test - checks if INSERT actually succeeds
# Run: powershell -File "scripts/a3_count_test.ps1"

$raw1 = powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType branch -Limit 100 -Raw
$resp1 = $raw1 | ConvertFrom-Json
$before = $resp1.data.Count
Write-Host "Branch count BEFORE: $before" -ForegroundColor Cyan

# Run A3 save
$GatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$Credential = [System.Convert]::ToBase64String(
    [System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l")
)
$Headers = @{
    "Authorization" = "Basic $Credential"
    "Content-Type"  = "application/json; charset=utf-8"
}

$payload = @{
    gw_action = "artifact.save"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type = "branch"
    title = "A3 count test - $(Get-Date -Format 'HH:mm:ss')"
    parent_artifact_id = "668bd18f-4424-41e6-b2f9-393ecd2ec534"
} | ConvertTo-Json -Depth 5

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
try {
    $r = Invoke-WebRequest -Uri $GatewayUrl -Method POST -Body $bodyBytes `
        -Headers $Headers -ContentType "application/json; charset=utf-8" -UseBasicParsing
    $saveResp = $r.Content | ConvertFrom-Json
} catch {
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        try { $saveResp = $_.ErrorDetails.Message | ConvertFrom-Json } catch { $saveResp = @{ _raw = $_.ErrorDetails.Message } }
    } else {
        $saveResp = @{ _exception = $_.Exception.Message }
    }
}

Write-Host "Save response:" -ForegroundColor Yellow
Write-Host ($saveResp | ConvertTo-Json -Depth 5 -Compress) -ForegroundColor Yellow

# Count after
Start-Sleep -Seconds 2
$raw2 = powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType branch -Limit 100 -Raw
$resp2 = $raw2 | ConvertFrom-Json
$after = $resp2.data.Count
Write-Host "Branch count AFTER:  $after" -ForegroundColor Cyan

if ($after -gt $before) {
    Write-Host "INSERT SUCCEEDED (+$($after - $before) branches)" -ForegroundColor Green
} elseif ($after -eq $before) {
    Write-Host "INSERT FAILED (count unchanged)" -ForegroundColor Red
} else {
    Write-Host "UNEXPECTED (count decreased?)" -ForegroundColor Red
}
