$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}

# Query session snapshot
Write-Host "=== Session Snapshot (1a68cc0a-30d1-4b3f-893d-02777ac84a56) ===" -ForegroundColor Cyan
$body1 = '{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"1a68cc0a-30d1-4b3f-893d-02777ac84a56","artifact_type":"snapshot","hydrate":true}'
$response1 = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" -Method POST -Body $body1 -ContentType "application/json" -Headers $headers
$response1 | ConvertTo-Json -Depth 10

# Query T15 completion snapshot
Write-Host "`n=== T15 Completion Snapshot (a45705ec-0746-4a5e-8546-086a6428913b) ===" -ForegroundColor Cyan
$body2 = '{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"a45705ec-0746-4a5e-8546-086a6428913b","artifact_type":"snapshot","hydrate":true}'
$response2 = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" -Method POST -Body $body2 -ContentType "application/json" -Headers $headers
$response2 | ConvertTo-Json -Depth 10
