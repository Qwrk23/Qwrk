# Replicate EXACTLY what CC-Gateway-Query.ps1 does
$Tags = "for-q"
$ArtifactType = "snapshot"
$Limit = 5
$Offset = 0

$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type" = "application/json"
}

$selector = @{
    limit = $Limit
    offset = $Offset
    hydrate = $false
}

if ($Tags) {
    $tagArray = $Tags -split "," | ForEach-Object { $_.Trim() }
    $selector["filters"] = @{ tags_any = $tagArray }
}

$body = @{
    gw_action = "artifact.list"
    gw_workspace_id = $workspaceId
    selector = $selector
}

if ($ArtifactType) {
    $body["artifact_type"] = $ArtifactType
}

$jsonBody = $body | ConvertTo-Json -Depth 5

Write-Host "=== JSON payload (from CC script logic) ==="
Write-Host $jsonBody

Write-Host "`n=== Sending to Gateway ==="
try {
    $response = Invoke-RestMethod -Uri $gatewayUrl -Method POST -Body $jsonBody -ContentType "application/json" -Headers $headers
    Write-Host "=== Response type: $($response.GetType().FullName) ==="
    Write-Host "=== Response ok: $($response.ok) ==="
    Write-Host "=== Full response ==="
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "=== Exception ==="
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host $reader.ReadToEnd()
    }
}
