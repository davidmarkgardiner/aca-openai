function Get-AccessTokenForFunction {
    param(
        $clientid,
        $scope,
        $tenantID,
        $secret,
        $requestAccessTokenUri
    )

    $body = "grant_type=client_credentials&client_id=$clientid&client_secret=$secret&scope=$scope"
    $accessTokenData = irm -method Post -uri $requestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'
    if ($accessTokenData.access_token) {
        return $accessTokenData.access_token
    } else {
        throw "Failed to get access token"
    }
}

function MakeApiCall {
    param(
        $apiEndpoint,
        $accessToken,
        $functionBody
    )

    $response = Invoke-RestMethod -Uri $apiEndpoint -Headers @{"authorization" = "Bearer $($accessToken)"} -Body $functionBody -ContentType "application/json" -Method POST -Verbose
    if ($null -eq $response) {
        throw "API call failed"
    }
    return $response
}


function ProcessEnvVars {
    param(
        $regionData,
        $accessToken,
        $apiEndpoint
    )

    $vars = @("ACTION", "SWCI", "SUFFIX", "REGION", "OP_ENVIRONMENT")

    foreach ($v in $vars) {
        Write-Host "$v: $($env:$v)"
    }
    $action = $env:ACTION
    $namespace = $env:NAMESPACE
    $suffix = $env:SUFFIX
    $region = $env:REGION
    $swc = $env:SWCI
    # Convert the first letter to uppercase and the rest to lowercase
    $action = $action.Substring(0,1).ToUpper() + $action.Substring(1).ToLower()
    # Convert $namespace $suffix $region to lowercase
    $namespace = $namespace.ToLower()
    $suffix = $suffix.ToLower()
    $region = $region.ToLower()
    $swc = $swc.ToLower()
    
    if ($regionData.ContainsKey($region)) {
        $clusterid = $regionData[$region]["clusterid"]
        $sub = $regionData[$region]["sub"]
        $rg = $regionData[$region]["rg"]
    } else {
        Write-Host "Invalid Cluster Name"
        return
    }

    Write-Host "region: $region"
    
    $functionBody = @{
        subscriptionID     = "$sub"
        resourceGroupName  = "$rg"
        action             = "$action"
        aksname            = "$clusterid"
        namespacename      = "$namespace"
        suffix             = "$suffix"
    } | convertto-json

    $namespaces_file = "environment/${region}/${clusterid}/kustomization.yaml"

    if ($action -eq "add") {
        if (!(Select-String -Path $namespaces_file -Pattern $namespace-$suffix -Quiet)) {
            $response = MakeApiCall -apiEndpoint $apiEndpoint -accessToken $accessToken -functionBody $functionBody
            Write-Host "$namespace-$env rbac role assignment added"
        }
    }
    if ($action -eq "remove") {
        if (Select-String -Path $namespaces_file -Pattern $namespace-$suffix -Quiet) {
            $response = MakeApiCall -apiEndpoint $apiEndpoint -accessToken $accessToken -functionBody $functionBody
            Write-Host "$namespace-$env rbac role assignment removed"
        }
    }
}

# Main script
# $accessToken = Get-AccessTokenForFunction -scope 
# $apiEndpoint = https://azurewebsites.net/api/aksnamespaceroleassign

# ProcessEnvVars -regionData $regionData -accessToken $accessToken -apiEndpoint $apiEndpoint

# # Example of setting environment variables (this would be part of your AddSPNToEnvironment logic)
# [System.Environment]::SetEnvironmentVariable("SPN_CLIENT_ID", "your_client_id", [System.EnvironmentVariableTarget]::Process)
# [System.Environment]::SetEnvironmentVariable("SPN_TENANT_ID", "your_tenant_id", [System.EnvironmentVariableTarget]::Process)
# [System.Environment]::SetEnvironmentVariable("SPN_SECRET", "your_secret", [System.EnvironmentVariableTarget]::Process)
# [System.Environment]::SetEnvironmentVariable("SPN_SCOPE", "your_scope", [System.EnvironmentVariableTarget]::Process)
# [System.Environment]::SetEnvironmentVariable("SPN_REQUEST_ACCESS_TOKEN_URI", "your_request_access_token_uri", [System.EnvironmentVariableTarget]::Process)

# # Main script
# $clientId = [System.Environment]::GetEnvironmentVariable("SPN_CLIENT_ID", [System.EnvironmentVariableTarget]::Process)
# $tenantId = [System.Environment]::GetEnvironmentVariable("SPN_TENANT_ID", [System.EnvironmentVariableTarget]::Process)
# $secret = [System.Environment]::GetEnvironmentVariable("SPN_SECRET", [System.EnvironmentVariableTarget]::Process)
# $scope = [System.Environment]::GetEnvironmentVariable("SPN_SCOPE", [System.EnvironmentVariableTarget]::Process)
# $requestAccessTokenUri = [System.Environment]::GetEnvironmentVariable("SPN_REQUEST_ACCESS_TOKEN_URI", [System.EnvironmentVariableTarget]::Process)

# $accessToken = Get-AccessTokenForFunction -clientid $clientId -tenantID $tenantId -secret $secret -scope $scope -requestAccessTokenUri $requestAccessTokenUri
# $apiEndpoint = "https://azurewebsites.net/api/aksnamespaceroleassign"

# # Assuming $regionData is defined somewhere in your script or passed as an argument
# ProcessEnvVars -regionData $regionData -accessToken $accessToken -apiEndpoint $apiEndpoint