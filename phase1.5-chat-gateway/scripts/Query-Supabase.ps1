<#
.SYNOPSIS
    Query Supabase REST API (PostgREST) with RLS enforcement.

.DESCRIPTION
    Reads credentials from .env.supabase and queries the specified table.
    Uses anon key only - RLS policies enforce workspace scoping.

.PARAMETER Table
    The table name to query (e.g., "qxb_artifact")

.PARAMETER Select
    Columns to return, comma-separated (e.g., "artifact_id,title,artifact_type")

.PARAMETER Filter
    PostgREST filter (e.g., "artifact_type=eq.journal")

.PARAMETER Order
    Order by clause (e.g., "created_at.desc")

.PARAMETER Limit
    Maximum rows to return (default: 100)

.PARAMETER Offset
    Rows to skip for pagination (default: 0)

.PARAMETER Raw
    Return raw JSON instead of PowerShell objects

.EXAMPLE
    .\Query-Supabase.ps1 -Table "qxb_artifact" -Select "artifact_id,title" -Limit 10

.EXAMPLE
    .\Query-Supabase.ps1 -Table "qxb_artifact" -Filter "artifact_type=eq.journal" -Order "created_at.desc" -Limit 5
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Table,

    [string]$Select = "*",

    [string]$Filter = "",

    [string]$Order = "",

    [int]$Limit = 100,

    [int]$Offset = 0,

    [switch]$Raw
)

# Configuration file path (project root)
$envFile = Join-Path $PSScriptRoot "..\..\.env.supabase"

# Read configuration
if (-not (Test-Path $envFile)) {
    Write-Error "Configuration file not found: $envFile"
    Write-Error "Please create .env.supabase with SUPABASE_URL and SUPABASE_ANON_KEY"
    exit 1
}

$config = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^([^=]+)=(.*)$") {
        $config[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$supabaseUrl = $config["SUPABASE_URL"]
$anonKey = $config["SUPABASE_ANON_KEY"]

if (-not $supabaseUrl -or -not $anonKey) {
    Write-Error "Missing SUPABASE_URL or SUPABASE_ANON_KEY in $envFile"
    exit 1
}

# Build query URL
$queryParams = @()
$queryParams += "select=$Select"
$queryParams += "limit=$Limit"
$queryParams += "offset=$Offset"

if ($Filter) {
    $queryParams += $Filter
}

if ($Order) {
    $queryParams += "order=$Order"
}

$queryString = $queryParams -join "&"
$url = "$supabaseUrl/rest/v1/$Table`?$queryString"

# Headers
$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Execute query
try {
    Write-Host "Querying: $Table" -ForegroundColor Cyan
    Write-Host "URL: $url" -ForegroundColor DarkGray

    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers

    if ($Raw) {
        $response | ConvertTo-Json -Depth 10
    } else {
        $response
    }

    Write-Host "`nRows returned: $($response.Count)" -ForegroundColor Green
}
catch {
    Write-Error "Query failed: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
