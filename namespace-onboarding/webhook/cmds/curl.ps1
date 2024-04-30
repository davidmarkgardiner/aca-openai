

# Define the payload
$payload = @{
    "action" = "add"
    "swci" = "at65999"
    "suffix" = "poc1"
    "region" = "westeurope"
    "opEnvironment" = "dev"
    "resourceQuotaCPU" = "0.5"
    "resourceQuotaMemoryGB" = "3"
    "resourceQuotaStorageGB" = "10"
    "billingReference" = "AB-BC-ABCDE-ABCDE"
    "source" = "GSNOW"
    "swcID" = "AA98765"
    "dataClassification" = "public"
    "appSubdomain" = ""
    "allowAccessFromNS" = "at98765"
    "requestedBy" = "david.gardiner@ubs.com"
} | ConvertTo-Json

# Define the secret key
$key = 'secretPassword'

# Create the HMAC-SHA1 hash
$hmacsha = New-Object System.Security.Cryptography.HMACSHA1
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($key)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($payload))
$signature = [BitConverter]::ToString($signature).Replace('-', '').ToLower()

# Define the headers
$headers = @{
    "Content-Type" = "application/json"
    "X-myapp-signature" = $signature
}

# Send the POST request
Invoke-RestMethod -Uri 'https://dev.azure.com/home-k8s/_apis/public/distributedtask/webhooks/danatWebHook2?api-version=6.0-preview' -Method Post -Body $payload -Headers $headers