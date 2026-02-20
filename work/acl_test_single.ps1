# Single test against clone endpoint
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type"  = "application/json"
}

$body = '{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":1}}'

$url = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/acl-test"

Write-Host "URL: $url"
Write-Host "Body: $body"
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $url -Method POST -Body $body -Headers $headers -UseBasicParsing
    Write-Host "HTTP Status: $($response.StatusCode)"
    Write-Host "Response:"
    Write-Host $response.Content
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
    Write-Host "HTTP Status: $statusCode"
    Write-Host "Error Body: '$errorBody'"
    Write-Host "Exception: $($_.Exception.Message)"
}
