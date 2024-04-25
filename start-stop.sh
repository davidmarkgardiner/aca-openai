# Function to start clusters
start_clusters() {
    subscriptions="$1"
    for subscription in $subscriptions
    do
        echo "Logging into $subscription"
        az login --subscription "$subscription" || exit 1

        echo "Setting subscription to $subscription"
        az account set --subscription "$subscription" || exit 1

        echo "Starting clusters..."
        for rg in $(az group list --query "[].name" -o tsv)
        do
            for cluster in $(az aks list -g "$rg" --query "[].name" -o tsv)
            do
                az aks start -g "$rg" -n "$cluster" || exit 1

                # Delete and recreate Private Endpoints
                private_endpoints=$(az network private-endpoint list --resource-group "$rg" --query "[].name" -o tsv)
                if [ -n "$private_endpoints" ]; then
                    for pe in $private_endpoints
                    do
                        echo "Deleting Private Endpoint $pe"
                        az network private-endpoint delete --name "$pe" --resource-group "$rg" || exit 1

                        echo "Recreating Private Endpoint $pe"
                        pcri=$(az aks show --name "$cluster" --resource-group "$rg" --query id -o tsv)
                        subnet_name="PE_SUBNET"
                        # Modify the following command as needed to match your Private Endpoint configuration
                        az network private-endpoint create --name "$pe" --resource-group "$rg" --private-connection-resource-id "$pcri" --subnet "$subnet_name" || exit 1
                    done
                else
                    echo "No private endpoints found in resource group $rg"
                fi
            done
        done
    done
}
