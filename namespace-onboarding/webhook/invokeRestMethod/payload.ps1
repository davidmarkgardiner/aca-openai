
$variables = @{
    ACTION = "Add"
    SWCI = "at65999"
    SUFFIX = "poc1"
    REGION = "westeurope"
    OPENV = "dev"
    CPU = "500m"
    MEM = "3"
    STORAGE = "128"
    BILLINGREFERENCE = "AB-BC-ABCDE-ABCDE"
    SOURCE = "GSNOW"
    SWCID = "AA98765"
    CLASS = "public"
    SUBDOMAIN = ""
    ALLOWACCESSFROMNS = "at98765"
    REQUESTEDBY = "david.gardiner@ubs.com"
}

$body = @{
  definition = {id = 2}
  sourceBranch = "refs/heads/master"
  parameters = ($variables | ConvertTo-Json)
}


# # Define the payload
# $payload = @{
#     "definition" = @{
#         "id" = 2
#     }
#     "sourceBranch" = "master"
#     "action" = "Add"
#     "swci" = "at65999"
#     "suffix" = "poc1"
#     "region" = "westeurope"
#     "opEnvironment" = "dev"
#     "resourceQuotaCPU" = "500m"
#     "resourceQuotaMemoryGB" = "3"
#     "resourceQuotaStorageGB" = "128"
#     "billingReference" = "AB-BC-ABCDE-ABCDE"
#     "source" = "GSNOW"
#     "swcID" = "AA98765"
#     "dataClassification" = "public"
#     "appSubdomain" = ""
#     "allowAccessFromNS" = "at98765"
#     "requestedBy" = "david.gardiner@ubs.com"
# } | ConvertTo-Json

# Define the URI for the Azure DevOps API
# $uri = "https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/pipelines/782/runs?api-version=6.0-preview.1"
# $uri = "https://dev.azure.com/home-k8s/Homelab/_apis/2/runs?api-version=7.0-preview.1"
$uri = "https://dev.azure.com/home-k8s/Homelab/_apis/build/builds?api-version=6.0"
# # Define the authorization header for the API request
# $authHeader = @{
#     'Authorization' = 'Bearer ' + (Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798").Token
#     'Content-Type'  = 'application/json'
# }

# # Define the authorization header for the API request
# $authHeader = @{
#     'Authorization' = 'Bearer ' + (Get-AzAccessToken -ResourceUrl "596e2eab-f731-4d9f-8c6c-909df9c5493c").Token
#     'Content-Type'  = 'application/json'
# }

# # Define the body for the API request
# $body = @{
#     "definition" = @{
#         "id" = 2
#     }
# } 

# # Merge the payload and the body
# $merged = $payload + $body

# # Convert the merged hashtable to JSON
# $json = $merged | ConvertTo-Json
# Write-Output $paylod
# Define the authorization header for the API request
$authHeader = @{
    'Authorization' = 'Bearer ' + (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
    'Content-Type'  = 'application/json'
}

Write-Output "$payload"

# Print a message indicating that a REST call is being made
Write-Output "Sending a REST call to Azure DevOps API"

# Make the REST call to Azure DevOps API
try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $payload -ContentType "application/json" -Headers $authHeader -Verbose
    $StatusCode = $Response.StatusCode
}
catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    Write-Output $_.Exception.Message
}
# # Print the status code
# Write-Output $StatusCode
# $StatusCode
# Write-Ouput $response
# $response 

# If the status code is 200, print a success message and the response
if ($StatusCode -eq 200) {
    Write-Output "API call successful"
    $response
}