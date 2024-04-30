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

## Further Explaniation

In Kubernetes, `requests` and `limits` are two different parameters you can set to control the resources a container is guaranteed and the resources a container can use.

- `Requests`: This is the amount of a specific resource that the system will guarantee to the container. For example, if you set a memory request of 256Mi for a container, Kubernetes will ensure that the container always has 256Mi of memory available.

- `Limits`: This is the maximum amount of a specific resource that a container is allowed to exceed. For example, if you set a memory limit of 512Mi for a container, the container is allowed to use more than its requested 256Mi of memory but is not allowed to use more than 512Mi.

In the context of a ResourceQuota, these parameters are used to control the total amount of resources that can be requested or limited by all the containers in a namespace.

- `requests.cpu`, `requests.memory`, `requests.storage`, and `requests.ephemeral-storage` quota the total amount of resources that can be requested by containers in the namespace.

- `limits.cpu`, `limits.memory`, and `limits.ephemeral-storage` quota the total amount of resources that can be used by containers in the namespace.

If a container exceeds its memory limit, it could be terminated. If it exceeds its CPU limit, it could be throttled.

## Requests and limits 
If the node where a Pod is running has enough of a resource available, it's possible (and allowed) for a container to use more resource than its request for that resource specifies. However, a container is not allowed to use more than its resource limit.

For example, if you set a memory request of 256 MiB for a container, and that container is in a Pod scheduled to a Node with 8GiB of memory and no other Pods, then the container can try to use more RAM.

If you set a memory limit of 4GiB for that container, the kubelet (and container runtime) enforce the limit. The runtime prevents the container from using more than the configured resource limit. For example: when a process in the container tries to consume more than the allowed amount of memory, the system kernel terminates the process that attempted the allocation, with an out of memory (OOM) error.

Limits can be implemented either reactively (the system intervenes once it sees a violation) or by enforcement (the system prevents the container from ever exceeding the limit). Different runtimes can have different ways to implement the same restrictions.


## Rolling Update

In Kubernetes, `requests` and `limits` are different parameters that you can set to control the resources a container is guaranteed and the resources a container can use.

- `Requests`: This is the amount of a specific resource that the system will guarantee to the container. If you set a CPU request of 1Gi for a container, Kubernetes will ensure that the container always has 1Gi of CPU available.

- `Limits`: This is the maximum amount of a specific resource that a container is allowed to use. If you set a CPU limit of 2Gi for a container, the container is allowed to use up to 2Gi of CPU.

If you need to run 10 pods, each requesting 1Gi of CPU and 1Gi of memory, you should set the resource quota for the namespace to at least 10Gi of CPU and 10Gi of memory to accommodate the `requests`. This will ensure that each pod gets the resources it needs.

However, if you want to allow for rolling updates, you should consider the maximum number of pods that could be running at the same time during the update process. If you update the pods one at a time, you might need resources for an extra pod during the update, so you would set the resource quota to 11Gi. If you update the pods in larger batches, you would need to increase the resource quota accordingly.

The same logic applies to the `limits`. If each pod has a limit of 2Gi of CPU and 2Gi of memory, and you want to allow for rolling updates, you should set the resource quota for the limits to accommodate the maximum number of pods that could be running at the same time.
