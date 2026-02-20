# T24 Step 2 — ACL Validation Test Runner
# Tests fail-closed ACL behavior on clone Gateway endpoint
# Usage: powershell -File "work/acl_test_runner.ps1" -Test <1|3|all>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("1","3","all")]
    [string]$Test
)

$baseUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/acl-test"
$base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

function Invoke-GatewayTest {
    param(
        [string]$TestName,
        [string]$Payload,
        [int]$ExpectedStatus
    )

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "TEST: $TestName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Payload: $Payload"
    Write-Host "Expected HTTP Status: $ExpectedStatus"
    Write-Host "----------------------------------------"

    try {
        $response = Invoke-WebRequest -Uri $baseUrl -Method POST -Body $Payload -Headers $headers -UseBasicParsing
        $statusCode = $response.StatusCode
        $body = $response.Content
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        $reader.Close()
    }

    Write-Host "HTTP Status: $statusCode"

    # Pretty-print JSON
    try {
        $parsed = $body | ConvertFrom-Json
        $pretty = $parsed | ConvertTo-Json -Depth 10
        Write-Host "Response Body:"
        Write-Host $pretty
    }
    catch {
        Write-Host "Response Body (raw): $body"
    }

    # Determine pass/fail
    $pass = ($statusCode -eq $ExpectedStatus)
    if ($pass) {
        Write-Host "`nRESULT: PASS" -ForegroundColor Green
    }
    else {
        Write-Host "`nRESULT: FAIL (expected $ExpectedStatus, got $statusCode)" -ForegroundColor Red
    }

    return @{
        TestName = $TestName
        StatusCode = $statusCode
        ExpectedStatus = $ExpectedStatus
        Pass = $pass
        Body = $body
    }
}

$results = @()

# ---- TEST 1: Disallowed Workspace ----
if ($Test -eq "1" -or $Test -eq "all") {
    $payload1 = @{
        gw_action = "artifact.list"
        gw_workspace_id = "00000000-0000-0000-0000-000000000000"
        artifact_type = "project"
        selector = @{ limit = 3 }
    } | ConvertTo-Json -Compress

    $results += Invoke-GatewayTest -TestName "Test 1 - Disallowed Workspace" -Payload $payload1 -ExpectedStatus 403
}

# ---- TEST 3: Allowed Workspace (Control) ----
if ($Test -eq "3" -or $Test -eq "all") {
    $payload3 = @{
        gw_action = "artifact.list"
        gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
        artifact_type = "project"
        selector = @{ limit = 3 }
    } | ConvertTo-Json -Compress

    $results += Invoke-GatewayTest -TestName "Test 3 - Allowed Workspace (Control)" -Payload $payload3 -ExpectedStatus 200
}

# ---- SUMMARY ----
Write-Host "`n`n========================================" -ForegroundColor Yellow
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

foreach ($r in $results) {
    $status = if ($r.Pass) { "PASS" } else { "FAIL" }
    $color = if ($r.Pass) { "Green" } else { "Red" }
    Write-Host "$($r.TestName): $status (HTTP $($r.StatusCode))" -ForegroundColor $color
}
