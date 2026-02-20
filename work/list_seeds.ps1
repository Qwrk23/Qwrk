$json = Get-Content 'C:\Users\j_bla\.claude\projects\c--Users-j-bla-OneDrive-AAA-QwrkX-new-qwrk-kernel\335997e3-b7b1-48db-b426-38dfae2eb91c\tool-results\toolu_013vNKbyrL3jio6vkGLdEsMK.txt' -Raw | ConvertFrom-Json
$json.data.artifacts | Where-Object { $_.lifecycle_status -in @('seed', 'sapling') } | ForEach-Object {
    [PSCustomObject]@{
        ID = $_.artifact_id.Substring(0,8)
        Title = $_.title
        Stage = $_.lifecycle_status
        Summary = if ($_.summary) { $_.summary.Substring(0, [Math]::Min(60, $_.summary.Length)) + "..." } else { "(no summary)" }
    }
} | Format-Table -AutoSize -Wrap
