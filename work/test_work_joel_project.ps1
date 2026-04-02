# Test 1 retry with project type

$webhookUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$principal = "qwrk-gw-work"
$password = "ufwpjNF0PEMq4R92ST6zKQM5eeVs7BnM"
$workspaceId = "635bb8d7-7b93-4bea-8ca6-ee2c924c9557"

$pair = "${principal}:${password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

Write-Host "=== TEST 1 RETRY: artifact.list with project type ===" -ForegroundColor Cyan

$body = @{
    gw_action       = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type   = "project"
    selector        = @{ limit = 3; offset = 0 }
} | ConvertTo-Json -Depth 5

Write-Host "Request:" -ForegroundColor Gray
Write-Host $body

try {
    $response = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body -UseBasicParsing
    Write-Host "`nHTTP Status: $($response.StatusCode)" -ForegroundColor Yellow
    Write-Host "Content-Length: $($response.Content.Length)" -ForegroundColor Yellow
    Write-Host "Response:" -ForegroundColor Yellow
    Write-Host $response.Content
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "HTTP Status: $errStatus" -ForegroundColor Red
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Body: $($reader.ReadToEnd())" -ForegroundColor Red
    } catch {}
}
