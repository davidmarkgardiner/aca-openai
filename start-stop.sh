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
        done
    done
}
