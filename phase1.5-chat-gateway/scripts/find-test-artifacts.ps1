$jsonFile = "C:\Users\j_bla\.claude\projects\C--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\6746a0cf-f751-47a2-813e-c1735f2a0932\tool-results\toolu_01BxrcirMbF2cqq9zFzn8L3Y.txt"
$content = Get-Content $jsonFile -Raw
# Remove the first two lines (Querying: and URL:)
$content = $content -replace "(?s)^Querying:.*?\[", "["
$content = $content -replace "Rows returned: \d+", ""
$artifacts = $content | ConvertFrom-Json

$testPatterns = @(
    "test", "Test", "TEST",
    "canary", "CANARY",
    "placeholder", "Placeholder",
    "smoke", "Smoke",
    "BUG-",
    "Kernel Validation",
    "Chunk Test",
    "Summary Workaround",
    "Tag Test",
    "IP Test",
    "Boot Anchor",
    "Session Boot",
    "Promote Test"
)

$testArtifacts = $artifacts | Where-Object {
    $title = $_.title
    $match = $false
    foreach ($pattern in $testPatterns) {
        if ($title -like "*$pattern*") { $match = $true; break }
    }
    $match
}

Write-Host "Found $($testArtifacts.Count) test artifacts:`n"
$testArtifacts | ForEach-Object {
    Write-Host "$($_.artifact_id)`t$($_.artifact_type.PadRight(16))`t$($_.title)"
}
