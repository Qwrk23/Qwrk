# Paginate to get true totals
$types = @('project','journal','snapshot','restart','branch','leaf','instruction_pack','limb')
foreach ($t in $types) {
    $total = 0
    $offset = 0
    $hasMore = $true
    while ($hasMore) {
        try {
            $raw = & powershell -File 'scripts/CC-Gateway-Query.ps1' -Action list -ArtifactType $t -Limit 50 -Offset $offset -Raw 2>$null
            $jsonStr = $raw -join ""
            $obj = $jsonStr | ConvertFrom-Json -ErrorAction Stop
            if ($obj.ok -eq $true) {
                $total += $obj.meta.count
                $hasMore = $obj.meta.has_more
                $offset += 50
            } else {
                Write-Output "${t}: GW_ERR at offset $offset"
                $hasMore = $false
            }
        } catch {
            Write-Output "${t}: PARSE_ERR at offset $offset"
            $hasMore = $false
        }
    }
    Write-Output "${t}: TOTAL = ${total}"
}
