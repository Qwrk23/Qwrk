$raw = & powershell -File 'scripts/CC-Gateway-Query.ps1' -Action list -ArtifactType project -Limit 100 -Raw 2>$null
$result = $raw | ConvertFrom-Json
Write-Output "Total projects: $($result.meta.count)"
Write-Output ""
$groups = $result.data.artifacts | Group-Object -Property lifecycle_status
foreach ($g in $groups) {
    Write-Output "lifecycle_status=$($g.Name): $($g.Count)"
}
Write-Output ""
Write-Output "--- All projects ---"
foreach ($a in $result.data.artifacts) {
    $id = $a.artifact_id.Substring(0,8)
    $title = if ($a.title.Length -gt 60) { $a.title.Substring(0,60) + "..." } else { $a.title }
    $ls = if ($a.lifecycle_status) { $a.lifecycle_status } else { "NULL" }
    $created = $a.created_at.Substring(0,10)
    Write-Output "$id | $ls | $created | $title"
}
