$cred = "cXdyay1nYXRld2F5OmFzbGZqYSd3d2UqKCNmaHdvSUk4NDNnaGx3X2VrMmw="

$body = @{
    gw_action = "artifact.list"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type = "journal"
    selector = @{ limit = 5 }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" `
    -Method POST `
    -Headers @{ Authorization = "Basic $cred"; "Content-Type" = "application/json" } `
    -Body $body

Write-Host "Recent journals:" -ForegroundColor Cyan
$response.data.artifacts | ForEach-Object {
    Write-Host "  $($_.artifact_id) | $($_.title) | $($_.created_at)"
}

# Check for the specific artifact
$target = $response.data.artifacts | Where-Object { $_.artifact_id -like "12e15422*" }
if ($target) {
    Write-Host "`nVERIFIED: Chrome extension artifact found!" -ForegroundColor Green
    Write-Host "  artifact_id: $($target.artifact_id)"
    Write-Host "  title: $($target.title)"
    Write-Host "  created_at: $($target.created_at)"
} else {
    Write-Host "`nNot found in top 5. Checking with larger limit..." -ForegroundColor Yellow
}
