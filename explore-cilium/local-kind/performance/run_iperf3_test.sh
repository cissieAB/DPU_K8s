#!/bin/bash

# Script to run iperf3 test and record results
# Usage: ./run_iperf3_test.sh [cni_type]
# Example: ./run_iperf3_test.sh default
# Example: ./run_iperf3_test.sh cilium

CNI_TYPE=${1:-default}  # Default to "default" if no argument provided
RESULTS_FILE="iperf3_results_${CNI_TYPE}.txt"

echo "Running iperf3 test with ${CNI_TYPE} CNI..."

# Get worker node names
WORKER_NODES=($(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}'))
if [ ${#WORKER_NODES[@]} -lt 2 ]; then
    echo "Error: Need at least 2 worker nodes for this test"
    exit 1
fi

# Create temporary YAML files with node selectors
cat > /tmp/iperf3-server.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: iperf3-server
spec:
  nodeSelector:
    kubernetes.io/hostname: ${WORKER_NODES[0]}
  containers:
  - name: iperf3
    image: networkstatic/iperf3
    args: ["-s"]
    ports:
    - containerPort: 5201
---
apiVersion: v1
kind: Service
metadata:
  name: iperf3-server
spec:
  selector:
    app: iperf3-server
  ports:
  - port: 5201
    targetPort: 5201
  type: ClusterIP
EOF

cat > /tmp/iperf3-client.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: iperf3-client
spec:
  nodeSelector:
    kubernetes.io/hostname: ${WORKER_NODES[1]}
  containers:
  - name: iperf3
    image: networkstatic/iperf3
    command: ["sleep", "3600"]
EOF

# Apply the configurations
kubectl apply -f /tmp/iperf3-server.yaml
kubectl apply -f /tmp/iperf3-client.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod/iperf3-server pod/iperf3-client --timeout=60s

# Get the server pod IP
SERVER_IP=$(kubectl get pod iperf3-server -o jsonpath='{.status.podIP}')

# Run the iperf3 test and save the output
echo "=== iperf3 Test Results with ${CNI_TYPE} CNI ===" > $RESULTS_FILE
echo "Test started at: $(date)" >> $RESULTS_FILE
echo "Server IP: ${SERVER_IP}" >> $RESULTS_FILE
echo "Server Node: ${WORKER_NODES[0]}" >> $RESULTS_FILE
echo "Client Node: ${WORKER_NODES[1]}" >> $RESULTS_FILE
echo "----------------------------------------" >> $RESULTS_FILE
kubectl exec -it iperf3-client -- iperf3 -c $SERVER_IP >> $RESULTS_FILE
echo "----------------------------------------" >> $RESULTS_FILE
echo "Test completed at: $(date)" >> $RESULTS_FILE

echo "iperf3 test completed. Results saved in ${RESULTS_FILE}"

# Clean up
kubectl delete -f /tmp/iperf3-server.yaml
kubectl delete -f /tmp/iperf3-client.yaml
rm /tmp/iperf3-server.yaml /tmp/iperf3-client.yaml 