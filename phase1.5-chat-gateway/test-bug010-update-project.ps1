# BUG-010 Test: artifact.update on PROJECT
# Projects should allow lifecycle_stage updates

$url = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$user = "qwrk-gateway"
$pass = Read-Host -Prompt "Password"
$bytes = [System.Text.Encoding]::ASCII.GetBytes("${user}:${pass}")
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $base64" }

# First, create a test project
$createBody = @'
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
  "artifact_type": "project",
  "title": "BUG-010 Update Test Project",
  "content": {},
  "extension": {
    "lifecycle_stage": "seed"
  }
}
'@

Write-Host "Step 1: Creating test project..." -ForegroundColor Cyan
$createResponse = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $createBody -ContentType "application/json"
Write-Host "Create Response:" -ForegroundColor Green
$createResponse | ConvertTo-Json -Depth 10

# Extract artifact_id from response
$artifactId = $createResponse.data.artifact.artifact_id
if (-not $artifactId) {
    $artifactId = $createResponse.artifact_id
}

if ($artifactId) {
    Write-Host "`nStep 2: Updating project lifecycle_stage to 'sapling'..." -ForegroundColor Cyan

    $updateBody = @"
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
  "artifact_type": "project",
  "artifact_id": "$artifactId",
  "extension": {
    "lifecycle_stage": "sapling"
  }
}
"@

    $updateResponse = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $updateBody -ContentType "application/json"
    Write-Host "Update Response:" -ForegroundColor Green
    $updateResponse | ConvertTo-Json -Depth 10
} else {
    Write-Host "Could not extract artifact_id from create response" -ForegroundColor Red
}
