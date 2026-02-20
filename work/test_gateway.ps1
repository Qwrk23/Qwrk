$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}
$body = '{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","owner_user_id":"7097c16c-ed88-4e49-983f-1de80e5cfcea","artifact_type":"project","title":"Chunk Test Project","content":{"chunks":["CHUNK_1"]},"extension":{"lifecycle_stage":"seed"}}'
$response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" -Method POST -Body $body -ContentType "application/json" -Headers $headers
$response | ConvertTo-Json -Depth 10
