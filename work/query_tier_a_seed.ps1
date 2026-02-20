$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}

# List projects to find the Tier A Memory Compaction seed
$body = '{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","limit":50}'
$response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" -Method POST -Body $body -ContentType "application/json" -Headers $headers
$response | ConvertTo-Json -Depth 10
