### pwsh
```
steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: ''
    scriptType: 'ps'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Log in using the service principal
      az login --service-principal -u $(servicePrincipalId) -p $(servicePrincipalKey) --tenant $(tenantId)
      # Define the resource group
      $rg = $env:rg
      # Replace the last part of the resource group name
      $newRg = $rg -replace '_AKS$', '_PRIVATEDNS'
      # Print the new resource group name
      Write-Output "New Resource Group: $newRg"
      # Get the list of private DNS zones
      $dnsZoneList = az network private-dns zone list --resource-group $newRg --output json
      # Convert the JSON output to a PowerShell object
      $dnsZoneList = $dnsZoneList | ConvertFrom-Json
     # Extract the 'name' property from each DNS zone
      $dnsZoneName = $dnsZoneList | ForEach-Object { $_.name } 
      # Print the DNS zone names
      Write-Output "DNS Zone Name: $dnsZoneName"
      # Set the result as a pipeline variable
      Write-Host "##vso[task.setvariable variable=dnsZone]$dnsZoneName"
  displayName: 'Lookup Azure Private DNS Zone'

- script: |
    # Use the extracted DNS Zone variable
    echo "Using extracted DNS Zone..."
    echo "DNS Zone: $(dnsZoneName)"
  displayName: 'Use Extracted DNS Zone Variable'
```

### Bash

```
steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: ''
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Log in using the service principal
      az login --service-principal -u $servicePrincipalId -p $servicePrincipalKey --tenant $tenantId
      # Define the resource group name
      rg=$rg
      # Check if the resource group name contains "AKS" and does not contain "at39473"
      if [[ "$rg" == *"AKS"* && "$rg" != *"at39473"* ]]; then
        # Replace the last part of the resource group name
        newRg="${rg%_*}_PRIVATEDNS"
        echo "New resource group name: $newRg" 
        # Get the list of private DNS zones
        dnsZoneList=$(az network private-dns zone list --resource-group $newRg --output json)
        # Extract the 'name' property from each DNS zone
        dnsZoneName=$(echo $dnsZoneList | jq -r '.[].name')
      else
        echo "Resource group name does not meet the criteria."
        # Hardcode the DNS zone name
        dnsZoneName="test-akseng-gitops"
      fi
      # Print the DNS zone names
      echo "DNS Zone Name: $dnsZoneName"
      # Set the result as a pipeline variable
      echo "##vso[task.setvariable variable=dnsZone]$dnsZoneName"
      # Print the DNS zone names
      echo "DNS Zone Name: $dnsZoneName"
      # Set the result as a pipeline variable
      echo "##vso[task.setvariable variable=dnsZone]$dnsZoneName"
  displayName: 'Lookup Azure Private DNS Zone'

- script: |
    # Use the extracted DNS Zone variable
    echo "Using extracted DNS Zone..."
    echo "DNS Zone: $(dnsZoneName)"
  displayName: 'Use Extracted DNS Zone Variable'
```


```


# Log in using the service principal
az login --service-principal -u $servicePrincipalId -p $servicePrincipalKey --tenant $tenantId

# Define the resource group name
rg=$rg

# Check if the resource group name contains "at39473"
if [[ "$rg" == *"at39473"* ]]; then
  echo "Resource group contains 'at39473', using hardcoded DNS zone name."
  dnsZoneName="test-akseng-gitops"
# Check if the resource group name contains "AKS" and does not end with "AKS"
elif [[ "$rg" == *"AKS"* && "$rg" != *"AKS" ]]; then
  # Replace the last part of the resource group name
  newRg="${rg%_*}_PRIVATEDNS"
  echo "New resource group name: $newRg" 
  # Get the list of private DNS zones
  dnsZoneList=$(az network private-dns zone list --resource-group $newRg --output json)
  # Extract the 'name' property from each DNS zone
  dnsZoneName=$(echo $dnsZoneList | jq -r '.[].name')
else
  echo "Resource group name does not meet any criteria: $rg"
  # Hardcode the DNS zone name as a fallback
  dnsZoneName="test-akseng-gitops"
fi

# Print the DNS zone name
echo "DNS Zone Name: $dnsZoneName"
# Set the result as a pipeline variable
echo "##vso[task.setvariable variable=dnsZone]$dnsZoneName"
```

```
#!/bin/bash

# Log in using the service principal
az login --service-principal -u $servicePrincipalId -p $servicePrincipalKey --tenant $tenantId

# Define the resource group name
rg=$rg

# Check if the resource group name ends with "_AKS" and does not start with "AT39473" (case-insensitive)
if [[ "$rg" == *"_AKS" && "${rg,,}" != at39473* ]]; then
  # Replace the last part of the resource group name
  newRg="${rg%_*}_PRIVATEDNS"
  echo "New resource group name: $newRg" 
  # Get the list of private DNS zones
  dnsZoneList=$(az network private-dns zone list --resource-group $newRg --output json)
  # Extract the 'name' property from each DNS zone
  dnsZoneName=$(echo $dnsZoneList | jq -r '.[].name')
else
  echo "Resource group name does not meet the criteria. RG: $rg"
  # Hardcode the DNS zone name
  dnsZoneName="test-akseng-gitops"
fi

# Print the DNS zone name
echo "DNS Zone Name: $dnsZoneName"
# Set the result as a pipeline variable
echo "##vso[task.setvariable variable=dnsZone]$dnsZoneName"
```