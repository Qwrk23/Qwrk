$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\docs\testing\Qwrk.Gateway.TestHarness.ps1",
    [ref]$tokens,
    [ref]$errors
)
if ($errors.Count -gt 0) {
    Write-Host "SYNTAX ERRORS FOUND:" -ForegroundColor Red
    foreach ($e in $errors) {
        Write-Host "  Line $($e.Extent.StartLineNumber): $($e.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "No syntax errors found." -ForegroundColor Green
}
