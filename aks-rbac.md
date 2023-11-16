
# Namespace RBAC configuration

### Create Cluster
```sh
az group create --location eastus --resource-group demo
az aks create --name demo-cluster \
              --resource-group agicdemo \
              --enable-managed-identity \
              --node-count 1 \
              --min-count 1 \
              --max-count 2 \
              --generate-ssh-keys \
              --enable-aad \
              --enable-azure-rbac \
              --disable-local-accounts \
```

### Create Group
```
az ad group create --display-name "aksreader" --mail-nickname "aksreader"
az ad group create --display-name "aksadmin" --mail-nickname "aksadmin"  
```
### Create Roles assignment to group
```sh
clusterId=/subscriptions/12345/resourcegroups/demo/providers/Microsoft.ContainerService/managedClusters/demo-cluster
echo $clusterId
export reader=$(az ad group create --display-name aksreader --mail-nickname aksreader --query objectId -o tsv)
echo $reader
export admin=$(az ad group create --display-name aksadmin --mail-nickname aksadmin --query objectId -o tsv)
echo $admin
## allows to get-creds
az role assignment create --assignee $reader --role "Azure Kubernetes Service Cluster User Role" --scope $clusterId
az role assignment create --assignee $admin --role "Azure Kubernetes Service Cluster User Role" --scope $clusterId
## assign at namespace scope
az role assignment create --assignee $admin --role "Azure Kubernetes Service RBAC Admin" --scope $clusterId/namespaces/at46993-dev
az role assignment create --assignee $reader --role "Azure Kubernetes Service RBAC Reader" --scope $clusterId/namespaces/at46993-prd

```
![](.\rbac-images\reader-roles.png)
![](.\rbac-images\admin-roles.png)

### Create Users
```
az ad user create --display-name "mr reader" --password "" --user-principal-name mr.reader@domain.onmicrosoft.com
az ad user create --display-name "mr admin" --password "" --user-principal-name mr.admin@domain.onmicrosoft.com
```

### Add users to Groups
```
az ad user show --id mr.reader@.onmicrosoft.com 
az ad user show --id mr.admin@.onmicrosoft.com 
```
```
az ad group member add --group "aksreader" --member-id 
az ad group member add --group "aksadmin" --member-id 
```
![](.\rbac-images\reader-members.png)
![](.\rbac-images\admin-members.png)

![](.\rbac-images\cluster-roles-assignment.png)






### Evidence Reader
```sh
az login --username mr.reader@.onmicrosoft.com --password 

az aks get-credentials --resource-group agicdemo --name agic-cluster --overwrite-existing --file ./kubeconfig-reader
export KUBECONFIG=./kubeconfig-reader

# Reader can view prod namespace but cannot delete or any other action
# Reader can only view specified namespace
```
![](.\rbac-images\reader.png)


### Evidence Admin
```sh
az login --username mr.admin@.onmicrosoft.com --password 

az aks get-credentials --resource-group agicdemo --name agic-cluster --overwrite-existing --file ./kubeconfig-admin
export KUBECONFIG=./kubeconfig-admin

# Admin can view dev namespace band create / delete pod
# Admin can only view specified namespace
```
![](.\rbac-images\admin.png)