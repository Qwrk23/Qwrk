# Temporary extraction script for for-q artifacts
$basePath = "C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\d0c6a6b9-3345-4229-b8d6-6036e51fd951\tool-results"

$files = @(
    "$basePath\bd5i15bjc.txt",  # snapshots p1
    "$basePath\blqc5x5bq.txt",  # snapshots p2
    "$basePath\b1ykuxq13.txt",  # snapshots p3
    "$basePath\b78aesi7m.txt"   # journals
)

$allArtifacts = @()

foreach ($f in $files) {
    if (Test-Path $f) {
        $json = Get-Content $f -Raw | ConvertFrom-Json
        foreach ($a in $json.data.artifacts) {
            $allArtifacts += [PSCustomObject]@{
                artifact_id = $a.artifact_id
                artifact_type = $a.artifact_type
                title = $a.title
                priority = $a.priority
                tags = ($a.tags -join ", ")
                created_at = $a.created_at
                lifecycle_status = $a.lifecycle_status
            }
        }
    }
}

# Sort by created_at ascending
$allArtifacts = $allArtifacts | Sort-Object created_at

Write-Host "=== COUNTS ==="
Write-Host "Snapshots: $( ($allArtifacts | Where-Object { $_.artifact_type -eq 'snapshot' }).Count )"
Write-Host "Journals: $( ($allArtifacts | Where-Object { $_.artifact_type -eq 'journal' }).Count )"
Write-Host ""
Write-Host "=== ALL ARTIFACTS (sorted by created_at ASC) ==="
Write-Host ""

foreach ($a in $allArtifacts) {
    $date = $a.created_at.Substring(0, 10)
    Write-Host "$($a.artifact_id)|$($a.artifact_type)|$($a.title)|$($a.priority)|$date|$($a.lifecycle_status)|$($a.tags)"
}
