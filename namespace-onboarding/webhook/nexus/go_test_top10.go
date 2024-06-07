// Test API server connectivity
func TestAPIServer(t *testing.T) {

config, err := clientcmd.BuildConfigFromFlags("", "/path/to/kubeconfig")
if err != nil {
  t.Fatal(err)
}

client, err := kubernetes.NewForConfig(config) 
if err != nil {
  t.Fatal(err)
}

// Make simple API request to validate connectivity
_, err = client.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
if err != nil {
  t.Errorf("Error querying API server: %v", err) 
}
}

// Check node count
func TestNodeCount(t *testing.T) {

nodes, err := client.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})

if len(nodes.Items) != 3 {
  t.Errorf("Expected 3 nodes, got %d", len(nodes.Items))
}
}

// Test service load balancing
func TestServiceLB(t *testing.T) {

// Create service 
svc := client.CoreV1().Services(ns).Create(context.TODO(), myService)

// Loop through service IP multiple times
for i:=0; i<10; i++ { 
  resp, err := http.Get(svc.Spec.ClusterIP)
  // Verify request success
}

// Check all pod backends were hit 
}

// Validate HPA
func TestHPA(t *testing.T) {

// Create HPA
hpa := client.AutoscalingV2beta2().HorizontalPodAutoscalers(ns).Create(context.TODO(), myHPA)

// Generate load
hey.Run("http://hpa-svc", hey.WithLoad("10", "30s"))

// Check HPA status
hpa, err := client.AutoscalingV2beta2().HorizontalPodAutoscalers(ns).Get(context.TODO(), hpaName, metav1.GetOptions{})

if hpa.Status.DesiredReplicas != 3 {
  t.Errorf("Expected 3 replicas, got %d", hpa.Status.DesiredReplicas)
}
}