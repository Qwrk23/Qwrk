# Temporary test runner - delete after use
param(
    [string]$Password,
    [string]$TestSuite = "Query"
)

$env:QWRK_GATEWAY_BASEURL = "https://n8n.halosparkai.com/webhook"
$env:QWRK_GATEWAY_PASSWORD = $Password

Set-Location "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
. .\docs\testing\Qwrk.Gateway.TestHarness.ps1

Initialize-QwrkGateway

switch ($TestSuite) {
    "Query"   { Invoke-QwrkQueryTests }
    "List"    { Invoke-QwrkListTests }
    "Save"    { Invoke-QwrkSaveTests }
    "Update"  { Invoke-QwrkUpdateTests }
    "Promote" { Invoke-QwrkPromoteTests }
    "All"     { Invoke-QwrkAllTests }
    default   { Invoke-QwrkQueryTests }
}
