#!/bin/bash

# Script to run HTTP performance test and record results
# Usage: ./run_http_test.sh [cni_type] [duration] [requests] [concurrency]
# Example: ./run_http_test.sh default 30 1000 10
# Example: ./run_http_test.sh cilium 30 1000 10

CNI_TYPE=${1:-default}  # Default to "default" if no argument provided
DURATION=${2:-30}       # Default duration: 30 seconds
REQUESTS=${3:-1000}     # Default requests: 1000
CONCURRENCY=${4:-10}    # Default concurrency: 10
RESULTS_FILE="http_results_${CNI_TYPE}_c${CONCURRENCY}.txt"

echo "Running HTTP test with ${CNI_TYPE} CNI (Concurrency: ${CONCURRENCY})..."

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

# Run the HTTP test and save the output
echo "=== HTTP Test Results with ${CNI_TYPE} CNI ===" > $RESULTS_FILE
echo "Test started at: $(date)" >> $RESULTS_FILE
echo "Server IP: ${SERVER_IP}" >> $RESULTS_FILE
echo "Server Node: ${WORKER_NODES[0]}" >> $RESULTS_FILE
echo "Client Node: ${WORKER_NODES[1]}" >> $RESULTS_FILE
echo "Test parameters:" >> $RESULTS_FILE
echo "- Duration: ${DURATION}s" >> $RESULTS_FILE
echo "- Total Requests: ${REQUESTS}" >> $RESULTS_FILE
echo "- Concurrency: ${CONCURRENCY}" >> $RESULTS_FILE
echo "----------------------------------------" >> $RESULTS_FILE

# Run the test using a temporary pod with Apache Benchmark on the second worker node
kubectl run -it --rm --restart=Never http-test \
    --image=jordi/ab \
    --overrides="{\"spec\": {\"nodeSelector\": {\"kubernetes.io/hostname\": \"${WORKER_NODES[1]}\"}}}" \
    -- \
    -n ${REQUESTS} \
    -c ${CONCURRENCY} \
    -t ${DURATION} \
    http://${SERVER_IP}/ >> $RESULTS_FILE

echo "----------------------------------------" >> $RESULTS_FILE
echo "Test completed at: $(date)" >> $RESULTS_FILE

echo "HTTP test completed. Results saved in ${RESULTS_FILE}"

# Clean up
kubectl delete -f /tmp/wrk-server.yaml
rm /tmp/wrk-server.yaml 