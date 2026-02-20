# Verbose ACL test — capture response body with multiple methods
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$cloneUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/acl-test"

# --- Test 3 first (allowed workspace, should be 200 with body) ---
Write-Host "=== TEST 3: Allowed Workspace ==="
Write-Host ""

$body = '{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":1}}'

# Method 1: Invoke-RestMethod (auto-parses JSON)
Write-Host "--- Method: Invoke-RestMethod ---"
try {
    $result = Invoke-RestMethod -Uri $cloneUrl -Method POST -Body $body -Headers @{
        "Authorization" = "Basic $credential"
        "Content-Type" = "application/json"
    }
    Write-Host "Result type: $($result.GetType().Name)"
    Write-Host "Result: $(ConvertTo-Json $result -Depth 5)"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) {
        Write-Host "ErrorDetails: $($_.ErrorDetails.Message)"
    }
}

Write-Host ""
Write-Host "=== TEST 1: Disallowed Workspace ==="
Write-Host ""

$body2 = '{"gw_action":"artifact.list","gw_workspace_id":"00000000-0000-0000-0000-000000000000","artifact_type":"project","selector":{"limit":3}}'

Write-Host "--- Method: Invoke-RestMethod ---"
try {
    $result2 = Invoke-RestMethod -Uri $cloneUrl -Method POST -Body $body2 -Headers @{
        "Authorization" = "Basic $credential"
        "Content-Type" = "application/json"
    }
    Write-Host "Result type: $($result2.GetType().Name)"
    Write-Host "Result: $(ConvertTo-Json $result2 -Depth 5)"
} catch {
    Write-Host "HTTP Error caught"
    if ($_.ErrorDetails.Message) {
        Write-Host "ErrorDetails.Message: $($_.ErrorDetails.Message)"
    }
    if ($_.Exception.Response) {
        Write-Host "Status: $([int]$_.Exception.Response.StatusCode)"
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errBody = $reader.ReadToEnd()
            $reader.Close()
            Write-Host "Stream body: '$errBody'"
        } catch {
            Write-Host "Could not read stream"
        }
    }
}
