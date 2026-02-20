$url = "https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/"
$key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5weW1oYWNwbXhkbmtxZHpneGxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxMTQxMjcsImV4cCI6MjA4MjY5MDEyN30.3KKdIXmxtXuFgAHu4nvm21odPZsHX_MFMjNshXpN7QM"

$headers = @{ "apikey" = $key }
$response = Invoke-RestMethod -Uri $url -Headers $headers
$defs = $response.definitions

foreach ($tableName in ($defs.PSObject.Properties.Name | Sort-Object)) {
    $table = $defs.$tableName
    Write-Output "=== TABLE: $tableName ==="
    if ($table.description) { Write-Output "  COMMENT: $($table.description)" }
    Write-Output "  REQUIRED: $($table.required -join ', ')"
    foreach ($colName in ($table.properties.PSObject.Properties.Name | Sort-Object)) {
        $col = $table.properties.$colName
        $type = $col.type
        $format = $col.format
        $desc = $col.description
        $default = $col.default
        $maxLen = $col.maxLength
        $enum = $col.enum
        Write-Output "  COLUMN: $colName | type=$type format=$format default=$default enum=$($enum -join ',') desc=$desc"
    }
    Write-Output ""
}
