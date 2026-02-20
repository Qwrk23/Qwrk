# Find the exact bytes around the transition/reason insertion
$path = 'c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Gateway_v1 (50).json'
$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Find 'transition' in the raw text (first occurrence should be in Normalize_Request jsCode)
$idx = $raw.IndexOf('transition: raw.transition')
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 100)
    $end = [Math]::Min($raw.Length, $idx + 150)
    $context = $raw.Substring($start, $end - $start)
    Write-Output "Found at char $idx"
    Write-Output "Context (escaped view):"
    Write-Output $context
    Write-Output ""
    Write-Output "--- Hex around edit point ---"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw.Substring($idx - 20, 80))
    $hex = ($bytes | ForEach-Object { '{0:x2}' -f $_ }) -join ' '
    Write-Output $hex
} else {
    Write-Output "NOT FOUND in raw text"
}

# Also check: does the v49 archived file parse with n8n-expected structure?
Write-Output ""
Write-Output "--- Top-level keys ---"
$json = $raw | ConvertFrom-Json
$json.PSObject.Properties | ForEach-Object { Write-Output "$($_.Name): $($_.TypeNameOfValue)" }
