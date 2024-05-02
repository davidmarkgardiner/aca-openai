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

    # Convert the first letter to uppercase and the rest to lowercase
    $action = $action.Substring(0,1).ToUpper() + $action.Substring(1).ToLower()
    # Convert $namespace $suffix $region to lowercase
    $namespace = $namespace.ToLower()
    $suffix = $suffix.ToLower()
    $region = $region.ToLower()

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