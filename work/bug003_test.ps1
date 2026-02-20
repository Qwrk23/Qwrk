# BUG-003 Validation Test Harness
# Sends artifact.query with hydrate in selector (correct contract location)

param(
    [Parameter(Mandatory=$true)]
    [string]$ArtifactType,

    [Parameter(Mandatory=$true)]
    [string]$ArtifactId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("true", "false")]
    [string]$Hydrate
)

$gatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$workspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
$credential = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:aslfja'wwe*(#fhwoII843ghlw_ek2l"))

$headers = @{
    "Authorization" = "Basic $credential"
    "Content-Type" = "application/json"
}

$hydrateBool = $Hydrate -eq "true"

$body = @{
    gw_action = "artifact.query"
    gw_workspace_id = $workspaceId
    artifact_id = $ArtifactId
    artifact_type = $ArtifactType
    selector = @{
        hydrate = $hydrateBool
    }
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri $gatewayUrl -Method POST -Body $body -ContentType "application/json" -Headers $headers
$response | ConvertTo-Json -Depth 10
