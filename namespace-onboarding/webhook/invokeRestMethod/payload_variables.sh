#!/bin/bash

#!/bin/bash

variables=$(cat <<EOF
{
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
    "requestedBy": ""
}
EOF
)

payload=$(cat <<EOF
{
  "definition": {"id": 2},
  "sourceBranch": "refs/heads/master",
  "parameters": $variables,
  "contentType": "application/json"
}
EOF
)



# write ouput of payload
echo "$payload"

# Define the URI for the Azure DevOps API
# uri="https://dev.azure.com/home-k8s/Homelab/_apis/build/builds?api-version=6.0"
uri-"https://dev.azure.com/home-k8s/Homelab/_apis/pipelines/2/runs?api-version=6.0-preview.1"
# Get the Azure access token
token=$(az account get-access-token --resource "https://management.azure.com/" | jq -r '.accessToken')

# Define the authorization header for the API request
authHeader="Authorization: Bearer $token"

# Make the REST call to Azure DevOps API
# response=$(curl -s -w "%{http_code}" -X POST -d "$payload" -H "Content-Type: application/json" -H "$authHeader" "$uri")
# response=$(curl -L -s -w "%{http_code}" -X POST -d "$payload" -H "Content-Type: application/json" -H "$authHeader" "$uri")
response=$(curl -L -s -w "%{http_code}" -X POST -d "$payload" -H "Content-Type: application/json" -H "Content-Length: ${#payload}" -H "$authHeader" "$uri")
# Extract the status code from the response
echo "$response"
statusCode=$(echo "$response" | tail -n1)

# Print the status code
echo "$statusCode"

# If the status code is 200, print a success message and the response
if [ "$statusCode" -eq 200 ]; then
    echo "API call successful"
    echo "$response"
fi