#!/bin/bash


# Define the payload
payload=$(jq -n \
  --arg id "2" \
  --arg sourceBranch "refs/heads/dev" \
  --arg action "Add" \
  --arg swci "at65999" \
  --arg suffix "poc1" \
  --arg region "westeurope" \
  --arg opEnvironment "dev" \
  --arg resourceQuotaCPU "500m" \
  --arg resourceQuotaMemoryGB "3" \
  --arg resourceQuotaStorageGB "128" \
  --arg billingReference "AB-BC-ABCDE-ABCDE" \
  --arg source "GSNOW" \
  --arg swcID "AA98765" \
  --arg dataClassification "public" \
  --arg appSubdomain "" \
  --arg allowAccessFromNS "at98765" \
  --arg requestedBy "david.gardiner@ubs.com" \
  '{
    "definition": {"id": $id},
    "sourceBranch": $sourceBranch,
    "action": $action,
    "swci": $swci,
    "suffix": $suffix,
    "region": $region,
    "opEnvironment": $opEnvironment,
    "resourceQuotaCPU": $resourceQuotaCPU,
    "resourceQuotaMemoryGB": $resourceQuotaMemoryGB,
    "resourceQuotaStorageGB": $resourceQuotaStorageGB,
    "billingReference": $billingReference,
    "source": $source,
    "swcID": $swcID,
    "dataClassification": $dataClassification,
    "appSubdomain": $appSubdomain,
    "allowAccessFromNS": $allowAccessFromNS,
    "requestedBy": $requestedBy
  }')


#!/bin/bash

# Get the access token
token=$(az account get-access-token --resource "https://management.azure.com/" | jq -r '.accessToken')

# Define the secret key
# key='secretPassword'

# Create the HMAC-SHA1 hash
signature=$(echo -n "$payload" | openssl dgst -sha1 -hmac "$key" | cut -d" " -f2)

# Define the headers
contentType="Content-Type: application/json"
authorization="Authorization: Bearer $token"
signatureHeader="X-myapp-signature: $signature"

# Send the POST request
response=$(curl -s -X POST -d "$payload" -H "$contentType" -H "$authorization" -H "$signatureHeader" 'https://dev.azure.com/home-k8s/_apis/public/distributedtask/webhooks/danatWebHook?api-version=6.0-preview')

