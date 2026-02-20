# Strict JSON validation using .NET
$path = 'c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Gateway_v1 (50).json'
$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
Write-Output "File length: $($raw.Length) chars"
Write-Output "First 3 chars: $($raw.Substring(0,3))"
Write-Output "Last 3 chars: $($raw.Substring($raw.Length - 3))"

try {
    [System.Text.Json.JsonDocument]::Parse($raw) | Out-Null
    Write-Output "System.Text.Json: VALID"
} catch {
    Write-Output "System.Text.Json: INVALID - $_"
}

# Also check the specific Normalize_Request jsCode for valid JS string escaping
$json = $raw | ConvertFrom-Json
$normalizeNode = $json.nodes | Where-Object { $_.name -eq 'NQxb_Gateway_v1__Normalize_Request' }
$code = $normalizeNode.parameters.jsCode

# Check for the transition/reason lines
if ($code -match 'transition: raw\.transition') {
    Write-Output "transition passthrough: FOUND"
} else {
    Write-Output "transition passthrough: MISSING"
}
if ($code -match 'reason: raw\.reason') {
    Write-Output "reason passthrough: FOUND"
} else {
    Write-Output "reason passthrough: MISSING"
}

# Check the jsCode can be embedded back
$testJson = @{ test = $code } | ConvertTo-Json -Depth 1
try {
    $testJson | ConvertFrom-Json | Out-Null
    Write-Output "jsCode round-trip: VALID"
} catch {
    Write-Output "jsCode round-trip: INVALID - $_"
}
