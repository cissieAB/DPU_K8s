# E2SAR Performance Testing in Kubernetes

This directory contains configuration files for running E2SAR (Event-to-Stream Application Runtime) performance tests in a Kubernetes environment. The setup uses Kubernetes Jobs to run sender and receiver components, with persistent storage for logs.

## Overview

The E2SAR performance test consists of:

1. **Sender Pod**: Sends a specified number of events to the receiver
2. **Receiver Pod**: Listens for events from the sender
3. **Log Viewer Pod**: Provides access to logs after the tests complete

The configuration uses persistent volumes to:
- Store logs from both sender and receiver for later analysis
- Enable direct pod-to-pod communication for optimal performance testing

## Configuration Files

- `e2sar-headless.yaml`: Implementation using a headless service for IP discovery (recommended)
- `kind-config.yaml`: KinD cluster configuration for local testing

## Setting Up the KinD Cluster

Before running the tests, you need to set up a Kubernetes in Docker (KinD) cluster using the provided configuration:

```bash
# Create a KinD cluster using the provided configuration
kind create cluster --config kind-config.yaml

# Verify the cluster is running
kubectl cluster-info --context kind-e2sar-cluster

# Check the nodes in the cluster
kubectl get nodes --context kind-e2sar-cluster
```

The `kind-config.yaml` file configures a cluster with:
- One control-plane node
- Two worker nodes with custom labels (`node=worker1` and `node=worker2`)
- IPv4 networking with pod subnet `10.244.0.0/16` and service subnet `10.96.0.0/16`

You can verify the node labels with:

```bash
kubectl get nodes --show-labels --context kind-e2sar-cluster
```

This is useful for performance testing to ensure sender and receiver pods run on different physical nodes.

## Running the Tests

To run the E2SAR performance tests:

```bash
# First, clean up any existing resources
kubectl delete namespace e2sar-perf --context kind-e2sar-cluster
# Wait for the namespace to be fully deleted
until kubectl get namespace e2sar-perf --context kind-e2sar-cluster 2>&1 | grep -q "not found"; do
  echo "Waiting for namespace to be deleted..."
  sleep 5
done

# Apply the headless service configuration
kubectl apply -f e2sar-headless.yaml --context kind-e2sar-cluster

# Check the status of the jobs
kubectl get jobs -n e2sar-perf --context kind-e2sar-cluster

# Check the status of the pods
kubectl get pods -n e2sar-perf --context kind-e2sar-cluster
```

## Accessing Logs

Logs are saved to a persistent volume and can be accessed through the log-viewer pod:

```bash
# Get the name of the log-viewer pod
LOG_VIEWER_POD=$(kubectl get pods -n e2sar-perf -l job-name=e2sar-log-viewer -o name --context kind-e2sar-cluster | cut -d/ -f2)

# View sender logs
kubectl exec -it -n e2sar-perf $LOG_VIEWER_POD --context kind-e2sar-cluster -- cat /logs/sender/sender.log

# View receiver logs
kubectl exec -it -n e2sar-perf $LOG_VIEWER_POD --context kind-e2sar-cluster -- cat /logs/receiver/receiver.log
```

The log-viewer pod remains running for 7 days after test completion to allow access to the logs.

## Configuration Parameters

### Sender Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| MTU | 512 | Maximum Transmission Unit in bytes |
| RATE | 0.1 | Sending rate in Gbps |
| LENGTH | 512 | Event length in bytes |
| NUM_EVENTS | 10000 | Number of events to send |
| BUF_SIZE | 32768 | Buffer size in bytes |
| DIRECT_MODE | true | Whether to use direct mode (no control plane) |

### Receiver Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| DURATION | 300 | Test duration in seconds |
| BUF_SIZE | 32768 | Buffer size in bytes |
| PORT | 19522 | Port to listen on |
| THREADS | 1 | Number of receiver threads |
| DIRECT_MODE | true | Whether to use direct mode (no control plane) |

## Modifying the Configuration

To modify the test parameters, edit the `e2sar-headless.yaml` file and update the environment variables in the sender and receiver container specifications.

For example, to increase the sending rate:

```yaml
export RATE="1.0"  # Change from 0.1 to 1.0 Gbps
```

Or to increase the test duration:

```yaml
- name: DURATION
  value: "600"  # Change from 300 to 600 seconds
```

## Troubleshooting

### Common Issues

1. **Sender can't connect to receiver**:
   - Check that the receiver pod is running
   - Verify the IP address being used by the sender
   - Check the logs of the init container: `kubectl logs -n e2sar-perf <sender-pod> -c wait-for-receiver --context kind-e2sar-cluster`
   - Ensure the DNS resolution is working correctly

2. **DNS resolution issues**:
   - Check that the service is correctly defined and has the right selector
   - Verify that the receiver pod has the correct labels
   - Try manually resolving the service: `kubectl exec -it -n e2sar-perf <any-pod> --context kind-e2sar-cluster -- nslookup e2sar-receiver-svc.e2sar-perf.svc.cluster.local`

3. **Logs not available**:
   - Check the status of the log-viewer pod
   - Ensure the persistent volume claims are bound
   - Check the logs of the log-saver containers

4. **Performance issues**:
   - Adjust resource limits in the pod specifications
   - Modify bandwidth annotations for network throttling

### Checking Pod Status

```bash
kubectl describe pod -n e2sar-perf <pod-name> --context kind-e2sar-cluster
```

### Checking Persistent Volumes

```bash
kubectl get pvc -n e2sar-perf --context kind-e2sar-cluster
```

### Checking Service and Endpoints

```bash
kubectl get service,endpoints -n e2sar-perf --context kind-e2sar-cluster
```

## Network Architecture

The E2SAR test uses direct pod-to-pod communication without any load balancer in between. The sender pod communicates directly with the receiver pod using the receiver's pod IP address, which is discovered via Kubernetes DNS resolution.

The traffic flows:
```
Sender Pod → Pod Network → Receiver Pod
```

### Kubernetes Networking Options

There are several ways to establish communication between pods in Kubernetes:

1. **Direct Pod-to-Pod Communication (current implementation)**
   - Uses the pod's IP address directly
   - Lowest latency and overhead
   - No service discovery or load balancing
   - Requires IP discovery mechanism (we use DNS resolution)
   - Pod IPs are ephemeral and change when pods restart

2. **ClusterIP Service**
   - Creates a stable virtual IP within the cluster
   - Provides service discovery via DNS (e.g., `e2sar-receiver-svc.e2sar-perf.svc.cluster.local`)
   - Performs load balancing if multiple pods match the selector
   - Adds a small network hop through kube-proxy
   - Example configuration:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: e2sar-receiver-svc
       namespace: e2sar-perf
     spec:
       selector:
         app: e2sar-receiver
       ports:
       - port: 19522
         targetPort: 19522
     ```

3. **Headless Service (current implementation)**
   - Similar to ClusterIP but without a cluster IP (sets `clusterIP: None`)
   - DNS resolves directly to individual pod IPs rather than to a service IP
   - **No load balancer or proxy** in the data path - traffic goes directly to pods
   - Only adds DNS resolution overhead during initial connection setup
   - Provides service discovery without the kube-proxy overhead
   - Particularly useful for stateful applications that need direct addressing
   - Example configuration:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: e2sar-receiver-svc
       namespace: e2sar-perf
     spec:
       clusterIP: None  # This makes it headless
       selector:
         app: e2sar-receiver
       ports:
       - port: 19522
         targetPort: 19522
     ```

4. **NodePort/LoadBalancer Services**
   - Expose services outside the cluster
   - Add more network hops and overhead
   - Not suitable for internal performance testing

### Why Direct Pod-to-Pod for E2SAR?

For the E2SAR performance tests, we chose direct pod-to-pod communication because:

1. **Performance**: Eliminates any overhead from service proxying
2. **Deterministic Routing**: No load balancing to introduce variability
3. **Simplicity**: Direct connection better represents the actual network performance
4. **Test Focus**: We're testing E2SAR performance, not Kubernetes service mechanisms

## Implementation Details

### Headless Service Implementation

The headless service implementation (`e2sar-headless.yaml`) achieves direct pod-to-pod communication through a sophisticated multi-step process:

#### 1. **Headless Service Definition**
The core of the implementation is a headless service that provides DNS resolution without load balancing:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: e2sar-receiver-svc
  namespace: e2sar-perf
spec:
  clusterIP: None  # This makes it a headless service
  selector:
    app: e2sar-receiver
  ports:
  - port: 19522
    targetPort: 19522
    protocol: TCP
    name: tcp
```

**Key Points:**
- `clusterIP: None` makes this a headless service
- DNS resolution returns actual pod IPs instead of a virtual service IP
- No load balancer or kube-proxy involvement in the data path

#### 2. **DNS Resolution in Init Container**
The sender pod uses an init container to discover the receiver's IP address:

```yaml
initContainers:
- name: wait-for-receiver
  image: busybox:1.28
  command: ["/bin/sh", "-c"]
  args:
  - |
    # Wait for the receiver service DNS to be available
    RECEIVER_SVC="e2sar-receiver-svc.e2sar-perf.svc.cluster.local"
    until nslookup $RECEIVER_SVC > /tmp/nslookup.out; do
      echo "Waiting for receiver service DNS to be available..."
      sleep 5
    done
    
    # Extract the receiver IP from the nslookup output
    RECEIVER_IP=$(grep "Address 1:" /tmp/nslookup.out | tail -n1 | awk '{print $3}')
    echo "Resolved receiver service IP: $RECEIVER_IP"
    
    # Wait a bit to ensure the receiver is fully ready
    sleep 5
    
    # Store the IP for the main container
    echo "export RECEIVER_IP=$RECEIVER_IP" > /shared-data/receiver-ip.env
  volumeMounts:
  - name: shared-data
    mountPath: /shared-data
```

**Process Flow:**
1. **DNS Query**: Uses `nslookup` to resolve the headless service name
2. **IP Extraction**: Parses the nslookup output to extract the actual pod IP
3. **IP Storage**: Saves the IP to a shared volume for the main container
4. **Race Condition Prevention**: Includes delays to ensure receiver readiness

#### 3. **Direct Pod-to-Pod Communication**
The sender container establishes a direct connection using the discovered IP:

```yaml
containers:
- name: sender
  image: jlabtsai/e2sar-container:latest
  command: ["/bin/bash", "-c"]
  args:
  - |
    # Source the receiver IP from the init container
    source /shared-data/receiver-ip.env
    echo "Using receiver IP: $RECEIVER_IP"
    
    export IP="0.0.0.0"
    export URI="ejfat://useless@10.10.10.10:1234/lb/1?data=${RECEIVER_IP}:19522&sync=192.168.77.7:1234"
    export MTU="512"
    export RATE="0.1"
    export LENGTH="512"
    export NUM_EVENTS="10000"
    export BUF_SIZE="32768"
    export DIRECT_MODE="true"
    /app/entrypoint-sender.sh 2>&1 | tee /shared-logs/sender.log
  volumeMounts:
  - name: shared-logs
    mountPath: /shared-logs
  - name: shared-data
    mountPath: /shared-data
```

**Key Features:**
- **Direct Connection**: Uses `${RECEIVER_IP}` directly in the URI
- **No Intermediary**: No service IP, load balancer, or proxy involved
- **Performance Optimized**: Minimal network overhead

#### 4. **Shared Volume for Inter-Container Communication**
The implementation uses an emptyDir volume to pass data between containers:

```yaml
volumes:
- name: shared-data
  emptyDir: {}
```

This volume allows the init container to write the discovered IP and the main container to read it.

### Complete Communication Flow

The entire process follows this sequence:

1. **Service Creation**: Headless service is created with `clusterIP: None`
2. **Receiver Pod Start**: Receiver pod starts and gets assigned a pod IP
3. **DNS Registration**: Kubernetes DNS registers the pod IP for the headless service
4. **Sender Init**: Init container resolves DNS to discover receiver's pod IP
5. **IP Discovery**: `nslookup` returns the actual pod IP address
6. **IP Storage**: IP is saved to shared volume
7. **Direct Connection**: Sender connects directly to receiver's pod IP
8. **Data Transfer**: E2SAR performance testing begins with direct pod-to-pod communication

### Why This Achieves True Direct Pod-to-Pod Communication

1. **No Load Balancer**: `clusterIP: None` eliminates the service IP layer
2. **No kube-proxy**: Traffic doesn't traverse iptables rules for service routing
3. **Direct DNS Resolution**: DNS resolves directly to pod IP, not service IP
4. **Minimal Overhead**: Only DNS resolution overhead during connection setup
5. **Deterministic Path**: Consistent network path for all data packets

### Log Persistence

The implementation uses a persistent volume to store logs from the sender and receiver pods. This allows you to access the logs even after the pods have completed their tasks.

The log-viewer pod mounts the same persistent volume and provides access to the logs for 7 days after test completion.

## Network Policy

The configuration includes a NetworkPolicy that allows all traffic. In a production environment, you might want to restrict this to only allow the necessary communication between sender and receiver:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: e2sar-network-policy
  namespace: e2sar-perf
spec:
  podSelector:
    matchLabels:
      app: e2sar-receiver
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: e2sar-sender
    ports:
    - protocol: TCP
      port: 19522
``` 