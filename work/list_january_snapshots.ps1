$cred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))
$headers = @{Authorization="Basic $cred"}

# Candidate IDs (seeds + saplings, excluding trees)
$candidates = @(
    "d34ebe66-cd75-40bc-aea2-b0f6bf3ee30a",  # Encode Old Bull Operating Law
    "963826c6-a3e2-4666-b6d5-32a5171e52bf",  # Canvas-First Prompt Review
    "a7f48a0c-29a6-4c69-b901-0d7b538a0eed",  # Reading Journal Mode Update
    "361e5e4a-feae-435e-b743-1c6861a98be0",  # Execution Surface Awareness
    "d6cc3ec9-c919-4a2f-ade5-e79c06eb5e52",  # Old Bull Principles
    "0a10a222-ebf2-41bc-8c28-9d4289197284",  # Guided Daily Routines
    "a6b5e07f-f540-43a3-a72f-e34199c365db",  # Idempotency Enforcement (sapling)
    "6e7aa9dc-c76c-4a36-8d51-672c3be9ad35"   # Browser Command Surface
)

Write-Host "=== Candidate Projects for Quick Wins ==="
Write-Host ""

foreach ($id in $candidates) {
    $queryBody = @{
        gw_action = "artifact.query"
        gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
        artifact_type = "project"
        artifact_id = $id
        hydrate = $true
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" -Method POST -Body $queryBody -ContentType "application/json" -Headers $headers
    $a = $response.data.artifact

    Write-Host "=========================================="
    Write-Host "TITLE: $($a.title)"
    Write-Host "STATUS: $($a.lifecycle_status)"
    Write-Host "TAGS: $($a.tags -join ', ')"
    Write-Host "ID: $($a.artifact_id)"
    Write-Host ""
    Write-Host "SUMMARY:"
    Write-Host $a.summary
    Write-Host ""
}
