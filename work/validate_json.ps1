try {
    $raw = Get-Content 'c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Gateway_v1 (50).json' -Raw
    $parsed = $raw | ConvertFrom-Json
    Write-Output "JSON VALID"
    Write-Output "Nodes: $($parsed.nodes.Count)"
    Write-Output "Node names:"
    foreach ($node in $parsed.nodes) {
        Write-Output "  - $($node.name)"
    }
} catch {
    Write-Output "JSON INVALID: $_"
}
