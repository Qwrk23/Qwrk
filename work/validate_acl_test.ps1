try {
    $json = Get-Content 'c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Gateway_v1__ACL_Test.json' -Raw | ConvertFrom-Json
    $nodeCount = $json.nodes.Count
    $aclNode = $json.nodes | Where-Object { $_.name -eq 'NQxb_Gateway_v1__ACL_Lookup' }

    Write-Output "JSON VALID"
    Write-Output "Workflow name: $($json.name)"
    Write-Output "Active: $($json.active)"
    Write-Output "Node count: $nodeCount"
    Write-Output "Webhook path: $($json.nodes[0].parameters.path)"
    Write-Output ""

    if ($aclNode) {
        Write-Output "ACL_Lookup node FOUND:"
        Write-Output "  Type: $($aclNode.type)"
        Write-Output "  TypeVersion: $($aclNode.typeVersion)"
        Write-Output "  Auth: $($aclNode.parameters.authentication)"
        Write-Output "  CredType: $($aclNode.parameters.nodeCredentialType)"
        Write-Output "  CredID: $($aclNode.credentials.supabaseApi.id)"
        Write-Output "  CredName: $($aclNode.credentials.supabaseApi.name)"
        Write-Output "  Method: $($aclNode.parameters.method)"
        Write-Output "  URL: $($aclNode.parameters.url)"
        Write-Output "  Position: [$($aclNode.position -join ', ')]"
    } else {
        Write-Output "ACL_Lookup node NOT FOUND"
    }

    # Check for any $env references
    $rawContent = Get-Content 'c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Gateway_v1__ACL_Test.json' -Raw
    if ($rawContent -match '\$env\.') {
        Write-Output "`nWARNING: Found `$env references!"
    } else {
        Write-Output "`nNo `$env references found (CLEAN)"
    }

    # Check connections for ACL node
    $connections = $json.connections
    $aclConnected = $connections.PSObject.Properties.Name -contains 'NQxb_Gateway_v1__ACL_Lookup'
    Write-Output "ACL node wired: $aclConnected"

} catch {
    Write-Output "JSON INVALID: $($_.Exception.Message)"
}
