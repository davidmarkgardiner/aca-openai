https://kubernetes.io/docs/concepts/policy/resource-quotas/#resource-quota-for-extended-resources

In Kubernetes, memory requests and memory limits are two aspects of how much memory a container can use, and they serve different purposes:

1. **Memory Requests**: This is the amount of memory that a container is guaranteed to have. The Kubernetes scheduler uses this value to decide on which nodes to place Pods. If a node doesn't have enough free memory to satisfy the Pod's memory request, the Pod won't be scheduled on that node. 

2. **Memory Limits**: This is the maximum amount of memory that a container can use. If a container exceeds this limit, it might be terminated. If it continues to exceed the limit, it might be killed.

In the context of Resource Quotas, these two values are used to control how much memory Pods in a namespace can request and use. For example, if you set a memory request quota of 1GB, the total memory requests of all Pods in the namespace can't exceed 1GB. Similarly, if you set a memory limit quota of 2GB, the total memory usage of all Pods in the namespace can't exceed 2GB.

It's important to set these values carefully. If you set the memory request too high, you might not be able to schedule any Pods. If you set the memory limit too low, your Pods might be constantly killed and restarted.


Kubernetes defines Limits as the maximum amount of a resource to be used by a container. This means that the container can never consume more than the memory amount or CPU amount indicated. 

Requests, on the other hand, are the minimum guaranteed amount of a resource that is reserved for a container.

apiVersion: v1
kind: ResourceQuota
metadata:
  name: example-quota
spec:
  hard:
    requests.cpu: "1" # 1 CPU
    requests.memory: 1Gi # 1 GiB of memory
    requests.storage: 10Gi # 10 GiB of storage
    limits.cpu: "2" # 2 CPUs
    limits.memory: 2Gi # 2 GiB of memory

## TODO
- logic for hard limit.. this can be double amount reserved?
- we can tag for high/ low resource so we can use to herd / bill later