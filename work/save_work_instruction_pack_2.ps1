# Save instruction_pack #2 via Work clone gateway
# Write override authorized by Joel

$webhookUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/work"
$principal = "qwrk-gw-work"
$password = "ufwpjNF0PEMq4R92ST6zKQM5eeVs7BnM"

$pair = "${principal}:${password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json; charset=utf-8"
}

$body = @"
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "instruction_pack",
  "title": "Instruction Pack - Qwrk@Work Execution Patterns v1",
  "priority": 3,
  "tags": ["instruction-pack", "execution", "lifecycle", "work", "v1"],
  "extension": {
    "scope": "Execution structure and lifecycle discipline for Qwrk@Work",
    "active": true,
    "priority": 1,
    "pack_format": "v1",
    "payload": {
      "version": "v1",
      "authority": "Immutable. Superseded only by future version.",
      "notes": "See canvas document for full structured content reference."
    }
  }
}
"@

Write-Host "=== SAVE: Instruction Pack #2 (Execution Patterns) ===" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -UseBasicParsing
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
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
