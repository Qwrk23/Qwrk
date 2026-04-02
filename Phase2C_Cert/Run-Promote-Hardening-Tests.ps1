$ErrorActionPreference = 'Continue'
$gatewayUrl = 'https://n8n.halosparkai.com/webhook/nqxb/gateway/v2'
$cred = "qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))
$headers = @{ Authorization = "Basic $b64" }
$ws = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'

# Known IDs from Phase 2C cert run (PROJECT is now sapling, JOURNAL exists)
$PROJECT_ID = 'c6cf3de6-6f85-4c56-b652-5a79ccf7b3c3'
$JOURNAL_ID = 'c8490002-d21a-42b0-9bb7-3c7500f15138'

$tests = @(
  @{ name='C01 Invalid Transition'; payload=@{gw_action='artifact.promote';workspace_id=$ws;artifact_type='project';artifact_id=$PROJECT_ID;transition='seed_to_tree';reason='Hardening verification -- invalid transition'} },
  @{ name='C02 Missing Transition'; payload=@{gw_action='artifact.promote';workspace_id=$ws;artifact_type='project';artifact_id=$PROJECT_ID;reason='Hardening verification -- missing transition'} },
  @{ name='C03 Missing Reason'; payload=@{gw_action='artifact.promote';workspace_id=$ws;artifact_type='project';artifact_id=$PROJECT_ID;transition='seed_to_sapling'} },
  @{ name='C04 Lifecycle Mismatch'; payload=@{gw_action='artifact.promote';workspace_id=$ws;artifact_type='project';artifact_id=$PROJECT_ID;transition='seed_to_sapling';reason='Hardening verification -- lifecycle mismatch'} },
  @{ name='C05 Non-Promotable Type'; payload=@{gw_action='artifact.promote';workspace_id=$ws;artifact_type='journal';artifact_id=$JOURNAL_ID;transition='seed_to_sapling';reason='Hardening verification -- journal promote'} }
)

$resultsDir = Join-Path $PSScriptRoot 'results' 'raw'

foreach ($t in $tests) {
  $body = $t.payload | ConvertTo-Json -Depth 10
  $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  try {
    $resp = Invoke-WebRequest -Uri $gatewayUrl -Method POST -Headers $headers -Body $bodyBytes -ContentType 'application/json; charset=utf-8' -UseBasicParsing
    $json = $resp.Content | ConvertFrom-Json
    $ok = $json.ok
    $code = if ($json.error) { $json.error.code } else { 'none' }
    $msg = if ($json.error) { $json.error.message } else { '' }
    Write-Output ("{0} | ok={1} | code={2} | msg={3}" -f $t.name, $ok, $code, $msg)
    # Save raw response
    $safeName = ($t.name -replace '[^a-zA-Z0-9]','_')
    $resp.Content | Out-File -FilePath (Join-Path $resultsDir "$safeName.json") -Encoding utf8
  } catch {
    $status = $_.Exception.Response.StatusCode.value__
    try {
      $stream = $_.Exception.Response.GetResponseStream()
      $reader = New-Object System.IO.StreamReader($stream)
      $errBody = $reader.ReadToEnd()
    } catch {
      $errBody = 'unreadable'
    }
    Write-Output ("{0} | HTTP {1} | body={2}" -f $t.name, $status, $errBody)
    # Save error response
    $safeName = ($t.name -replace '[^a-zA-Z0-9]','_')
    $errBody | Out-File -FilePath (Join-Path $resultsDir "$safeName.json") -Encoding utf8
  }
}
