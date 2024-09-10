To get started with HashiCorp Vault's Kubernetes Injector, here’s a step-by-step guide:

### 1. **Install Vault and the Agent Injector**  
Use Helm to install Vault alongside the Vault Agent Injector in your Kubernetes cluster. First, add the HashiCorp Helm repository and install Vault with the injector enabled:
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --set="injector.enabled=true"
```
Ensure that Vault is version 1.3.1 or greater. You can customize values like namespaces, TLS options, and more by inspecting the chart values.

### 2. **Configure TLS for the Injector**  
The Agent Injector requires TLS to function properly. By default, it uses auto-generated certificates, but you can also manually configure TLS if necessary. To set specific TLS versions or cipher suites, adjust Helm parameters:
```bash
helm install vault hashicorp/vault --set="injector.extraEnvironmentVars.AGENT_INJECT_TLS_MIN_VERSION=tls13"
```
TLS 1.2 and above is recommended for security【8†source】.

### 3. **Annotating Your Kubernetes Workloads**  
To inject secrets into your workloads, annotate the pod spec in your Kubernetes deployment or StatefulSet. Example annotations:
```yaml
vault.hashicorp.com/agent-inject: 'true'
vault.hashicorp.com/agent-inject-secret-db-creds: 'database/creds/db-app'
vault.hashicorp.com/agent-inject-template-db-creds: |
  {{- with secret "database/creds/db-app" -}}
  postgres://{{ .Data.username }}:{{ .Data.password }}@postgres:5432/appdb?sslmode=disable
  {{- end }}
```
These annotations will inject a sidecar container into your pod to pull secrets from Vault【9†source】【10†source】.

### 4. **Managing Resources**  
Control resource usage for the Vault Agent with annotations like CPU and memory limits:
```yaml
vault.hashicorp.com/agent-limits-cpu: "500m"
vault.hashicorp.com/agent-limits-mem: "128Mi"
```
Additionally, you can configure options such as whether the agent token is revoked upon shutdown or if the agent should pre-populate secrets before the app starts【10†source】.

### 5. **Using ConfigMaps for Advanced Configuration**  
You can also inject Vault Agent configurations using a Kubernetes ConfigMap:
```yaml
vault.hashicorp.com/agent-configmap: 'my-configmap'
```
This allows for more complex setups such as handling dynamic credentials, defining templates, and specifying auto-auth configurations【9†source】.

This should give you a good foundation for using the Vault Agent Injector in Kubernetes! For detailed use cases and examples, refer to the official [HashiCorp documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/injector).