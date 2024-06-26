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

function ProcessJsonFile {
    param(
        $jsonfile,
        $regionData,
        $accessToken,
        $apiEndpoint
    )

    $jsonData = Get-Content -Path $jsonfile.FullName -Raw | ConvertFrom-Json

    $action = $jsonData.action
    $namespace = $jsonData.namespace
    $suffix = $jsonData.suffix
    $region = $jsonData.region

    # Convert the first letter to uppercase and the rest to lowercase
    $jsonData.action = $jsonData.action.Substring(0,1).ToUpper() + $jsonData.action.Substring(1).ToLower()
    # Convert $jsonData.namespace $jsonData.suffix $jsonData.region to lowercase
    $jsonData.namespace = $jsonData.namespace.ToLower()
    $jsonData.suffix = $jsonData.suffix.ToLower()
    $jsonData.region = $jsonData.region.ToLower()
    


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
$datadir = "data2/"
$jsonFiles = Get-ChildItem -Path $datadir -Filter "*.json"

if ($jsonFiles.Count -eq 0) {
    Write-Host "No JSON files found in $datadir"
    exit 1
}

# # ... rest of your script ...

# $accessToken = Get-AccessTokenForFunction -scope 
# $apiEndpoint = https://azurewebsites.net/api/aksnamespaceroleassign

# foreach ($jsonfile in $jsonFiles) {
#     ProcessJsonFile -jsonfile $jsonfile -regionData $regionData -accessToken $accessToken -apiEndpoint $apiEndpoint
# }