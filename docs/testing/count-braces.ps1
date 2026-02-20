$content = Get-Content "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\docs\testing\Qwrk.Gateway.TestHarness.ps1" -Raw
$open = ([regex]::Matches($content, '\{')).Count
$close = ([regex]::Matches($content, '\}')).Count
Write-Host "Opening braces: $open"
Write-Host "Closing braces: $close"
Write-Host "Difference: $($open - $close)"

# Find where imbalance occurs
$lineNum = 0
$depth = 0
foreach ($line in (Get-Content "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\docs\testing\Qwrk.Gateway.TestHarness.ps1")) {
    $lineNum++
    $lineOpen = ([regex]::Matches($line, '\{')).Count
    $lineClose = ([regex]::Matches($line, '\}')).Count
    $depth += $lineOpen - $lineClose
    if ($depth -lt 0) {
        Write-Host "Imbalance at line $lineNum (depth=$depth): $line"
    }
}
Write-Host "Final depth: $depth"
