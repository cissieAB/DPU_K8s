# E2SAR Kubernetes Architecture

## Kubernetes Deployment: Key Concepts and Implementation

### Understanding Our Kubernetes Approach

Deploying the E2SAR performance testing framework in Kubernetes involves several key concepts that are important to understand, even if you're new to Kubernetes:

#### 1. Pod-to-Pod Communication Challenge

In Kubernetes, applications typically communicate through Services, which act as stable network endpoints. However, for performance testing, we need direct pod-to-pod communication to minimize network overhead:

```
Traditional Kubernetes:
Pod → Service → Pod (adds latency)

Our Approach:
Pod → Pod (direct, lower latency)
```

The challenge is: How do pods find each other without a traditional Service intermediary?

#### 2. Our Solution: Headless Service Discovery

We use a "headless" service - a special Kubernetes service that doesn't load-balance traffic but provides DNS entries for direct pod access:

```yaml
kind: Service
metadata:
  name: e2sar-receiver-svc
spec:
  clusterIP: None  # This makes it headless
  selector:
    app: e2sar-receiver
```

This creates a DNS entry that resolves directly to pod IPs rather than to a virtual service IP.

#### 3. How Pods Find Each Other

Our sender pod uses a simple but effective approach to find the receiver:

1. **Init Container**: A specialized container that runs before the main application:
   ```yaml
   initContainers:
   - name: wait-for-receiver
     image: busybox:1.28
     command: ["/bin/sh", "-c"]
     args:
     - |
       # Look up the receiver's address using DNS
       RECEIVER_SVC="e2sar-receiver-svc.e2sar-perf.svc.cluster.local"
       until nslookup $RECEIVER_SVC > /tmp/nslookup.out; do
         echo "Waiting for receiver..."
         sleep 5
       done
       
       # Save the IP address for the main container
       RECEIVER_IP=$(grep "Address 1:" /tmp/nslookup.out | tail -n1 | awk '{print $3}')
       echo "export RECEIVER_IP=$RECEIVER_IP" > /shared-data/receiver-ip.env
   ```

   **How nslookup works with headless services:**
   
   `nslookup` is a standard networking utility tool (not Kubernetes-specific) that queries DNS servers to obtain domain name or IP address mapping information. It comes pre-installed in many Linux distributions and container images like BusyBox that we use in our init container.
   
   When we run `nslookup e2sar-receiver-svc.e2sar-perf.svc.cluster.local`, the following happens:
   
   1. The DNS query is sent to the Kubernetes DNS service (CoreDNS or kube-dns)
   2. For a regular service, DNS would return the ClusterIP of the service
   3. For a headless service (`clusterIP: None`), DNS instead returns the actual IP addresses of all pods matching the service selector
   4. The nslookup output looks something like this:
      ```
      Server:    10.96.0.10
      Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

      Name:      e2sar-receiver-svc.e2sar-perf.svc.cluster.local
      Address 1: 10.244.2.48 e2sar-receiver-mxpbd.e2sar-perf.svc.cluster.local
      ```
   5. The script extracts the pod IP address (10.244.2.48 in this example) using grep and awk
   6. This direct pod IP is what enables direct pod-to-pod communication

   **DNS resolution with multiple pods:**
   
   If multiple receiver pods exist, the nslookup would return multiple IPs:
   ```
   Name:      e2sar-receiver-svc.e2sar-perf.svc.cluster.local
   Address 1: 10.244.2.48 e2sar-receiver-1.e2sar-perf.svc.cluster.local
   Address 2: 10.244.3.21 e2sar-receiver-2.e2sar-perf.svc.cluster.local
   ```
   
   Our script takes the first IP by using `tail -n1`, but could be modified to select a specific pod or distribute connections across multiple receivers.

2. **Shared Volume**: A temporary storage space shared between containers in the same pod:
   ```yaml
   volumes:
   - name: shared-data
     emptyDir: {}
   ```

3. **Main Container**: Reads the IP and connects directly:
   ```yaml
   source /shared-data/receiver-ip.env
   echo "Using receiver IP: $RECEIVER_IP"
   ```

**Advantages over standard service discovery:**

Unlike using a standard Kubernetes service where kube-proxy would load balance connections:

1. **No Proxying**: Traffic goes directly from sender to receiver pod
2. **No Load Balancing**: We get a consistent connection to the same pod
3. **Deterministic Networking**: The network path remains consistent for all tests
4. **Lower Latency**: Eliminating the kube-proxy layer reduces latency

**Potential challenges:**

1. **Race Conditions**: If the receiver pod is restarting, DNS might return its IP before it's ready
2. **DNS Caching**: Some Kubernetes environments aggressively cache DNS, which could return stale IPs
3. **Multiple Receivers**: With multiple receiver pods, we need logic to select the appropriate one

Our init container addresses these challenges by continuously polling until a valid IP is found, ensuring the receiver is ready before the sender starts.

#### 4. Jobs vs. Long-Running Services

Unlike typical applications that run continuously, our performance tests run to completion:

```yaml
kind: Job  # Not Deployment or StatefulSet
spec:
  ttlSecondsAfterFinished: 100  # Auto-cleanup after completion
  template:
    spec:
      restartPolicy: Never  # Run once and exit
```

This "Job" approach is perfect for tests that:
- Run for a specific duration
- Process a fixed amount of data
- Need to report results and exit

#### 5. Persistent Logs for Analysis

Performance test results must survive after the test completes. We solve this with:

1. **Persistent Volume**: Storage that exists independently of pods:
   ```yaml
   kind: PersistentVolumeClaim
   metadata:
     name: logs-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 10Mi
   ```

2. **Log Saver Container**: A helper container that copies logs to persistent storage:
   ```yaml
   - name: log-saver
     image: busybox:1.28
     command: ["/bin/sh", "-c"]
     args:
     - |
       # Copy logs to persistent storage
       cp /shared-logs/sender.log /logs/sender/
   ```

3. **Log Viewer Pod**: A long-running pod that provides access to test results:
   ```yaml
   kind: Job
   metadata:
     name: e2sar-log-viewer
   spec:
     ttlSecondsAfterFinished: 604800  # Keep for 7 days
   ```

#### 6. Resource Control for Consistent Testing

To ensure test consistency, we explicitly control resources:

```yaml
resources:
  requests:
    cpu: "100m"     # 0.1 CPU cores
    memory: "128Mi" # 128 MB memory
  limits:
    cpu: "200m"
    memory: "256Mi"
```

We also control network bandwidth using annotations:
```yaml
annotations:
  kubernetes.io/ingress-bandwidth: "100M"
  kubernetes.io/egress-bandwidth: "100M"
```

## Process Flow Diagrams

The following diagrams illustrate the key processes in our E2SAR Kubernetes setup:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                             │
│                         E2SAR Process Flow Diagram                                          │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  1. Receiver IP Acquisition Process                                                         │
│                                                                                             │
│    ┌───────────────┐     ┌───────────────┐     ┌───────────────┐     ┌───────────────┐     │
│    │ Sender's Init │     │  Kubernetes   │     │   Headless    │     │  Receiver     │     │
│    │  Container    │     │  DNS Service  │     │   Service     │     │  Pod IP       │     │
│    │ [e2sar-sender]│────►│               │────►│[e2sar-receiver-svc]─►│[e2sar-receiver]│   │
│    └───────────────┘     └───────────────┘     └───────────────┘     └───────────────┘     │
│           │                                                                 │               │
│           │                                                                 │               │
│           ▼                                                                 │               │
│    ┌───────────────┐                                                        │               │
│    │  IP Written   │                                                        │               │
│    │  to Shared    │◄───────────────────────────────────────────────────────┘               │
│    │  Volume       │                                                                        │
│    └───────────────┘                                                                        │
│           │                                                                                 │
│           │                                                                                 │
│           ▼                                                                                 │
│    ┌───────────────┐     ┌───────────────┐                                                  │
│    │ Sender Main   │     │ Direct TCP/UDP│                                                  │
│    │ Container     │     │ Connection to │                                                  │
│    │ [e2sar-sender]│────►│ Receiver      │                                                  │
│    └───────────────┘     └───────────────┘                                                  │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  2. Log Collection Process                                                                  │
│                                                                                             │
│    ┌───────────────┐                     ┌───────────────┐                                  │
│    │ Sender        │                     │ Receiver      │                                  │
│    │ Container     │                     │ Container     │                                  │
│    │ [e2sar-sender]│                     │[e2sar-receiver]│                                 │
│    └───────┬───────┘                     └───────┬───────┘                                  │
│            │                                     │                                          │
│            ▼                                     ▼                                          │
│    ┌───────────────┐                     ┌───────────────┐                                  │
│    │ Output to     │                     │ Output to     │                                  │
│    │ stdout/stderr │                     │ stdout/stderr │                                  │
│    └───────┬───────┘                     └───────┬───────┘                                  │
│            │                                     │                                          │
│            ▼                                     ▼                                          │
│    ┌───────────────┐                     ┌───────────────┐                                  │
│    │ Shared Volume │                     │ Shared Volume │                                  │
│    │ (emptyDir)    │                     │ (emptyDir)    │                                  │
│    └───────┬───────┘                     └───────┬───────┘                                  │
│            │                                     │                                          │
│            ▼                                     ▼                                          │
│    ┌───────────────┐                     ┌───────────────┐                                  │
│    │ Log-saver     │                     │ Log-saver     │                                  │
│    │ Container     │                     │ Container     │                                  │
│    │ [e2sar-sender]│                     │[e2sar-receiver]│                                 │
│    └───────┬───────┘                     └───────┬───────┘                                  │
│            │                                     │                                          │
│            └─────────────────┬───────────────────┘                                          │
│                              │                                                              │
│                              ▼                                                              │
│                      ┌───────────────┐                                                      │
│                      │ Persistent    │                                                      │
│                      │ Volume (PVC)  │                                                      │
│                      │ [logs-pvc]    │                                                      │
│                      └───────┬───────┘                                                      │
│                              │                                                              │
│                              ▼                                                              │
│                      ┌───────────────┐     ┌───────────────┐                                │
│                      │ Log-viewer    │     │ User Access   │                                │
│                      │ Container     │     │ via kubectl   │                                │
│                      │[e2sar-log-viewer]──►│ exec          │                                │
│                      └───────────────┘     └───────────────┘                                │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Why This Approach Matters

This architecture provides several benefits:

1. **Realistic Performance Testing**: Direct pod-to-pod communication mimics real-world data paths
2. **Reproducible Results**: Resource controls ensure consistent test environments
3. **Self-Contained Tests**: Each test runs independently with its own resources
4. **Persistent Results**: Test data remains available after completion
5. **Kubernetes-Native**: Uses standard Kubernetes patterns rather than custom solutions

By understanding these key concepts, you can better grasp how our E2SAR performance testing framework leverages Kubernetes capabilities while addressing the unique requirements of performance testing. 