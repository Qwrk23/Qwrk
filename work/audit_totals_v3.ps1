$types = @('project','journal','snapshot','restart','branch','leaf','instruction_pack','limb')
foreach ($t in $types) {
    try {
        $raw = & powershell -File 'scripts/CC-Gateway-Query.ps1' -Action list -ArtifactType $t -Limit 200 -Raw 2>$null
        $jsonStr = $raw -join ""
        $obj = $jsonStr | ConvertFrom-Json -ErrorAction Stop
        if ($obj.ok -eq $true) {
            $c = $obj.meta.count
            $hm = $obj.meta.has_more
            Write-Output "${t}: ${c} (has_more=${hm})"
        } else {
            Write-Output "${t}: GW_ERR"
        }
    } catch {
        Write-Output "${t}: PARSE_ERR"
    }
}
