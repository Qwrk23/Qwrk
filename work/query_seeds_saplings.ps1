# Query seeds and saplings from Gateway
$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
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
    hydrate = $false
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri $gatewayUrl -Method Post -Headers $headers -Body $body

$response.data.artifacts | Where-Object { $_.lifecycle_status -in @('seed', 'sapling') } | ForEach-Object {
    Write-Host ("{0} | {1,-8} | {2}" -f $_.artifact_id.Substring(0,8), $_.lifecycle_status, $_.title)
}

Write-Host ""
Write-Host "Total seeds/saplings: $($response.data.artifacts | Where-Object { $_.lifecycle_status -in @('seed', 'sapling') } | Measure-Object | Select-Object -ExpandProperty Count)"
