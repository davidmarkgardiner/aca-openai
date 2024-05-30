## Azure Service Operator

I would like to setup an app with various 

## Reoources
[ASO](https://azure.github.io/azure-service-operator/)
[Supported Resources](https://azure.github.io/azure-service-operator/reference/)
[Tutorials](https://azure.github.io/azure-service-operator/tutorials/)
[Tooles](https://azure.github.io/azure-service-operator/tools/)

[GitHub}(https://github.com/Azure/azure-service-operator)
[Examples](https://github.com/Azure/azure-service-operator/blob/main/v2/samples/containerservice/v1api20210501/v1api20210501_managedcluster.yaml)

## Dependencies
1. setup credentials
2. asoctl must have read permissions on rsources

## Asoctl
INstallll and Import Resoucres [using](https://azure.github.io/azure-service-operator/tools/asoctl/)
> Must have read data action on rsources

## Ideas for demo 
### AKS
1. aks stack with rg, des, vnet, kv, uami, fgederated credentuial, dns

### Pods
2. [Cosmosdb with uami](https://github.com/Azure-Samples/azure-service-operator-samples/tree/master/cosmos-todo-list-mi)
3. [Cosmosdb](https://github.com/Azure-Samples/azure-service-operator-samples/tree/master/cosmos-todo-list)
4. [PostGresSQL](https://github.com/Azure-Samples/azure-service-operator-samples/tree/master/cosmos-todo-list)
5. [Reedis](https://github.com/Azure-Samples/azure-service-operator-samples/tree/master/azure-votes-redis)

6. workload Identity + KV
7. Storge, disk/ file

### Demo for web app
1. Site, with stroage and sql db