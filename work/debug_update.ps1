# Debug: test artifact.update on snapshot with tags.add
$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$body = @{
    gw_action = "artifact.update"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type = "snapshot"
    artifact_id = "a52f402e-1b07-4e6e-bb44-a3bb776f87af"
    tags = @{
        add = @("personal")
    }
} | ConvertTo-Json -Depth 5

Write-Host "Request body:" -ForegroundColor Cyan
Write-Host $body

try {
    $response = Invoke-WebRequest -Uri $gatewayUrl -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization = "Basic $credential" } -UseBasicParsing
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host $response.Content
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $responseBody = $reader.ReadToEnd()
    Write-Host "Response body:" -ForegroundColor Yellow
    Write-Host $responseBody
}
