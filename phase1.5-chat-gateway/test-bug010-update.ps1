# BUG-010 Test: artifact.update
# Tests if artifact.update actually modifies the journal entry_text

$url = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$user = "qwrk-gateway"
$pass = Read-Host -Prompt "Password"
$bytes = [System.Text.Encoding]::ASCII.GetBytes("${user}:${pass}")
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $base64" }

$body = @'
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
  "artifact_type": "journal",
  "artifact_id": "da0a6c2b-9bf6-43be-b183-4f86aeee918b",
  "extension": {
    "entry_text": "UPDATED via artifact.update - BUG-010 test"
  }
}
'@

Write-Host "Sending artifact.update request..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body -ContentType "application/json"
Write-Host "Response:" -ForegroundColor Green
$response | ConvertTo-Json -Depth 10
