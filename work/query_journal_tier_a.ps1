$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}

# Query the Tier A Memory Compaction companion journal with hydrate
$body = '{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"6f9c71d9-d345-409c-9ce8-24eec9ba72c4","artifact_type":"journal","hydrate":true}'
$response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2" -Method POST -Body $body -ContentType "application/json" -Headers $headers
$response | ConvertTo-Json -Depth 10
