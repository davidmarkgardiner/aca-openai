#!/bin/bash


# Define the payload
payload=$(jq -n \
  --arg id "2" \
  --arg sourceBranch "refs/heads/dev" \
  --argjson parameters '{
    "action": "Add",
    "swci": "at65999",
    "suffix": "poc1",
    "region": "westeurope",
    "opEnvironment": "dev",
    "resourceQuotaCPU": "500m",
    "resourceQuotaMemoryGB": "3",
    "resourceQuotaStorageGB": "128",
    "billingReference": "AB-BC-ABCDE-ABCDE",
    "source": "GSNOW",
    "swcID": "AA98765",
    "dataClassification": "public",
    "appSubdomain": "",
    "allowAccessFromNS": "at98765",
    "requestedBy": "david.gardiner@ubs.com"
  }' \
  '{
    "definition": {"id": $id},
    "sourceBranch": $sourceBranch,
    "parameters": $parameters
  }')

# # Define the payload
# payload=$(jq -n \
#   --arg id "2" \
#   --arg sourceBranch "refs/heads/dev" \
#   --arg action "Add" \
#   --arg swci "at65999" \
#   --arg suffix "poc1" \
#   --arg region "westeurope" \
#   --arg opEnvironment "dev" \
#   --arg resourceQuotaCPU "500m" \
#   --arg resourceQuotaMemoryGB "3" \
#   --arg resourceQuotaStorageGB "128" \
#   --arg billingReference "AB-BC-ABCDE-ABCDE" \
#   --arg source "GSNOW" \
#   --arg swcID "AA98765" \
#   --arg dataClassification "public" \
#   --arg appSubdomain "" \
#   --arg allowAccessFromNS "at98765" \
#   --arg requestedBy "david.gardiner@ubs.com" \
#   '{
#     "definition": {"id": $id},
#     "sourceBranch": $sourceBranch,
#     "action": $action,
#     "swci": $swci,
#     "suffix": $suffix,
#     "region": $region,
#     "opEnvironment": $opEnvironment,
#     "resourceQuotaCPU": $resourceQuotaCPU,
#     "resourceQuotaMemoryGB": $resourceQuotaMemoryGB,
#     "resourceQuotaStorageGB": $resourceQuotaStorageGB,
#     "billingReference": $billingReference,
#     "source": $source,
#     "swcID": $swcID,
#     "dataClassification": $dataClassification,
#     "appSubdomain": $appSubdomain,
#     "allowAccessFromNS": $allowAccessFromNS,
#     "requestedBy": $requestedBy
#   }')

# write ouput of payload
echo "$payload"

# Define the URI for the Azure DevOps API
uri="https://dev.azure.com/home-k8s/Homelab/_apis/build/builds?api-version=6.0"

# Get the Azure access token
token=$(az account get-access-token --resource "https://management.azure.com/" | jq -r '.accessToken')

# Define the authorization header for the API request
authHeader="Authorization: Bearer $token"

# Make the REST call to Azure DevOps API
# response=$(curl -s -w "%{http_code}" -X POST -d "$payload" -H "Content-Type: application/json" -H "$authHeader" "$uri")
# response=$(curl -L -s -w "%{http_code}" -X POST -d "$payload" -H "Content-Type: application/json" -H "$authHeader" "$uri")
response=$(curl -L -s -w "%{http_code}" -X POST -d "$payload" -H "Content-Type: application/json" -H "Content-Length: ${#payload}" -H "$authHeader" "$uri")
# Extract the status code from the response
statusCode=$(echo "$response" | tail -n1)

# Print the status code
echo "$statusCode"

# If the status code is 200, print a success message and the response
if [ "$statusCode" -eq 200 ]; then
    echo "API call successful"
    echo "$response"
fi