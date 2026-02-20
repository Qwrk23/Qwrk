$types = @('project','journal','snapshot','restart','branch','leaf','grass','thorn','instruction_pack','limb')
foreach ($t in $types) {
    $raw = & powershell -File 'scripts/CC-Gateway-Query.ps1' -Action list -ArtifactType $t -Limit 1 -Raw 2>$null
    $result = $raw | ConvertFrom-Json
    if ($result.ok) {
        Write-Output "$t : $($result.meta.count)"
    } else {
        Write-Output "$t : ERROR"
    }
}
