# T112 Filter Validation Tests
param([string]$Test = "all")

$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{ "Authorization" = "Basic $credential"; "Content-Type" = "application/json" }

function Run-Test {
    param([string]$Name, [string]$Json, [string]$Expect)
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    Write-Host "PAYLOAD: $Json" -ForegroundColor DarkGray
    try {
        $resp = Invoke-RestMethod -Uri $gatewayUrl -Method Post -Headers $headers -Body $Json -ErrorAction Stop
        $out = $resp | ConvertTo-Json -Depth 10
        if ($Expect -eq "error" -and $resp.ok -eq $false) { Write-Host "PASS" -ForegroundColor Green }
        elseif ($Expect -eq "ok" -and $resp.ok -eq $true) { Write-Host "PASS" -ForegroundColor Green }
        else { Write-Host "FAIL - Expected $Expect" -ForegroundColor Red }
        Write-Host $out
    } catch { Write-Host "HTTP ERROR: $_" -ForegroundColor Red }
}

# F1: Valid lifecycle_status
if ($Test -eq "all" -or $Test -eq "F1") {
    $body = '{"gw_action":"artifact.list","gw_workspace_id":"' + $workspaceId + '","artifact_type":"project","selector":{"limit":3,"filters":{"lifecycle_status":"seed"}}}'
    Run-Test -Name "F1: Valid lifecycle_status=seed" -Json $body -Expect "ok"
}

# F4: Invalid lifecycle_status
if ($Test -eq "all" -or $Test -eq "F4") {
    $body = '{"gw_action":"artifact.list","gw_workspace_id":"' + $workspaceId + '","artifact_type":"project","selector":{"limit":3,"filters":{"lifecycle_status":"invalid_status"}}}'
    Run-Test -Name "F4: Invalid lifecycle_status=invalid_status" -Json $body -Expect "error"
}

# F5: Invalid execution_status
if ($Test -eq "all" -or $Test -eq "F5") {
    $body = '{"gw_action":"artifact.list","gw_workspace_id":"' + $workspaceId + '","artifact_type":"project","selector":{"limit":3,"filters":{"execution_status":"bogus"}}}'
    Run-Test -Name "F5: Invalid execution_status=bogus" -Json $body -Expect "error"
}

# F1b: Valid execution_status
if ($Test -eq "all" -or $Test -eq "F1b") {
    $body = '{"gw_action":"artifact.list","gw_workspace_id":"' + $workspaceId + '","artifact_type":"project","selector":{"limit":3,"filters":{"execution_status":"in_progress"}}}'
    Run-Test -Name "F1b: Valid execution_status=in_progress" -Json $body -Expect "ok"
}
