$cred = "cXdyay1nYXRld2F5OmFzbGZqYSd3d2UqKCNmaHdvSUk4NDNnaGx3X2VrMmw="

$body = @{
    gw_action = "artifact.list"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type = "project"
    selector = @{ limit = 20 }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" `
    -Method POST `
    -Headers @{ Authorization = "Basic $cred"; "Content-Type" = "application/json" } `
    -Body $body

Write-Host "Recent projects (looking for seeds about instruction updates):" -ForegroundColor Cyan
$response.data.artifacts | ForEach-Object {
    $title = $_.title
    $status = $_.lifecycle_status
    $created = $_.created_at
    $id = $_.artifact_id
    # Filter for seeds or anything mentioning instruction
    if ($title -match "instruction|prompt|format|json|telegram" -or $status -eq "seed") {
        Write-Host "  [$status] $title"
        Write-Host "    ID: $id"
        Write-Host "    Created: $created"
        Write-Host ""
    }
}
