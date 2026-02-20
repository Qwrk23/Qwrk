<#
.SYNOPSIS
    Update Supabase records via REST API (PostgREST).

.DESCRIPTION
    Reads credentials from .env.supabase and updates records in the specified table.
    Uses anon key - RLS policies must allow updates for this to work.

.PARAMETER Table
    The table name (e.g., "qxb_artifact")

.PARAMETER Filter
    PostgREST filter to identify rows (e.g., "artifact_id=eq.abc123")

.PARAMETER Data
    Hashtable of fields to update

.EXAMPLE
    .\Update-Supabase.ps1 -Table "qxb_artifact" -Filter "artifact_id=eq.abc123" -Data @{deleted_at="2026-02-01T00:00:00Z"}
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Table,

    [Parameter(Mandatory=$true)]
    [string]$Filter,

    [Parameter(Mandatory=$true)]
    [hashtable]$Data
)

# Configuration file path (project root)
$envFile = Join-Path $PSScriptRoot "..\..\.env.supabase"

# Read configuration
if (-not (Test-Path $envFile)) {
    Write-Error "Configuration file not found: $envFile"
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

# Build URL
$url = "$supabaseUrl/rest/v1/$Table`?$Filter"

# Headers
$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Body
$body = $Data | ConvertTo-Json -Compress

# Execute update
try {
    Write-Host "Updating: $Table" -ForegroundColor Cyan
    Write-Host "Filter: $Filter" -ForegroundColor DarkGray
    Write-Host "Data: $body" -ForegroundColor DarkGray

    $response = Invoke-RestMethod -Uri $url -Method PATCH -Headers $headers -Body $body

    if ($response) {
        Write-Host "`nUpdated rows:" -ForegroundColor Green
        $response | Format-Table -AutoSize
    } else {
        Write-Host "`nNo rows matched filter (or RLS blocked update)" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Update failed: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
