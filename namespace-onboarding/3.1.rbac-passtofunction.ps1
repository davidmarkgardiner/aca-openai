$datadir = "data2/"
$jsonFiles = Get-ChildItem -Path $datadir -Filter "*.json"

 

foreach ($jsonfile in $jsonFiles) {
    $jsonData = Get-Content -Path $jsonfile.FullName -Raw | ConvertFrom-Json
    $action = $jsonData.action
    $swci = $jsonData.swci
    $suffix = $jsonData.suffix
    $region = $jsonData.region
    $opEnvironment = $jsonData.opEnvironment
    # Write-Host "region: $region"
    # Write-Host "region: $opEnvironment"
    # Write-Host "region: $region"
    # Assume $item.Region is already defined
    
    $filename = "region/$region.env"

    # Read the .env file
    $data = Get-Content $filename -ErrorAction Stop

    # Iterate over the lines
    foreach ($line in $data) {
        # Split the line into a key and a value
        $parts = $line -split "=", 2
        if ($parts.Count -ne 2) {
            Write-Host "Invalid line: $line"
            continue
        }

        # Set the environment variable
        $key = $parts[0]
        $value = $parts[1]
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }

# Print environment variables
$clustername = [Environment]::GetEnvironmentVariable("clustername", "Process")
$domain = [Environment]::GetEnvironmentVariable("domain", "Process")
$sub = [Environment]::GetEnvironmentVariable("sub", "Process")
$rg = [Environment]::GetEnvironmentVariable("rg", "Process")
Write-Host "clustername: $clustername"
Write-Host "domain: $domain"
Write-Host "sub: $sub"
Write-Host "rg: $rg"

Write-Host "namespace: $swci-$opEnvironment-$suffix"
Write-Host "swci-suffix: $opEnvironment-$suffix"

 
}