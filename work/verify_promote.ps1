$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}

$artifacts = @(
    @{ id = "a7f48a0c-29a6-4c69-b901-0d7b538a0eed"; name = "Reading Journal Mode Update" },
    @{ id = "361e5e4a-feae-435e-b743-1c6861a98be0"; name = "Execution Surface Awareness" }
)

Write-Host "=== Pre-Promote Verification ==="
Write-Host ""

foreach ($artifact in $artifacts) {
    $queryBody = @{
        gw_action = "artifact.query"
        gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
        artifact_type = "project"
        artifact_id = $artifact.id
        hydrate = $true
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" -Method POST -Body $queryBody -ContentType "application/json" -Headers $headers
    $a = $response.data.artifact

    Write-Host "Artifact: $($a.title)"
    Write-Host "  ID: $($a.artifact_id)"
    Write-Host "  Current lifecycle_status: $($a.lifecycle_status)"
    Write-Host ""
}
