<#
.SYNOPSIS
    Claude Code helper script for Gateway queries.

.DESCRIPTION
    Provides a simple interface for CC to query the Qwrk Gateway.
    Avoids escaping issues with inline PowerShell through Bash.

.PARAMETER Action
    Gateway action: "list" or "query"

.PARAMETER ArtifactType
    For query: REQUIRED. For list: optional filter.
    Valid types: project, journal, snapshot, restart, video, grass, thorn

.PARAMETER ArtifactId
    For query: specific artifact ID to retrieve

.PARAMETER Tags
    For list: comma-separated tags to filter by (e.g., "for-q,governance")

.PARAMETER Hydrate
    Include extension table data (default: false for list, true for query)

.PARAMETER Limit
    Maximum results for list (default: 20)

.PARAMETER Offset
    Pagination offset for list (default: 0)

.PARAMETER Raw
    Output raw JSON instead of formatted

.EXAMPLE
    .\CC-Gateway-Query.ps1 -Action list -ArtifactType snapshot -Tags "for-q" -Limit 10

.EXAMPLE
    .\CC-Gateway-Query.ps1 -Action query -ArtifactType snapshot -ArtifactId "6b0b1bf4-76e4-4baf-b2eb-5af044fb4b01" -Hydrate

.EXAMPLE
    .\CC-Gateway-Query.ps1 -Action list -ArtifactType project -Limit 5
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("list", "query")]
    [string]$Action,

    [string]$ArtifactType = "",

    [string]$ArtifactId = "",

    [string]$Tags = "",

    [switch]$Hydrate,

    [int]$Limit = 20,

    [int]$Offset = 0,

    [switch]$Raw
)

# Gateway configuration
$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type" = "application/json"
}

# Build request body based on action
if ($Action -eq "list") {
    $selector = @{
        limit = $Limit
        offset = $Offset
        hydrate = $Hydrate.IsPresent
    }

    if ($Tags) {
        $tagArray = @($Tags -split "," | ForEach-Object { $_.Trim() })
        $selector["filters"] = @{ tags_any = $tagArray }
    }

    $body = @{
        gw_action = "artifact.list"
        gw_workspace_id = $workspaceId
        selector = $selector
    }

    if ($ArtifactType) {
        $body["artifact_type"] = $ArtifactType
    }
}
elseif ($Action -eq "query") {
    if (-not $ArtifactId) {
        Write-Error "ArtifactId is required for query action"
        exit 1
    }
    if (-not $ArtifactType) {
        Write-Error "ArtifactType is required for query action (Gateway contract requirement)"
        exit 1
    }

    $body = @{
        gw_action = "artifact.query"
        gw_workspace_id = $workspaceId
        artifact_id = $ArtifactId
        artifact_type = $ArtifactType
        selector = @{
            hydrate = if ($PSBoundParameters.ContainsKey('Hydrate')) { $Hydrate.IsPresent } else { $true }
        }
    }
}

$jsonBody = $body | ConvertTo-Json -Depth 5

# Execute request
try {
    if (-not $Raw) {
        Write-Host "Gateway $Action..." -ForegroundColor Cyan
    }

    $response = Invoke-RestMethod -Uri $gatewayUrl -Method POST -Body $jsonBody -ContentType "application/json" -Headers $headers

    if ($Raw) {
        $response | ConvertTo-Json -Depth 10
    }
    else {
        # Format output based on action
        if ($Action -eq "list") {
            if ($response.ok -eq $true) {
                $artifacts = $response.data.artifacts
                Write-Host "Found $($artifacts.Count) artifacts" -ForegroundColor Green
                Write-Host ""

                foreach ($a in $artifacts) {
                    $tags = if ($a.tags) { ($a.tags -join ", ") } else { "-" }
                    Write-Host "$($a.artifact_id)" -ForegroundColor Yellow -NoNewline
                    Write-Host " | $($a.artifact_type) | " -NoNewline
                    Write-Host "$($a.title)" -ForegroundColor White
                    Write-Host "   Tags: $tags" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Host "Error: $($response.error.message)" -ForegroundColor Red
                $response | ConvertTo-Json -Depth 5
            }
        }
        elseif ($Action -eq "query") {
            # Gateway returns data.artifact for query responses
            $artifact = if ($response.data.artifact) { $response.data.artifact } elseif ($response.artifact) { $response.artifact } else { $null }
            if ($artifact) {
                $a = $artifact
                Write-Host "Artifact: $($a.title)" -ForegroundColor Green
                Write-Host "ID: $($a.artifact_id)" -ForegroundColor Yellow
                Write-Host "Type: $($a.artifact_type)"
                Write-Host "Tags: $(if ($a.tags) { $a.tags -join ', ' } else { '-' })"
                Write-Host "Created: $($a.created_at)"
                Write-Host ""

                # Show extension data if hydrated
                if ($a.extension -and $a.extension.payload) {
                    Write-Host "Payload:" -ForegroundColor Cyan
                    $a.extension.payload | ConvertTo-Json -Depth 5
                }
                elseif ($a.payload) {
                    Write-Host "Payload:" -ForegroundColor Cyan
                    $a.payload | ConvertTo-Json -Depth 5
                }
                elseif ($a.extension -and $a.extension.content) {
                    Write-Host "Content:" -ForegroundColor Cyan
                    $a.extension.content | ConvertTo-Json -Depth 5
                }
                elseif ($a.content -and $a.content.PSObject.Properties.Count -gt 0) {
                    Write-Host "Content:" -ForegroundColor Cyan
                    $a.content | ConvertTo-Json -Depth 5
                }
            }
            else {
                Write-Host "Error or not found:" -ForegroundColor Red
                $response | ConvertTo-Json -Depth 5
            }
        }
    }
}
catch {
    Write-Error "Gateway request failed: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
