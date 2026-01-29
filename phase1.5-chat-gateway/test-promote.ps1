# Test: artifact.promote
# Use the project we just created: 2a188c98-a85a-4bf6-8632-424574b23866

$url = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$user = "qwrk-gateway"
$pass = Read-Host -Prompt "Password"
$bytes = [System.Text.Encoding]::ASCII.GetBytes("${user}:${pass}")
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $base64" }

$body = @'
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
  "artifact_type": "project",
  "artifact_id": "2a188c98-a85a-4bf6-8632-424574b23866",
  "transition": "seed_to_sapling",
  "reason": "BUG-010 promote test"
}
'@

Write-Host "Promoting project from seed to sapling..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body -ContentType "application/json"
Write-Host "Response:" -ForegroundColor Green
$response | ConvertTo-Json -Depth 10
