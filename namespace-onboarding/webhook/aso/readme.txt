using this api  

https://azure.github.io/azure-service-operator/reference/containerservice/v1api20210501/

please update all field that you see in corespoding arm template arm.json

this should be in managedcluster.yaml that starts like
please break into commented sections like networking, security etc

here is the main arm page for ref https://learn.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters?pivots=deployment-language-arm-template
```
# compusolry fields
apiVersion: containerservice.azure.com/v1api20210501
kind: ManagedCluster
metadata:
  name: samplemanagedcluster
  namespace: default
spec:
  location: westeurope
  owner:
    name: aso-sample-rg
  dnsPrefix: aso
  agentPoolProfiles:
    - name: pool1
      count: 1
      vmSize: Standard_DS2_v2
      osType: Linux
      mode: System
  identity:
    type: SystemAssigned
```

| ARM Template Field                          | Description                                                        |
|---------------------------------------------|--------------------------------------------------------------------|
| location                                    | The location of the resource.                                      |
| dnsPrefix                                   | DNS prefix specified when creating the managed cluster.            |
| kubernetesVersion                           | Version of Kubernetes specified when creating the managed cluster. |
| agentPoolProfiles                           | Properties of the agent pool.                                      |
| agentPoolProfiles.count                     | Number of agents (VMs) to host docker containers.                  |
| agentPoolProfiles.vmSize                    | Size of agent VMs.                                                 |
| agentPoolProfiles.osType                    | OS Type of agent VMs.                                              |
| agentPoolProfiles.mode                      | AgentPool Mode represents mode of an agent pool.                   |
| networkProfile                              | Profile of network configuration.                                  |
| networkProfile.networkPlugin                | Network plugin used for building Kubernetes network.               |
| networkProfile.serviceCidr                  | A CIDR notation IP range from which to assign service cluster IPs. |
| networkProfile.dnsServiceIP                 | An IP address assigned to the Kubernetes DNS service.              |
| networkProfile.dockerBridgeCidr             | A CIDR notation IP for Docker bridge.                              |
| networkProfile.loadBalancerSku              | The load balancer sku for a Kubernetes cluster.                    |
| networkProfile.outboundType                 | The outbound (egress) routing method.                              |
| apiServerAccessProfile                      | Access profile for Kubernetes API server.                          |
| apiServerAccessProfile.enablePrivateCluster | Whether to create a private cluster.                               |
| identity                                    | The identity of the managed cluster, if configured.                |
| identity.type                               | The type of identity used for the managed cluster.                 |
| addonProfiles                               | Profile of managed cluster add-on.                                 |

