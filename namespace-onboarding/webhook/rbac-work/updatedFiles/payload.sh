
#!/bin/bash

variables=$(cat <<EOF
  {
    "action": "REMOVE",
    "aksresid": "/subscriptions/123456-4478-412b-ab09-123456/resourcegroups/AT12345_PREPROD _NCH_AKS/providers/Microsoft.ContainerService/managedClusters/ ",
    "mg": "PREPROD",
    "namespacename": "at12345-preprod-pim-onboarding"
  }
EOF
)
body=$(cat <<EOF
  {
    "resources": {
      "repositories": {
        "self": {
          "refName": "master"
        }
      }
    },
    "templateParameters": $variables,
    "variables": {}
  }
EOF
)

url='https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/pipelines/1577/runs?api-version=6.0'
token=$(az account get-access-token --resource "123456-1321-427f-aa17-123456" | jq -r '.accessToken')

response=$(curl -L -X POST -d "$body" -H "Content-Type: application/json" -H "Authorization: Bearer $token" "$url")
echo "$response"

# Extract the status code from the response
statusCode=$(echo "$response" | tail -n1)

# Print the status code
echo "$statusCode"

# If the status code is 200, print a success message and the response
if [ "$statusCode" -eq 200 ]; then
    echo "API call successful"
    echo "$response"
fi