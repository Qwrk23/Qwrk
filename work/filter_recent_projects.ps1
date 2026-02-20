$json = Get-Content 'C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\edbc35ef-bf18-47ba-83f0-eb7b9f17f097\tool-results\toolu_016hSfsHHRJUCNi59iFZAC1y.txt' -Raw | ConvertFrom-Json
$cutoff = (Get-Date).AddHours(-24)
$recent = $json.data.artifacts | Where-Object { [datetime]$_.created_at -gt $cutoff }

Write-Host "Projects created in last 24 hours:" -ForegroundColor Cyan
Write-Host "Cutoff: $cutoff" -ForegroundColor DarkGray
Write-Host ""

foreach ($p in $recent) {
    Write-Host "$($p.artifact_id)" -ForegroundColor Yellow
    Write-Host "  Title: $($p.title)"
    Write-Host "  Status: $($p.lifecycle_status)"
    Write-Host "  Tags: $($p.tags -join ', ')"
    Write-Host "  Created: $($p.created_at)"
    Write-Host "  Parent: $($p.parent_artifact_id)"
    Write-Host ""
}

Write-Host "Total: $($recent.Count) projects" -ForegroundColor Green
