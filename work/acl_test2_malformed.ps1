# T24 Step 2 - Test 2: Malformed ACL Endpoint (Fail-Closed Proof)
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$cloneUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/acl-test"

$body = '{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":1}}'

Write-Host "========================================"
Write-Host "TEST 2: Malformed ACL Endpoint"
Write-Host "========================================"
Write-Host "ACL_Lookup URL broken (/broken appended)"
Write-Host "Payload: allowed workspace (owner)"
Write-Host "Expected: HTTP 403, ACL_FORBIDDEN"
Write-Host "----------------------------------------"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $result = Invoke-RestMethod -Uri $cloneUrl -Method POST -Body $body -Headers @{
        "Authorization" = "Basic $credential"
        "Content-Type" = "application/json"
    }
    $stopwatch.Stop()
    Write-Host "HTTP Status: 200 (UNEXPECTED - request passed through)"
    Write-Host "Elapsed: $($stopwatch.ElapsedMilliseconds)ms"
    Write-Host "Response: $(ConvertTo-Json $result -Depth 5)"
    Write-Host ""
    Write-Host "RESULT: FAIL" -ForegroundColor Red
}
catch {
    $stopwatch.Stop()
    $statusCode = [int]$_.Exception.Response.StatusCode
    $errorBody = $_.ErrorDetails.Message

    Write-Host "HTTP Status: $statusCode"
    Write-Host "Elapsed: $($stopwatch.ElapsedMilliseconds)ms"

    if ($errorBody -and $errorBody.Length -gt 0) {
        $parsed = $errorBody | ConvertFrom-Json
        Write-Host "Response:"
        Write-Host (ConvertTo-Json $parsed -Depth 5)

        $isAclForbidden = ($parsed.error.code -eq "ACL_FORBIDDEN")
        $isDenied = ($parsed._acl_status -eq "denied")
        $noPassThrough = ($parsed.ok -eq $false)

        Write-Host ""
        if ($statusCode -eq 403 -and $isAclForbidden -and $isDenied -and $noPassThrough) {
            Write-Host "RESULT: PASS - Fail-closed confirmed" -ForegroundColor Green
            Write-Host "  HTTP 403: YES"
            Write-Host "  ACL_FORBIDDEN: YES"
            Write-Host "  _acl_status=denied: YES"
            Write-Host "  ok=false: YES"
            Write-Host "  No 500: YES"
            Write-Host "  No hang: YES ($($stopwatch.ElapsedMilliseconds)ms)"
        }
        else {
            Write-Host "RESULT: FAIL - Unexpected shape" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Response: (empty body)"
        if ($statusCode -eq 403) {
            Write-Host "RESULT: PARTIAL - Got 403 but no body" -ForegroundColor Yellow
        }
        elseif ($statusCode -eq 500) {
            Write-Host "RESULT: FAIL - Server error (not fail-closed)" -ForegroundColor Red
        }
        else {
            Write-Host "RESULT: FAIL - Unexpected status" -ForegroundColor Red
        }
    }
}
