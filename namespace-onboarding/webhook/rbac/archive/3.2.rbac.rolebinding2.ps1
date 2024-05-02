function Get-AccessTokenForFunction {
    param(
    $clientid = $env:ARM_CLIENT_ID,
    $scope = $env:SCOPE_ID,
    $tenantID = $env:SP_TENANT_ID,
    $secret = $env:ARM_CLIENT_SECRET
    )

    $requestAccessTokenUri = "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"

    $body = "grant_type=client_credentials&client_id=$clientid&client_secret=$secret&scope=$scope"

    $accessTokenData = irm -method Post -uri $requestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

    if ($accessTokenData.access_token) {
        return $accessTokenData.access_token
    } else {
        throw "Failed to get access token"
    }
}

$action = $env:ACTION
$suffix = $env:SUFFIX
$region = $env:REGION
$swc = $env:SWCI
$opEnvironment = $env:OP_ENVIRONMENT

write-host "action: $action"
write-host "suffix: $suffix"
write-host "region: $region"
write-host "swc: $swc"
write-host "opEnvironment: $opEnvironment"

$action = $action.Substring(0,1).ToUpper() + $action.Substring(1).ToLower()

$suffix = $suffix.ToLower()
$region = $region.ToLower()
$swc = $swc.ToLower()

$filename = "region/$region.env"

$data = Get-Content $filename -ErrorAction Stop

foreach ($line in $data) {
    $parts = $line -split "=", 2

    if ($parts.Count -ne 2) {
        Write-Host "Invalid line: $line"
        continue
    }

    $key = $parts[0]
    $value = $parts[1]
    [Environment]::SetEnvironmentVariable($key, $value, "Process")
}

$clustername = [Environment]::GetEnvironmentVariable("clustername", "Process")
$sub = [Environment]::GetEnvironmentVariable("sub", "Process")
$rg = [Environment]::GetEnvironmentVariable("rg", "Process")

Write-Host "clustername: $clustername"
Write-Host "sub: $sub"
Write-Host "rg: $rg"

$accessToken = Get-AccessTokenForFunction -clientid "$env:ARM_CLIENT_ID" -scope "$env:SCOPE_ID" -tenantID "$env:SP_TENANT_ID" -secret "$env:ARM_CLIENT_SECRET"

Write-Host "namespace: $swci-$opEnvironment-$suffix"
Write-Host "swci-suffix: $opEnvironment-$suffix"

$functionBody = @{
    subscriptionID     = "$sub"
    resourceGroupName  = "$rg"
    action             = "$action"
    aksname            = "$clustername"
    namespacename      = "$swci"
    suffix             = "$opEnvironment-$suffix"
} | convertto-json

$apiEndpoint = "your_api_endpoint_here" # Define $apiEndpoint

Write-Host "apiEndpoint is $apiEndpoint"
Write-Host "action is $action"

switch ($action) {
    "Add" {
        $response = Invoke-RestMethod -Uri $apiEndpoint -Headers @{"authorization" = "Bearer $($accessToken)"} -Body $functionBody -content "application/json" -Method POST -Verbose

        if ($null -eq $response) {
            Write-Host "API call failed"
            Write-Host "Error: $Error[0]"
            exit 1
        }

        Write-Host "$swci-$opEnvironment-$suffix rbac role assignment added"
        Start-Sleep -Seconds 30
    }        

    "Remove" {
        $response = Invoke-RestMethod -Uri $apiEndpoint -Headers @{"authorization" = "Bearer $($accessToken)"} -Body $functionBody -content "application/json" -Method POST -Verbose

        if ($null -eq $response) {
            Write-Host "API call failed"
            Write-Host "Error: $Error[0]"
            exit 1
        }

        Write-Host "$swci-$opEnvironment-$suffix rbac role assignment added"
        Start-Sleep -Seconds 30
    }
}