# T24 Step 2 — Full ACL Validation Suite
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type"  = "application/json"
}

$cloneUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/acl-test"

function Run-Test {
    param([string]$Name, [string]$Body, [int]$ExpectedStatus)

    Write-Host "`n========================================"
    Write-Host "TEST: $Name"
    Write-Host "========================================"
    Write-Host "Expected: HTTP $ExpectedStatus"

    try {
        $resp = Invoke-WebRequest -Uri $cloneUrl -Method POST -Body $Body -Headers $headers -UseBasicParsing
        $code = $resp.StatusCode
        $content = $resp.Content
    }
    catch {
        $code = [int]$_.Exception.Response.StatusCode
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $content = $reader.ReadToEnd()
            $reader.Close()
        } catch { $content = "(could not read)" }
    }

    Write-Host "Actual:   HTTP $code"
    Write-Host "Body length: $($content.Length) chars"

    if ($content.Length -gt 0) {
        try {
            $parsed = $content | ConvertFrom-Json | ConvertTo-Json -Depth 10
            Write-Host "Response:`n$parsed"
        } catch {
            Write-Host "Response (raw): $content"
        }
    } else {
        Write-Host "Response: (empty)"
    }

    $pass = ($code -eq $ExpectedStatus)
    if ($pass) { Write-Host "`nRESULT: PASS" -ForegroundColor Green }
    else { Write-Host "`nRESULT: FAIL (expected $ExpectedStatus, got $code)" -ForegroundColor Red }

    return @{ Name=$Name; Code=$code; Expected=$ExpectedStatus; Pass=$pass; Body=$content }
}

# ---- TEST 1: Disallowed Workspace ----
$r1 = Run-Test -Name "Test 1 - Disallowed Workspace" `
    -Body '{"gw_action":"artifact.list","gw_workspace_id":"00000000-0000-0000-0000-000000000000","artifact_type":"project","selector":{"limit":3}}' `
    -ExpectedStatus 403

# ---- TEST 3: Allowed Workspace (Control) ----
$r3 = Run-Test -Name "Test 3 - Allowed Workspace (Control)" `
    -Body '{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":1}}' `
    -ExpectedStatus 200

# ---- SUMMARY ----
Write-Host "`n========================================"
Write-Host "SUMMARY"
Write-Host "========================================"
foreach ($r in @($r1, $r3)) {
    $status = if ($r.Pass) { "PASS" } else { "FAIL" }
    Write-Host "$($r.Name): $status (HTTP $($r.Code))"
}
