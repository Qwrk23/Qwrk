$types = @('project','journal','snapshot','restart','branch','leaf','grass','thorn','instruction_pack','limb')
foreach ($t in $types) {
    try {
        $raw = & powershell -File 'scripts/CC-Gateway-Query.ps1' -Action list -ArtifactType $t -Limit 1 -Raw 2>$null
        $jsonStr = $raw -join "`n"
        $obj = $jsonStr | ConvertFrom-Json -ErrorAction Stop
        if ($obj.ok -eq $true) {
            $c = $obj.meta.count
            $hm = $obj.meta.has_more
            Write-Output "${t}: count=${c}, has_more=${hm}"
        } else {
            Write-Output "${t}: GATEWAY_ERROR"
        }
    } catch {
        Write-Output "${t}: PARSE_ERROR - $($_.Exception.Message)"
    }
}
