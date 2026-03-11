param([string]$OutPath)
$content = Get-Content -Raw $PSScriptRoot\promote_diff_template.js
Write-Output $content
