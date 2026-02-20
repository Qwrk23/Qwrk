$raw = Get-Content 'C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\36e31ec3-5270-4dc0-80f3-abae6cd2a5be\tool-results\toolu_01FnNeFNe7aXwkWcgd4Wew3k.txt' -Raw
$json = $raw | ConvertFrom-Json
$artifacts = $json.data.artifacts

# Filter to only those tagged 'for-q'
$forQ = $artifacts | Where-Object { $_.tags -contains 'for-q' }

Write-Host "Total artifacts in response: $($artifacts.Count)"
Write-Host "Artifacts with for-q tag: $($forQ.Count)"
Write-Host ""

$knownIds = @(
  '041f678e-81e1-467f-af25-5bd922daace7',
  'a59311c2-d388-4224-aab6-b1cb9d60e431',
  '6159fea4-bcc7-4654-928b-ab22b4b46f16',
  'b753a85e-3aea-4aa2-8b97-eed9132c310d',
  '0bf89bec-fd2c-4969-ae3f-0aea08203dbf',
  '8b98f42d-5200-417f-bcfe-f57392bc9bdb',
  '120812e8-690f-426d-a9b1-4aeae81e225d',
  '13dfa8fb-c9fc-4942-87a5-7ad9455d2a2d',
  '271046d8-5f5c-412f-8e1e-7c471c0621a2',
  'a45705ec-0746-4a5e-8546-086a6428913b',
  '6b0b1bf4-76e4-4baf-b2eb-5af044fb4b01',
  '687c4439-b15e-4ba9-8b06-00b1b6246438',
  'a52f402e-1b07-4e6e-bb44-a3bb776f87af'
)

$excludedIds = @(
  'bedd7c67-91c1-4490-9c79-dbf90bf04d76'
)

$allKnown = $knownIds + $excludedIds

Write-Host "=== ALL for-q ARTIFACTS ==="
foreach ($a in $forQ) {
  $status = if ($allKnown -contains $a.artifact_id) { 'KNOWN' } else { '** NEW **' }
  Write-Host "$status  $($a.artifact_id)  $($a.title)"
}

Write-Host ""
Write-Host "=== DELTA (NEW artifact_ids not in known list) ==="
$newOnes = $forQ | Where-Object { $allKnown -notcontains $_.artifact_id }
if ($null -eq $newOnes -or @($newOnes).Count -eq 0) {
  Write-Host "No new for-q artifacts found."
} else {
  $newArr = @($newOnes)
  Write-Host "Found $($newArr.Count) new for-q artifact(s):"
  Write-Host ""
  foreach ($n in $newArr) {
    Write-Host "  artifact_id: $($n.artifact_id)"
    Write-Host "  title:       $($n.title)"
    Write-Host "  tags:        $($n.tags -join ', ')"
    Write-Host "  created_at:  $($n.created_at)"
    Write-Host ""
  }
}
