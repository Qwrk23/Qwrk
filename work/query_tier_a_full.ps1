$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}

# Query the Tier A Memory Compaction seed with hydrate
Write-Host "=== Seed: Tier A Memory Compaction ===" -ForegroundColor Cyan
$body1 = '{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"d05341ed-997d-4015-ae0d-7537e783fa6d","artifact_type":"project","hydrate":true}'
$response1 = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" -Method POST -Body $body1 -ContentType "application/json" -Headers $headers
$response1 | ConvertTo-Json -Depth 10
