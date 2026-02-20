$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}
$body = '{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"69ea3ebe-84dc-4ff0-a354-1103f7a92595","artifact_type":"project","content":{"chunks":["CHUNK_1","CHUNK_2: This is the appended second chunk."]}}'
$response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" -Method POST -Body $body -ContentType "application/json" -Headers $headers
$response | ConvertTo-Json -Depth 10
