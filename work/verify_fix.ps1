$json = Get-Content 'c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Gateway_v1 (50).json' -Raw | ConvertFrom-Json
$normalizeNode = $json.nodes | Where-Object { $_.name -eq 'NQxb_Gateway_v1__Normalize_Request' }
$code = $normalizeNode.parameters.jsCode
$lines = $code -split "`n"
$i = 0
foreach ($line in $lines) {
    $i++
    if ($line -match 'selector|transition|reason|_gw_debug') {
        Write-Output "${i}: $($line.Trim())"
    }
}
