#Requires -Version 5.1
<#
.SYNOPSIS
    Qwrk Gateway v1 Test Harness
.DESCRIPTION
    PowerShell test harness for Gateway v1 regression testing.
    Provides invoker functions for all 5 KGB-locked actions.
.VERSION
    1.0.0
.DATE
    2026-01-24
#>

#region === CONFIGURATION ===

# Script-level state
$script:QwrkGatewayBaseUrl = $null
$script:QwrkAuthHeader = $null
$script:QwrkWorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$script:QwrkInitialized = $false

# Known-Good Test IDs
$script:KnownIds = @{
    project         = "668bd18f-4424-41e6-b2f9-393ecd2ec534"
    journal         = "db428a32-1afa-4e6b-a649-347b0bffd46c"
    snapshot        = "610e16d1-c5bb-468c-bd35-57eadf9f2e38"
    restart         = "ac1d6294-2bd7-4a9d-823e-827562b56e26"
    instruction_pack = "f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779"
    project_promote = "e9601873-9f71-4843-bd81-9ecaccbbf9e3"
}

#endregion

#region === INITIALIZATION ===

function Get-QwrkGatewayBaseUrl {
    <#
    .SYNOPSIS
        Gets or prompts for Gateway base URL
    #>
    if ($env:QWRK_GATEWAY_BASEURL) {
        return $env:QWRK_GATEWAY_BASEURL
    }

    if ($script:QwrkGatewayBaseUrl) {
        return $script:QwrkGatewayBaseUrl
    }

    $url = Read-Host "Enter Gateway base URL (e.g., https://n8n.halosparkai.com/webhook)"
    $script:QwrkGatewayBaseUrl = $url.TrimEnd('/')
    return $script:QwrkGatewayBaseUrl
}

function New-QwrkBasicAuthHeader {
    <#
    .SYNOPSIS
        Creates Basic Auth header from secure password input or environment variable
    .NOTES
        Non-interactive mode: Set $env:QWRK_GATEWAY_PASSWORD before running
    #>
    param(
        [string]$Username = "qwrk-gateway"
    )

    $password = $null

    # Check for non-interactive mode (environment variable)
    if ($env:QWRK_GATEWAY_PASSWORD) {
        $password = $env:QWRK_GATEWAY_PASSWORD
        Write-Host "Auth: Using password from environment variable" -ForegroundColor Gray
    }
    else {
        # Interactive mode
        Write-Host "Enter Gateway password for user '$Username':" -ForegroundColor Cyan
        $securePassword = Read-Host -AsSecureString

        # Convert SecureString to plain text for Base64 encoding
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    $pair = "${Username}:${password}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)

    return @{
        Authorization = "Basic $base64"
        "Content-Type" = "application/json"
    }
}

function Initialize-QwrkGateway {
    <#
    .SYNOPSIS
        Initializes the test harness (call once per session)
    .DESCRIPTION
        Interactive mode: Prompts for base URL and password
        Non-interactive mode: Set these environment variables:
          - $env:QWRK_GATEWAY_BASEURL (e.g., "https://n8n.halosparkai.com/webhook")
          - $env:QWRK_GATEWAY_PASSWORD (Gateway Basic Auth password)
    .EXAMPLE
        Initialize-QwrkGateway
    .EXAMPLE
        # Non-interactive (env vars pre-set)
        $env:QWRK_GATEWAY_BASEURL = "https://n8n.halosparkai.com/webhook"
        $env:QWRK_GATEWAY_PASSWORD = "secret"
        Initialize-QwrkGateway
    #>
    param(
        [switch]$Quiet
    )

    if (-not $Quiet) {
        Write-Host "`n=== Qwrk Gateway Test Harness v1.0 ===" -ForegroundColor Green
        Write-Host "Initializing...`n" -ForegroundColor Gray
    }

    # Check for non-interactive mode
    $nonInteractive = ($env:QWRK_GATEWAY_BASEURL -and $env:QWRK_GATEWAY_PASSWORD)
    if ($nonInteractive -and -not $Quiet) {
        Write-Host "Mode: Non-interactive (using environment variables)" -ForegroundColor Cyan
    }

    # Get base URL
    $script:QwrkGatewayBaseUrl = Get-QwrkGatewayBaseUrl
    if (-not $Quiet) { Write-Host "Base URL: $($script:QwrkGatewayBaseUrl)" -ForegroundColor Gray }

    # Get auth header
    $script:QwrkAuthHeader = New-QwrkBasicAuthHeader
    if (-not $Quiet) { Write-Host "Auth: Configured" -ForegroundColor Gray }

    # Confirm workspace
    if (-not $Quiet) { Write-Host "Workspace: $($script:QwrkWorkspaceId)" -ForegroundColor Gray }

    $script:QwrkInitialized = $true
    if (-not $Quiet) { Write-Host "`nInitialization complete. Ready for tests.`n" -ForegroundColor Green }
}

function Assert-QwrkInitialized {
    if (-not $script:QwrkInitialized) {
        throw "Harness not initialized. Run Initialize-QwrkGateway first."
    }
}

#endregion

#region === CORE INVOKER ===

function Invoke-QwrkGateway {
    <#
    .SYNOPSIS
        Core Gateway invoker - sends request and prints receipts
    .PARAMETER Payload
        Hashtable payload to send
    .PARAMETER SaveReceipt
        Optional path to save receipt JSON
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Payload,

        [string]$SaveReceipt
    )

    Assert-QwrkInitialized

    $uri = "$($script:QwrkGatewayBaseUrl)/nqxb/gateway/v1"
    $json = $Payload | ConvertTo-Json -Depth 10

    # Print request
    Write-Host "`n--- REQUEST ---" -ForegroundColor Yellow
    Write-Host "POST $uri" -ForegroundColor Gray
    Write-Host $json -ForegroundColor White

    try {
        $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $script:QwrkAuthHeader -Body $json -ErrorAction Stop
        $responseJson = $response | ConvertTo-Json -Depth 10

        # Print response
        Write-Host "`n--- RESPONSE ---" -ForegroundColor Yellow
        if ($response.ok -eq $true) {
            Write-Host $responseJson -ForegroundColor Green
        } else {
            Write-Host $responseJson -ForegroundColor Red
        }

        # Save receipt if requested
        if ($SaveReceipt) {
            $receipt = @{
                timestamp = (Get-Date -Format "o")
                request = $Payload
                response = $response
            }
            $receipt | ConvertTo-Json -Depth 10 | Set-Content $SaveReceipt
            Write-Host "`nReceipt saved: $SaveReceipt" -ForegroundColor Gray
        }

        return $response
    }
    catch {
        Write-Host "`n--- ERROR ---" -ForegroundColor Red
        Write-Host "HTTP Error: $($_.Exception.Message)" -ForegroundColor Red

        # Try to get error body
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error Body: $errorBody" -ForegroundColor Red
        }

        return @{ ok = $false; error = @{ code = "HTTP_ERROR"; message = $_.Exception.Message } }
    }
}

#endregion

#region === ACTION WRAPPERS ===

function Invoke-QwrkQuery {
    <#
    .SYNOPSIS
        Invokes artifact.query
    .EXAMPLE
        Invoke-QwrkQuery -ArtifactType "project" -ArtifactId "668bd18f-4424-41e6-b2f9-393ecd2ec534"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactType,

        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [hashtable]$Selector,

        [string]$WorkspaceId = $script:QwrkWorkspaceId,

        [string]$SaveReceipt
    )

    $payload = @{
        gw_action = "artifact.query"
        gw_workspace_id = $WorkspaceId
        artifact_type = $ArtifactType
        artifact_id = $ArtifactId
    }

    if ($Selector) {
        $payload.selector = $Selector
    }

    return Invoke-QwrkGateway -Payload $payload -SaveReceipt $SaveReceipt
}

function Invoke-QwrkList {
    <#
    .SYNOPSIS
        Invokes artifact.list
    .EXAMPLE
        Invoke-QwrkList -ArtifactType "project" -Limit 10
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactType,

        [int]$Limit,

        [int]$Offset,

        [bool]$Hydrate,

        [string]$AsOf,

        [string]$WorkspaceId = $script:QwrkWorkspaceId,

        [string]$SaveReceipt
    )

    $payload = @{
        gw_action = "artifact.list"
        gw_workspace_id = $WorkspaceId
        artifact_type = $ArtifactType
    }

    $selector = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $selector.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $selector.offset = $Offset }
    if ($PSBoundParameters.ContainsKey('Hydrate')) { $selector.hydrate = $Hydrate }
    if ($AsOf) { $selector.as_of = $AsOf }

    if ($selector.Count -gt 0) {
        $payload.selector = $selector
    }

    return Invoke-QwrkGateway -Payload $payload -SaveReceipt $SaveReceipt
}

function Invoke-QwrkSave {
    <#
    .SYNOPSIS
        Invokes artifact.save (CREATE ONLY)
    .EXAMPLE
        Invoke-QwrkSave -ArtifactType "project" -Title "Test" -Extension @{lifecycle_stage="seed"}
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactType,

        [Parameter(Mandatory)]
        [string]$Title,

        [string]$Summary,

        [array]$Tags,

        [hashtable]$Content,

        [string]$ParentArtifactId,

        [int]$Priority = 3,

        [string]$LifecycleStatus,

        [hashtable]$Extension,

        [string]$WorkspaceId = $script:QwrkWorkspaceId,

        [string]$SaveReceipt
    )

    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $WorkspaceId
        artifact_type = $ArtifactType
        title = $Title
        priority = $Priority
    }

    if ($Summary) { $payload.summary = $Summary }
    if ($Tags) { $payload.tags = $Tags }
    if ($Content) { $payload.content = $Content }
    if ($ParentArtifactId) { $payload.parent_artifact_id = $ParentArtifactId }
    if ($LifecycleStatus) { $payload.lifecycle_status = $LifecycleStatus }
    if ($Extension) { $payload.extension = $Extension }

    return Invoke-QwrkGateway -Payload $payload -SaveReceipt $SaveReceipt
}

function Invoke-QwrkUpdate {
    <#
    .SYNOPSIS
        Invokes artifact.update
    .EXAMPLE
        Invoke-QwrkUpdate -ArtifactType "project" -ArtifactId "..." -Extension @{operational_state="paused"}
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactType,

        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [hashtable]$Extension,

        [string]$WorkspaceId = $script:QwrkWorkspaceId,

        [string]$SaveReceipt
    )

    $payload = @{
        gw_action = "artifact.update"
        gw_workspace_id = $WorkspaceId
        artifact_type = $ArtifactType
        artifact_id = $ArtifactId
        extension = $Extension
    }

    return Invoke-QwrkGateway -Payload $payload -SaveReceipt $SaveReceipt
}

function Invoke-QwrkPromote {
    <#
    .SYNOPSIS
        Invokes artifact.promote
    .EXAMPLE
        Invoke-QwrkPromote -ArtifactId "..." -Transition "seed_to_sapling" -Reason "Ready"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Transition,

        [string]$Reason,

        [string]$ArtifactType = "project",

        [string]$WorkspaceId = $script:QwrkWorkspaceId,

        [string]$SaveReceipt
    )

    $payload = @{
        gw_action = "artifact.promote"
        gw_workspace_id = $WorkspaceId
        artifact_type = $ArtifactType
        artifact_id = $ArtifactId
        transition = $Transition
    }

    if ($Reason) { $payload.reason = $Reason }

    return Invoke-QwrkGateway -Payload $payload -SaveReceipt $SaveReceipt
}

#endregion

#region === TEST SUITES ===

function Invoke-QwrkQueryTests {
    <#
    .SYNOPSIS
        Runs all artifact.query tests
    #>
    Write-Host "`n========== QUERY TESTS ==========" -ForegroundColor Cyan

    $results = @()

    # Q1: Query project (happy path)
    Write-Host "`n[Q1] Query project (known ID)" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "project" -ArtifactId $script:KnownIds.project
    $results += @{ id = "Q1"; pass = ($r.ok -eq $true) }

    # Q2: Query journal (happy path)
    Write-Host "`n[Q2] Query journal (known ID)" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "journal" -ArtifactId $script:KnownIds.journal
    $results += @{ id = "Q2"; pass = ($r.ok -eq $true) }

    # Q3: Query snapshot (happy path)
    Write-Host "`n[Q3] Query snapshot (known ID)" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "snapshot" -ArtifactId $script:KnownIds.snapshot
    $results += @{ id = "Q3"; pass = ($r.ok -eq $true) }

    # Q4: Query restart (happy path)
    Write-Host "`n[Q4] Query restart (known ID)" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "restart" -ArtifactId $script:KnownIds.restart
    $results += @{ id = "Q4"; pass = ($r.ok -eq $true) }

    # Q5: Query instruction_pack (happy path)
    Write-Host "`n[Q5] Query instruction_pack (known ID)" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "instruction_pack" -ArtifactId $script:KnownIds.instruction_pack
    $results += @{ id = "Q5"; pass = ($r.ok -eq $true) }

    # Q6: TYPE_MISMATCH (query project ID as journal)
    Write-Host "`n[Q6] TYPE_MISMATCH test" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "journal" -ArtifactId $script:KnownIds.project
    $results += @{ id = "Q6"; pass = ($r.error.code -eq "TYPE_MISMATCH") }

    # Q7: NOT_FOUND (non-existent ID)
    Write-Host "`n[Q7] NOT_FOUND test" -ForegroundColor White
    $r = Invoke-QwrkQuery -ArtifactType "project" -ArtifactId "00000000-0000-0000-0000-000000000000"
    $results += @{ id = "Q7"; pass = ($r.error.code -eq "NOT_FOUND" -or $r.ok -eq $false) }

    # Summary
    Write-Host "`n--- Query Test Summary ---" -ForegroundColor Cyan
    $passed = ($results | Where-Object { $_.pass }).Count
    $total = $results.Count
    Write-Host "Passed: $passed / $total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

    return $results
}

function Invoke-QwrkListTests {
    <#
    .SYNOPSIS
        Runs all artifact.list tests
    #>
    Write-Host "`n========== LIST TESTS ==========" -ForegroundColor Cyan

    $results = @()

    # L1: List projects (default)
    Write-Host "`n[L1] List projects (default)" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "project"
    $results += @{ id = "L1"; pass = ($r.ok -eq $true) }

    # L2: List projects with limit
    Write-Host "`n[L2] List projects (limit=5)" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "project" -Limit 5
    $results += @{ id = "L2"; pass = ($r.ok -eq $true) }

    # L3: List projects with offset
    Write-Host "`n[L3] List projects (offset=1)" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "project" -Offset 1
    $results += @{ id = "L3"; pass = ($r.ok -eq $true) }

    # L4: List projects hydrated
    Write-Host "`n[L4] List projects (hydrate=true)" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "project" -Hydrate $true
    $results += @{ id = "L4"; pass = ($r.ok -eq $true) }

    # L5: List projects spine only
    Write-Host "`n[L5] List projects (hydrate=false)" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "project" -Hydrate $false
    $results += @{ id = "L5"; pass = ($r.ok -eq $true) }

    # L6: List instruction_packs
    Write-Host "`n[L6] List instruction_packs" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "instruction_pack"
    $results += @{ id = "L6"; pass = ($r.ok -eq $true) }

    # L7: List instruction_packs with pagination
    Write-Host "`n[L7] List instruction_packs (limit=10, offset=0)" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "instruction_pack" -Limit 10 -Offset 0
    $results += @{ id = "L7"; pass = ($r.ok -eq $true) }

    # L8: List journals
    Write-Host "`n[L8] List journals" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "journal"
    $results += @{ id = "L8"; pass = ($r.ok -eq $true) }

    # L9: List snapshots
    Write-Host "`n[L9] List snapshots" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "snapshot"
    $results += @{ id = "L9"; pass = ($r.ok -eq $true) }

    # L10: List restarts
    Write-Host "`n[L10] List restarts" -ForegroundColor White
    $r = Invoke-QwrkList -ArtifactType "restart"
    $results += @{ id = "L10"; pass = ($r.ok -eq $true) }

    # Summary
    Write-Host "`n--- List Test Summary ---" -ForegroundColor Cyan
    $passed = ($results | Where-Object { $_.pass }).Count
    $total = $results.Count
    Write-Host "Passed: $passed / $total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

    return $results
}

function Invoke-QwrkSaveTests {
    <#
    .SYNOPSIS
        Runs all artifact.save tests
    #>
    Write-Host "`n========== SAVE TESTS ==========" -ForegroundColor Cyan

    $results = @()
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # S1: Save project (happy path)
    Write-Host "`n[S1] Save project" -ForegroundColor White
    $r = Invoke-QwrkSave -ArtifactType "project" `
        -Title "Test Project $timestamp" `
        -Summary "Created by Gateway Test Harness" `
        -Tags @("test", "harness") `
        -LifecycleStatus "seed" `
        -Extension @{ lifecycle_stage = "seed"; operational_state = "active" }
    $results += @{ id = "S1"; pass = ($r.ok -eq $true); artifact_id = $r.data.artifact_id }
    if ($r.ok) { Write-Host "Created artifact_id: $($r.data.artifact_id)" -ForegroundColor Green }

    # S2: Save journal
    Write-Host "`n[S2] Save journal" -ForegroundColor White
    $r = Invoke-QwrkSave -ArtifactType "journal" `
        -Title "Test Journal $timestamp" `
        -Summary "Test journal entry" `
        -Extension @{ entry_text = "Test entry from harness"; payload = @{} }
    $results += @{ id = "S2"; pass = ($r.ok -eq $true); artifact_id = $r.data.artifact_id }
    if ($r.ok) { Write-Host "Created artifact_id: $($r.data.artifact_id)" -ForegroundColor Green }

    # S3: Save snapshot
    Write-Host "`n[S3] Save snapshot" -ForegroundColor White
    $r = Invoke-QwrkSave -ArtifactType "snapshot" `
        -Title "Test Snapshot $timestamp" `
        -Summary "Test snapshot" `
        -Extension @{ payload = @{ test = "data"; timestamp = $timestamp } }
    $results += @{ id = "S3"; pass = ($r.ok -eq $true); artifact_id = $r.data.artifact_id }
    if ($r.ok) { Write-Host "Created artifact_id: $($r.data.artifact_id)" -ForegroundColor Green }

    # S4: Save restart
    Write-Host "`n[S4] Save restart" -ForegroundColor White
    $r = Invoke-QwrkSave -ArtifactType "restart" `
        -Title "Test Restart $timestamp" `
        -Summary "Test restart prompt" `
        -Extension @{ payload = @{ context = "test"; next_step = "continue" } }
    $results += @{ id = "S4"; pass = ($r.ok -eq $true); artifact_id = $r.data.artifact_id }
    if ($r.ok) { Write-Host "Created artifact_id: $($r.data.artifact_id)" -ForegroundColor Green }

    # S5: Save instruction_pack (may fail if extension table missing)
    Write-Host "`n[S5] Save instruction_pack" -ForegroundColor White
    $r = Invoke-QwrkSave -ArtifactType "instruction_pack" `
        -Title "Test Instruction Pack $timestamp" `
        -Summary "Test pack" `
        -Content @{ pack_version = "1.0"; scope = "global"; rules = @{} }
    $results += @{ id = "S5"; pass = ($r.ok -eq $true); artifact_id = $r.data.artifact_id }
    if ($r.ok) { Write-Host "Created artifact_id: $($r.data.artifact_id)" -ForegroundColor Green }

    # S6: Nil UUID artifact_id is ignored (treated as no artifact_id = INSERT)
    # Design decision: Nil UUIDs are not valid artifact references, so save proceeds as INSERT
    Write-Host "`n[S6] Nil UUID artifact_id behavior (ignored, proceeds as INSERT)" -ForegroundColor White
    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $script:QwrkWorkspaceId
        artifact_type = "project"
        artifact_id = "00000000-0000-0000-0000-000000000000"
        title = "Nil UUID test - should INSERT"
        extension = @{ lifecycle_stage = "seed" }
    }
    $r = Invoke-QwrkGateway -Payload $payload
    # Nil UUID is ignored, INSERT proceeds, ok: true expected
    $results += @{ id = "S6"; pass = ($r.ok -eq $true -and $r.operation -eq "INSERT") }

    # S7: VALIDATION_ERROR - missing title
    Write-Host "`n[S7] VALIDATION_ERROR test (missing title)" -ForegroundColor White
    $payload = @{
        gw_action = "artifact.save"
        gw_workspace_id = $script:QwrkWorkspaceId
        artifact_type = "project"
        extension = @{ lifecycle_stage = "seed" }
    }
    $r = Invoke-QwrkGateway -Payload $payload
    $results += @{ id = "S7"; pass = ($r.ok -eq $false) }

    # S9: ARTIFACT_TYPE_NOT_ALLOWED - invalid type
    Write-Host "`n[S9] ARTIFACT_TYPE_NOT_ALLOWED test" -ForegroundColor White
    $r = Invoke-QwrkSave -ArtifactType "invalid_fake_type" `
        -Title "Should fail" `
        -Extension @{}
    $results += @{ id = "S9"; pass = ($r.ok -eq $false -and $r.error.code -eq "ARTIFACT_TYPE_NOT_ALLOWED") }

    # Summary
    Write-Host "`n--- Save Test Summary ---" -ForegroundColor Cyan
    $passed = ($results | Where-Object { $_.pass }).Count
    $total = $results.Count
    Write-Host "Passed: $passed / $total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

    # Report created IDs
    Write-Host "`n--- Created Artifacts ---" -ForegroundColor Cyan
    $results | Where-Object { $_.artifact_id } | ForEach-Object {
        Write-Host "$($_.id): $($_.artifact_id)"
    }

    return $results
}

function Invoke-QwrkUpdateTests {
    <#
    .SYNOPSIS
        Runs all artifact.update tests
    #>
    Write-Host "`n========== UPDATE TESTS ==========" -ForegroundColor Cyan

    $results = @()

    # U1: Update project operational_state
    Write-Host "`n[U1] Update project operational_state" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "project" `
        -ArtifactId $script:KnownIds.project `
        -Extension @{ operational_state = "active" }
    $results += @{ id = "U1"; pass = ($r.ok -eq $true) }

    # U2: Update project state_reason
    Write-Host "`n[U2] Update project state_reason" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "project" `
        -ArtifactId $script:KnownIds.project `
        -Extension @{ state_reason = "Updated by test harness" }
    $results += @{ id = "U2"; pass = ($r.ok -eq $true) }

    # U3: IMMUTABILITY_ERROR - lifecycle_stage via update
    Write-Host "`n[U3] IMMUTABILITY_ERROR test (lifecycle_stage)" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "project" `
        -ArtifactId $script:KnownIds.project `
        -Extension @{ lifecycle_stage = "tree" }
    $results += @{ id = "U3"; pass = ($r.ok -eq $false) }

    # U4: IMMUTABILITY_ERROR - update snapshot
    Write-Host "`n[U4] IMMUTABILITY_ERROR test (snapshot)" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "snapshot" `
        -ArtifactId $script:KnownIds.snapshot `
        -Extension @{ payload = @{ test = "should fail" } }
    $results += @{ id = "U4"; pass = ($r.ok -eq $false) }

    # U5: IMMUTABILITY_ERROR - update restart
    Write-Host "`n[U5] IMMUTABILITY_ERROR test (restart)" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "restart" `
        -ArtifactId $script:KnownIds.restart `
        -Extension @{ payload = @{ test = "should fail" } }
    $results += @{ id = "U5"; pass = ($r.ok -eq $false) }

    # U6: IMMUTABILITY_ERROR - update journal
    Write-Host "`n[U6] IMMUTABILITY_ERROR test (journal)" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "journal" `
        -ArtifactId $script:KnownIds.journal `
        -Extension @{ entry_text = "should fail" }
    $results += @{ id = "U6"; pass = ($r.ok -eq $false) }

    # U7: NOT_FOUND - non-existent ID
    Write-Host "`n[U7] NOT_FOUND test" -ForegroundColor White
    $r = Invoke-QwrkUpdate -ArtifactType "project" `
        -ArtifactId "00000000-0000-0000-0000-000000000000" `
        -Extension @{ operational_state = "active" }
    $results += @{ id = "U7"; pass = ($r.ok -eq $false) }

    # Summary
    Write-Host "`n--- Update Test Summary ---" -ForegroundColor Cyan
    $passed = ($results | Where-Object { $_.pass }).Count
    $total = $results.Count
    Write-Host "Passed: $passed / $total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

    return $results
}

function Invoke-QwrkPromoteTests {
    <#
    .SYNOPSIS
        Runs artifact.promote tests
    .NOTES
        Promote tests are stateful - they change lifecycle.
        Run with caution or use test artifacts.
    #>
    Write-Host "`n========== PROMOTE TESTS ==========" -ForegroundColor Cyan
    Write-Host "NOTE: Promote tests modify artifact state. Use test artifacts." -ForegroundColor Yellow

    $results = @()

    # First, create a fresh project in seed state for testing
    Write-Host "`n[P0] Creating test project for promote tests..." -ForegroundColor White
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $createResult = Invoke-QwrkSave -ArtifactType "project" `
        -Title "Promote Test $timestamp" `
        -Summary "Created for promote testing" `
        -LifecycleStatus "seed" `
        -Extension @{ lifecycle_stage = "seed"; operational_state = "active" }

    if (-not $createResult.ok) {
        Write-Host "Failed to create test project. Skipping promote tests." -ForegroundColor Red
        return @()
    }

    $testProjectId = $createResult.artifact_id
    Write-Host "Test project created: $testProjectId" -ForegroundColor Green

    # P1: seed_to_sapling (valid)
    Write-Host "`n[P1] Promote seed_to_sapling" -ForegroundColor White
    $r = Invoke-QwrkPromote -ArtifactId $testProjectId `
        -Transition "seed_to_sapling" `
        -Reason "Test promotion"
    $results += @{ id = "P1"; pass = ($r.ok -eq $true) }

    # P4: Repeat same transition (should fail)
    Write-Host "`n[P4] LIFECYCLE_STATE_MISMATCH test (repeat transition)" -ForegroundColor White
    $r = Invoke-QwrkPromote -ArtifactId $testProjectId `
        -Transition "seed_to_sapling" `
        -Reason "Should fail - already sapling"
    $results += @{ id = "P4"; pass = ($r.ok -eq $false) }

    # P2: sapling_to_tree (valid, continues from P1)
    Write-Host "`n[P2] Promote sapling_to_tree" -ForegroundColor White
    $r = Invoke-QwrkPromote -ArtifactId $testProjectId `
        -Transition "sapling_to_tree" `
        -Reason "Test promotion to tree"
    $results += @{ id = "P2"; pass = ($r.ok -eq $true) }

    # P5: ACTION_NOT_ALLOWED - promote snapshot
    Write-Host "`n[P5] ACTION_NOT_ALLOWED test (snapshot)" -ForegroundColor White
    $r = Invoke-QwrkPromote -ArtifactId $script:KnownIds.snapshot `
        -ArtifactType "snapshot" `
        -Transition "seed_to_sapling"
    $results += @{ id = "P5"; pass = ($r.ok -eq $false) }

    # P7: Invalid transition key
    Write-Host "`n[P7] LIFECYCLE_TRANSITION_NOT_ALLOWED test (invalid key)" -ForegroundColor White
    $freshProject = Invoke-QwrkSave -ArtifactType "project" `
        -Title "Promote Test Invalid $timestamp" `
        -LifecycleStatus "seed" `
        -Extension @{ lifecycle_stage = "seed"; operational_state = "active" }
    if ($freshProject.ok) {
        $r = Invoke-QwrkPromote -ArtifactId $freshProject.artifact_id `
            -Transition "invalid_transition_key"
        $results += @{ id = "P7"; pass = ($r.ok -eq $false) }
    }

    # Summary
    Write-Host "`n--- Promote Test Summary ---" -ForegroundColor Cyan
    $passed = ($results | Where-Object { $_.pass }).Count
    $total = $results.Count
    Write-Host "Passed: $passed / $total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

    return $results
}

function Invoke-QwrkAllTests {
    <#
    .SYNOPSIS
        Runs all test suites
    #>
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "   QWRK GATEWAY v1 FULL TEST SUITE         " -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan

    $allResults = @{
        query = Invoke-QwrkQueryTests
        list = Invoke-QwrkListTests
        save = Invoke-QwrkSaveTests
        update = Invoke-QwrkUpdateTests
        promote = Invoke-QwrkPromoteTests
    }

    # Final summary
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "           FINAL SUMMARY                   " -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan

    $totalPassed = 0
    $totalTests = 0

    foreach ($suite in $allResults.Keys) {
        $passed = ($allResults[$suite] | Where-Object { $_.pass }).Count
        $total = $allResults[$suite].Count
        $totalPassed += $passed
        $totalTests += $total
        $color = if ($passed -eq $total) { "Green" } else { "Yellow" }
        Write-Host "$($suite.ToUpper()): $passed / $total" -ForegroundColor $color
    }

    Write-Host "-------------------------------------------" -ForegroundColor Gray
    $finalColor = if ($totalPassed -eq $totalTests) { "Green" } else { "Red" }
    Write-Host "TOTAL: $totalPassed / $totalTests" -ForegroundColor $finalColor

    if ($totalPassed -eq $totalTests) {
        Write-Host "`nALL TESTS PASSED" -ForegroundColor Green
    } else {
        Write-Host "`nSOME TESTS FAILED - Review output above" -ForegroundColor Red
    }

    return $allResults
}

#endregion

#region === UTILITY FUNCTIONS ===

function Save-QwrkTestReceipt {
    <#
    .SYNOPSIS
        Saves test results to a receipt file
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Results,

        [string]$Operator = $env:USERNAME,

        [string]$OutputPath
    )

    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $OutputPath = "docs/testing/receipts/${timestamp}__Gateway_Test_Run__${Operator}.json"
    }

    # Ensure directory exists
    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $receipt = @{
        run_id = (Get-Date -Format "o")
        operator = $Operator
        harness_version = "1.0"
        results = $Results
        summary = @{
            total = 0
            passed = 0
            failed = 0
        }
    }

    # Calculate summary
    foreach ($suite in $Results.Keys) {
        $receipt.summary.total += $Results[$suite].Count
        $receipt.summary.passed += ($Results[$suite] | Where-Object { $_.pass }).Count
    }
    $receipt.summary.failed = $receipt.summary.total - $receipt.summary.passed

    $receipt | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
    Write-Host "Receipt saved: $OutputPath" -ForegroundColor Green

    return $OutputPath
}

function Get-QwrkKnownIds {
    <#
    .SYNOPSIS
        Returns known-good test IDs
    #>
    return $script:KnownIds
}

#endregion

# Export functions
Export-ModuleMember -Function * -Variable KnownIds 2>$null

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "         Qwrk Gateway Test Harness v1.0 Loaded              " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Run: Initialize-QwrkGateway    (required first)           " -ForegroundColor Cyan
Write-Host "  Run: Invoke-QwrkAllTests       (full suite)               " -ForegroundColor Cyan
Write-Host "  Run: Invoke-QwrkQueryTests     (query only)               " -ForegroundColor Cyan
Write-Host "  Run: Get-QwrkKnownIds          (show test IDs)            " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  NON-INTERACTIVE: Set env vars before Initialize           " -ForegroundColor Gray
Write-Host "    QWRK_GATEWAY_BASEURL, QWRK_GATEWAY_PASSWORD              " -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
