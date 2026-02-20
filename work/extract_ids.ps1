$raw = Get-Content 'C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\a2a48958-46a6-4fd1-a4a4-d372ad5dff5d\tool-results\toolu_01ACb1G7miTGdMHiTPwSPtEq.txt' -Raw
$json = $raw | ConvertFrom-Json
$ids = $json.data.artifacts | ForEach-Object { $_.artifact_id }
Write-Output "Total: $($ids.Count)"
$ids | ForEach-Object { Write-Output $_ }
