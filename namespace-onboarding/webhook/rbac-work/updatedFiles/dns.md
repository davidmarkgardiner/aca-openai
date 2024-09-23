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