# Function to start clusters
start_clusters() {
    subscription=$1
    echo "Setting subscription to $subscription"
    az account set --subscription $subscription

    echo "Starting clusters..."
    for rg in $(az group list --query "[].name" -o tsv)
    do
        for cluster in $(az aks list -g $rg --query "[].name" -o tsv)
        do
            az aks start -g $rg -n $cluster

            # Delete and recreate Private Endpoints
            for pe in $(az network private-endpoint list --resource-group $rg --query "[].name" -o tsv)
            do
                echo "Deleting Private Endpoint $pe"
                az network private-endpoint delete --name $pe --resource-group $rg

                echo "Recreating Private Endpoint $pe"
                # Modify the following command as needed to match your Private Endpoint configuration
                az network private-endpoint create --name $pe --resource-group $rg --vnet-name YourVnetName --subnet YourSubnetName --private-connection-resource-id $(az aks show --name $cluster --resource-group $rg --query id -o tsv) --group-ids managedClusters
            done
        done
    done
}
