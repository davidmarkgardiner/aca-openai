#  The script authenticates with Azure using these credentials and gets an access token. The token is then added to the request headers using the `Authorization` header.


# Import the Az.Accounts module
Import-Module Az.Accounts

# Define your Service Principal credentials
$tenantId = "<your-tenant-id>"
$clientId = "<your-client-id>"
$clientSecret = "<your-client-secret>"

# Authenticate and get the access token
$securePassword = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force
$psCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securePassword
Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId
$token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token

# Define the payload
$payload = @{
    # ...
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
    "Authorization" = "Bearer $token"
    "X-myapp-signature" = $signature
}

# Send the POST request
Invoke-RestMethod -Uri 'https://dev.azure.com/home-k8s/_apis/public/distributedtask/webhooks/danatWebHook?api-version=6.0-preview' -Method Post -Body $payload -Headers $headers
