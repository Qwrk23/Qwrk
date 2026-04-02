# Direct test against clone endpoint
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type"  = "application/json"
}

$body = '{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":1}}'

Write-Host "Credential (first 20 chars of base64): $($credential.Substring(0,20))..."
Write-Host "URL: https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
Write-Host "Body: $body"
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" -Method POST -Body $body -Headers $headers -UseBasicParsing
    Write-Host "SUCCESS - Status: $($response.StatusCode)"
    Write-Host "Body: $($response.Content)"
}
catch {
    $statusCode = 0
    $errorBody = ""
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errorBody = $reader.ReadToEnd()
            $reader.Close()
        } catch {}
    }
    Write-Host "ERROR - Status: $statusCode"
    Write-Host "Error Body: '$errorBody'"
    Write-Host "Exception: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "--- Now testing production for comparison ---"
try {
    $response2 = Invoke-WebRequest -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" -Method POST -Body $body -Headers $headers -UseBasicParsing
    Write-Host "PRODUCTION - Status: $($response2.StatusCode)"
    Write-Host "Body (first 100): $($response2.Content.Substring(0, [Math]::Min(100, $response2.Content.Length)))"
}
catch {
    Write-Host "PRODUCTION ERROR - $($_.Exception.Message)"
}
