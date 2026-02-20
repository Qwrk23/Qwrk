$data = Get-Content 'C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\00d980f2-7c5f-48db-ad3f-41556c04c41f\tool-results\toolu_011XTjR3KhzsDjgpKdQ5Ef6o.txt' -Raw | ConvertFrom-Json

$filtered = $data.data.artifacts | Where-Object {
    $_.created_at -ge '2026-02-15' -and $_.created_at -lt '2026-02-17'
}

Write-Output "=== FOR-Q SNAPSHOTS FROM 2026-02-15/16 ==="
Write-Output "Count: $($filtered.Count)"
Write-Output ""

foreach ($a in $filtered) {
    $pid8 = if ($a.parent_artifact_id) { $a.parent_artifact_id.Substring(0,8) } else { '-' }
    Write-Output "ID: $($a.artifact_id.Substring(0,8))  |  $($a.created_at.Substring(0,10))  |  Parent: $pid8"
    Write-Output "   Title: $($a.title)"
    Write-Output "   Tags: $($a.tags -join ', ')"
    Write-Output ""
}
