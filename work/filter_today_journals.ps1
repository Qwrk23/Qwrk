$raw = Get-Content 'C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\40661477-10f9-480b-b13c-3674a325c258\tool-results\toolu_01U7rUHEqGagU8TcWCFcpHtJ.txt' -Raw
$j = ConvertFrom-Json $raw
$count = 0
foreach ($a in $j.data.artifacts) {
    if ($a.created_at -match '^2026-02-18') {
        $count++
        Write-Host "ID: $($a.artifact_id)"
        Write-Host "Title: $($a.title)"
        Write-Host "Tags: $($a.tags -join ', ')"
        Write-Host "Created: $($a.created_at)"
        Write-Host "Parent: $($a.parent_artifact_id)"
        Write-Host "---"
    }
}
Write-Host "Total today: $count"
