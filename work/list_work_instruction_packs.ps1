# List instruction_packs in Work workspace
$webhookUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/work"
$principal = "qwrk-gw-work"
$password = "ufwpjNF0PEMq4R92ST6zKQM5eeVs7BnM"

$pair = "${principal}:${password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

$body = @{
    gw_action       = "artifact.list"
    gw_workspace_id = "635bb8d7-7b93-4bea-8ca6-ee2c924c9557"
    artifact_type   = "instruction_pack"
    selector        = @{ limit = 5; offset = 0 }
} | ConvertTo-Json -Depth 5

Write-Host "=== LIST: instruction_packs in Work workspace ===" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body -UseBasicParsing
    Write-Host "HTTP Status: $($response.StatusCode)" -ForegroundColor Yellow
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
