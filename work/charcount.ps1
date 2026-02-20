$old = Get-Content "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\phase1.5-chat-gateway\Chat Project Files\Archive\Qwrk_SYSTEM_INSTRUCTIONS_2_5_28__v3__2026-02-17.md" -Raw
$new = Get-Content "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\phase1.5-chat-gateway\Chat Project Files\Qwrk_SYSTEM_INSTRUCTIONS_2_5_28.md" -Raw
$oldLF = $old -replace "`r`n", "`n"
$newLF = $new -replace "`r`n", "`n"
Write-Output "Old (v2_5_28.3): $($oldLF.Length) chars"
Write-Output "New (v2_5_29):   $($newLF.Length) chars"
Write-Output "Delta:           -$($oldLF.Length - $newLF.Length) chars"
Write-Output "Under 8000:      $(if ($newLF.Length -lt 8000) { 'YES' } else { 'NO (' + $newLF.Length + ')' })"
Write-Output "Lines old:       $(($old -split "`r?`n").Count)"
Write-Output "Lines new:       $(($new -split "`r?`n").Count)"
