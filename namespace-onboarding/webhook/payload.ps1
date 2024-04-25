Param (
    [uri]
    $Url = "https://dev.azure.com/MY_ORG/_apis/public/distributedtask/webhooks/WebookDemoTrigger/?api-version=6.0-preview",

    [string]
    $Secret = "Demo123!",

    [string]
    $HeaderName = "MyHeader"
)

$Body = @{
    action = "REMOVE", 
    swci = "at52223",
    suffix = "OB-test",
    region = "westeurope",
    opEnvironment = "DEV",
    resourceQuotaCPU = "0.5",
    resourceQuotaMemoryGB = "1",
    resourceQuotaStorageGB = "10",
    billingReference = "AB-BC-abcde-ABCDE",
    source = "GSNOW",
    swcID = "aa98765",
    dataClassification = "public",
    appSubdomain = "",
    allowAccessFromNS = "at98765",
    requestedBy = "david.gardiner@ubs.com"
} | ConvertTo-Json

$hmacSha = New-Object System.Security.Cryptography.HMACSHA1 -Property @{
    Key = [Text.Encoding]::ASCII.GetBytes($secret)
}

$hashBytes = $hmacSha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Body))
$signature = ''

$hashBytes | ForEach-Object { $signature += $_.ToString('x2')}

$headers = @{
    $headerName = "sha1=$signature"
}

Invoke-WebRequest -Uri $Url -Body $Body -Method Post -ContentType 'application/json' -Headers $headers