# Debug test for Work_Joel gateway — raw output

$webhookUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/work"
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

# --- TEST 1 DEBUG: See raw response ---
Write-Host "=== TEST 1 DEBUG: Allowed Workspace ===" -ForegroundColor Cyan

$body1 = @{
    gw_action       = "artifact.list"
    gw_workspace_id = $workspaceId
    artifact_type   = "snapshot"
    selector        = @{ limit = 1 }
} | ConvertTo-Json -Depth 5

Write-Host "Request body:" -ForegroundColor Gray
Write-Host $body1

try {
    $response1 = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body1 -UseBasicParsing
    Write-Host "`nHTTP Status: $($response1.StatusCode)" -ForegroundColor Yellow
    Write-Host "Content-Type: $($response1.Headers['Content-Type'])" -ForegroundColor Yellow
    Write-Host "Content-Length: $($response1.Content.Length)" -ForegroundColor Yellow
    Write-Host "Raw Content:" -ForegroundColor Yellow
    Write-Host $response1.Content
    Write-Host "RawContent (first 500):" -ForegroundColor Yellow
    Write-Host ($response1.RawContent.Substring(0, [Math]::Min(500, $response1.RawContent.Length)))
} catch {
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "HTTP Status: $errStatus" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Error Body: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

# --- TEST 3 DEBUG: See raw response ---
Write-Host "`n=== TEST 3 DEBUG: Missing gw_action ===" -ForegroundColor Cyan

$body3 = @{
    gw_workspace_id = $workspaceId
} | ConvertTo-Json -Depth 5

Write-Host "Request body:" -ForegroundColor Gray
Write-Host $body3

try {
    $response3 = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $body3 -UseBasicParsing
    Write-Host "`nHTTP Status: $($response3.StatusCode)" -ForegroundColor Yellow
    Write-Host "Raw Content:" -ForegroundColor Yellow
    Write-Host $response3.Content
} catch {
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "HTTP Status: $errStatus" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Error Body: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    # Try to read response stream
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $errContent = $reader.ReadToEnd()
        Write-Host "Stream Content: $errContent" -ForegroundColor Red
    } catch {
        Write-Host "Could not read response stream" -ForegroundColor DarkRed
    }
}
