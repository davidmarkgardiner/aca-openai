### Creating a certificate in a Kubernetes ConfigMap and mounting it to a Pod involves several steps. Below is a basic example to demonstrate how you can achieve this.

1. Create a Certificate
Assume you have a certificate file named tls.crt and a private key file named tls.key.

2. Create a ConfigMap
You can store these files in a Kubernetes ConfigMap.


# configmap.yaml
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-cert-configmap
data:
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    MIIC+zCCAeOgAwIBAgI...
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANB...
    -----END PRIVATE KEY-----
```
In this YAML, replace the tls.crt and tls.key content with your actual certificate and key content.

3. Create a Pod that Mounts the ConfigMap
Next, you create a Pod that mounts this ConfigMap as a volume.

# pod.yaml
```
apiVersion: v1
kind: Pod
metadata:
  name: my-cert-pod
spec:
  containers:
  - name: my-container
    image: nginx:latest
    volumeMounts:
    - name: certs
      mountPath: "/etc/tls"
      readOnly: true
  volumes:
  - name: certs
    configMap:
      name: my-cert-configmap
      items:
      - key: tls.crt
        path: tls.crt
      - key: tls.key
        path: tls.key
```

4. Apply the ConfigMap and Pod
Apply the ConfigMap and Pod to your Kubernetes cluster:

```
kubectl apply -f configmap.yaml
kubectl apply -f pod.yaml
```
5. Verify the Certificate Mounting
Once the Pod is running, you can verify that the certificate is correctly mounted by accessing the Pod’s filesystem:

```
kubectl exec -it my-cert-pod -- ls /etc/tls/
```
You should see tls.crt and tls.key listed. You can also check the content of these files:

```
kubectl exec -it my-cert-pod -- cat /etc/tls/tls.crt
kubectl exec -it my-cert-pod -- cat /etc/tls/tls.key
```

Explanation:
ConfigMap: The ConfigMap named my-cert-configmap stores the certificate and key.
Pod: The Pod named my-cert-pod mounts the ConfigMap to /etc/tls in the container as a read-only volume.
VolumeMounts: volumeMounts define where in the container’s filesystem the ConfigMap should be mounted.
This setup allows your application inside the Pod to use the certificate files located at /etc/tls/tls.crt and /etc/tls/tls.key.