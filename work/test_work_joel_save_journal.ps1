# Smoke test: Save a journal + query it via Work_Joel clone

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

# --- SAVE ---
Write-Host "=== SAVE: Journal Smoke Test ===" -ForegroundColor Cyan

$saveBody = @{
    gw_action       = "artifact.save"
    gw_workspace_id = "635bb8d7-7b93-4bea-8ca6-ee2c924c9557"
    artifact_type   = "journal"
    title           = "Work Clone Smoke Test - Journal"
    priority        = 3
    tags            = @("smoke-test", "work-clone")
    extension       = @{
        entry_text = "This is a journal smoke test for the Qwrk@Work gateway clone."
    }
} | ConvertTo-Json -Depth 5

$artifactId = $null

try {
    $saveResponse = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $saveBody -UseBasicParsing
    Write-Host "HTTP Status: $($saveResponse.StatusCode)" -ForegroundColor Yellow
    Write-Host "Response:" -ForegroundColor Yellow
    Write-Host $saveResponse.Content

    $saveJson = $saveResponse.Content | ConvertFrom-Json
    if ($saveJson.ok -eq $true -and $saveJson.artifact_id) {
        $artifactId = $saveJson.artifact_id
        Write-Host "`nSaved artifact_id: $artifactId" -ForegroundColor Green
    }
} catch {
    $errStatus = $_.Exception.Response.StatusCode.value__
    Write-Host "SAVE FAILED - HTTP $errStatus" -ForegroundColor Red
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Body: $($reader.ReadToEnd())" -ForegroundColor Red
    } catch {}
    exit 1
}

# --- QUERY ---
if ($artifactId) {
    Write-Host "`n=== QUERY: Retrieve saved journal ===" -ForegroundColor Cyan

    $queryBody = @{
        gw_action       = "artifact.query"
        gw_workspace_id = "635bb8d7-7b93-4bea-8ca6-ee2c924c9557"
        artifact_type   = "journal"
        artifact_id     = $artifactId
    } | ConvertTo-Json -Depth 5

    try {
        $queryResponse = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body $queryBody -UseBasicParsing
        Write-Host "HTTP Status: $($queryResponse.StatusCode)" -ForegroundColor Yellow
        Write-Host "Response:" -ForegroundColor Yellow
        Write-Host $queryResponse.Content
    } catch {
        $errStatus = $_.Exception.Response.StatusCode.value__
        Write-Host "QUERY FAILED - HTTP $errStatus" -ForegroundColor Red
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            Write-Host "Body: $($reader.ReadToEnd())" -ForegroundColor Red
        } catch {}
    }
} else {
    Write-Host "Skipping query - no artifact_id from save" -ForegroundColor Red
}
