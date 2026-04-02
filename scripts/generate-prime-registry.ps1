# Generate Prime workspace artifact registry CSV
# Queries Supabase directly via MCP-equivalent REST API
# Output: Qwrk_RollingMem/artifact_registry__2026-03-15.csv

$ErrorActionPreference = "Stop"

$projectRef = "npymhacpmxdnkqdzgxll"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$outputPath = Join-Path $PSScriptRoot ".." "Qwrk_RollingMem" "artifact_registry__2026-03-15.csv"

# Read service role key from credentials file
$credsPath = Join-Path $env:USERPROFILE ".qwrk" "supabase_service_key.txt"
if (-not (Test-Path $credsPath)) {
    # Try environment variable
    $serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
    if (-not $serviceKey) {
        Write-Error "No Supabase service role key found. Set SUPABASE_SERVICE_ROLE_KEY or create $credsPath"
        exit 1
    }
} else {
    $serviceKey = (Get-Content $credsPath -Raw).Trim()
}

$baseUrl = "https://$projectRef.supabase.co/rest/v1/rpc/execute_sql"

# We'll use the PostgREST endpoint directly to query
$restUrl = "https://$projectRef.supabase.co/rest/v1/qxb_artifact"

$headers = @{
    "apikey" = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Query all artifacts for workspace, ordered by created_at
# Using PostgREST query parameters
$allRows = @()
$offset = 0
$batchSize = 500

do {
    $url = "${restUrl}?workspace_id=eq.${workspaceId}&deleted_at=is.null&order=created_at.asc&offset=${offset}&limit=${batchSize}&select=artifact_id,artifact_type,title,priority,lifecycle_status,execution_status,semantic_type_id,tags,parent_artifact_id,created_at,updated_at"

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    $allRows += $response
    $offset += $batchSize
    Write-Host "Fetched $($allRows.Count) rows so far..."
} while ($response.Count -eq $batchSize)

Write-Host "Total rows: $($allRows.Count)"

# Now query semantic type registry for key lookup
$stUrl = "https://$projectRef.supabase.co/rest/v1/qxb_semantic_type_registry?select=semantic_type_id,key"
$stRegistry = Invoke-RestMethod -Uri $stUrl -Headers $headers -Method Get
$stMap = @{}
foreach ($st in $stRegistry) {
    $stMap[$st.semantic_type_id] = $st.key
}

# Build CSV
$csvLines = @()
$csvLines += "artifact_id,artifact_type,title,priority,lifecycle_status,execution_status,semantic_type_id,semantic_type,tags,parent_artifact_id,created_at,updated_at"

foreach ($row in $allRows) {
    $title = $row.title -replace '"', '""'
    $tags = if ($row.tags) { ($row.tags | ConvertTo-Json -Compress) } else { "[]" }
    $semanticType = if ($row.semantic_type_id -and $stMap.ContainsKey($row.semantic_type_id)) { $stMap[$row.semantic_type_id] } else { "" }
    $semanticTypeId = if ($row.semantic_type_id) { $row.semantic_type_id } else { "" }
    $lifecycleStatus = if ($row.lifecycle_status) { $row.lifecycle_status } else { "" }
    $executionStatus = if ($row.execution_status) { $row.execution_status } else { "" }
    $parentId = if ($row.parent_artifact_id) { $row.parent_artifact_id } else { "" }

    $csvLines += "$($row.artifact_id),$($row.artifact_type),`"$title`",$($row.priority),$lifecycleStatus,$executionStatus,$semanticTypeId,$semanticType,`"$tags`",$parentId,$($row.created_at),$($row.updated_at)"
}

$csvContent = $csvLines -join "`n"
Set-Content -Path $outputPath -Value $csvContent -Encoding UTF8 -NoNewline

Write-Host "Written $($allRows.Count) rows to $outputPath"
