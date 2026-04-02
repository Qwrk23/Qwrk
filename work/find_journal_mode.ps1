# Find Journal Mode Redesign artifact
$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type" = "application/json"
}

$body = @{
    gw_action = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type = "project"
    limit = 50
    offset = 0
    hydrate = $true
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri $gatewayUrl -Method Post -Headers $headers -Body $body

$artifact = $response.data.artifacts | Where-Object { $_.title -like "*Journal Mode Redesign*" }
if ($artifact) {
    $artifact | ConvertTo-Json -Depth 10
} else {
    Write-Host "Not found"
}
