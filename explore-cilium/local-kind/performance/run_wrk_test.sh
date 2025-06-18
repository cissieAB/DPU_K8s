#!/bin/bash

# Script to run wrk performance test and record results
# Usage: ./run_wrk_test.sh [cni_type] [duration] [connections] [threads]
# Example: ./run_wrk_test.sh default 30s 1000 8
# Example: ./run_wrk_test.sh cilium 30s 1000 8

CNI_TYPE=${1:-default}  # Default to "default" if no argument provided
DURATION=${2:-30s}      # Default duration: 30 seconds
CONNECTIONS=${3:-1000}  # Default connections: 1000 (high concurrency)
THREADS=${4:-8}         # Default threads: 8 (high concurrency)
RESULTS_FILE="wrk_results_${CNI_TYPE}_c${CONNECTIONS}_t${THREADS}.txt"

echo "Running wrk test with ${CNI_TYPE} CNI..."

# Get worker node names
WORKER_NODES=($(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}'))
if [ ${#WORKER_NODES[@]} -lt 2 ]; then
    echo "Error: Need at least 2 worker nodes for this test"
    exit 1
fi

# Create temporary YAML files with node selectors
cat > /tmp/wrk-server.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: http-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: http-server
  template:
    metadata:
      labels:
        app: http-server
    spec:
      nodeSelector:
        kubernetes.io/hostname: ${WORKER_NODES[0]}
      containers:
      - name: http-server
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: http-server
spec:
  selector:
    app: http-server
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Apply the server configuration
kubectl apply -f /tmp/wrk-server.yaml

# Wait for server to be ready
kubectl wait --for=condition=ready pod -l app=http-server --timeout=60s

# Get the server service IP
SERVER_IP=$(kubectl get service http-server -o jsonpath='{.spec.clusterIP}')

# Create wrk client pod YAML to run the test as entrypoint with shell
cat > /tmp/wrk-client.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: wrk-client
spec:
  nodeSelector:
    kubernetes.io/hostname: ${WORKER_NODES[1]}
  restartPolicy: Never
  containers:
  - name: wrk
    image: williamyeh/wrk:latest
    command: ["/bin/sh", "-c"]
    args: ["wrk -t${THREADS} -c${CONNECTIONS} -d${DURATION} http://${SERVER_IP}"]
EOF

# Apply the wrk client pod
kubectl apply -f /tmp/wrk-client.yaml

# Wait for wrk-client pod to complete
kubectl wait --for=condition=Succeeded pod/wrk-client --timeout=300s

# Run the wrk test and save the output
echo "=== wrk Test Results with ${CNI_TYPE} CNI ===" > $RESULTS_FILE
echo "Test started at: $(date)" >> $RESULTS_FILE
echo "Server IP: ${SERVER_IP}" >> $RESULTS_FILE
echo "Server Node: ${WORKER_NODES[0]}" >> $RESULTS_FILE
echo "Client Node: ${WORKER_NODES[1]}" >> $RESULTS_FILE
echo "Test parameters:" >> $RESULTS_FILE
echo "- Duration: ${DURATION}" >> $RESULTS_FILE
echo "- Connections: ${CONNECTIONS}" >> $RESULTS_FILE
echo "- Threads: ${THREADS}" >> $RESULTS_FILE
echo "----------------------------------------" >> $RESULTS_FILE

# Fetch wrk output from pod logs and append to results file
kubectl logs wrk-client | tee -a $RESULTS_FILE

echo "----------------------------------------" >> $RESULTS_FILE
echo "Test completed at: $(date)" >> $RESULTS_FILE

echo "wrk test completed. Results saved in ${RESULTS_FILE}"

# Clean up
kubectl delete -f /tmp/wrk-server.yaml
kubectl delete -f /tmp/wrk-client.yaml
rm /tmp/wrk-server.yaml /tmp/wrk-client.yaml 