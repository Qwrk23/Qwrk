# Smoke test: Save a snapshot via Work_Joel clone

$webhookUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
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
    gw_action       = "artifact.save"
    gw_workspace_id = "635bb8d7-7b93-4bea-8ca6-ee2c924c9557"
    artifact_type   = "snapshot"
    title           = "Work Clone Smoke Test - Snapshot"
    priority        = 3
    tags            = @("smoke-test", "work-clone")
    extension       = @{
        payload = @{
            test      = $true
            origin    = "Qwrk@Work clone validation"
            timestamp = "manual-test"
        }
    }
} | ConvertTo-Json -Depth 5

Write-Host "=== SAVE: Work Clone Smoke Test ===" -ForegroundColor Cyan
Write-Host "URL: $webhookUrl" -ForegroundColor Gray
Write-Host "Body:" -ForegroundColor Gray
Write-Host $body

try {
    $response = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body -UseBasicParsing
    Write-Host "`nHTTP Status: $($response.StatusCode)" -ForegroundColor Yellow
    Write-Host "Response:" -ForegroundColor Yellow
    Write-Host $response.Content
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "HTTP Status: $errStatus" -ForegroundColor Red
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Body: $($reader.ReadToEnd())" -ForegroundColor Red
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
