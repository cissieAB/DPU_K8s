#!/bin/bash

# Start minikube with 2 nodes (1 control plane + 1 worker)
echo "Starting minikube cluster..."
minikube start --nodes 2 --driver=docker --cpus=2 --memory=4096

# Add worker node label
echo "Labeling worker node..."
kubectl label nodes minikube-m02 node-role.kubernetes.io/worker=worker

# Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
kubectl wait --for=condition=ready node --all --timeout=300s

# Build the E2SAR container image
echo "Building E2SAR container image..."
eval $(minikube docker-env)
docker build -t e2sar-container ../run-E2SAR/container/

# Deploy the receiver
echo "Deploying E2SAR receiver..."
kubectl apply -f k8s/e2sar-receiver.yaml

# Wait for receiver pod to be ready
echo "Waiting for receiver pod to be ready..."
kubectl wait --for=condition=ready pod -l app=e2sar-receiver --timeout=300s

# Get receiver pod IP and create ConfigMap
echo "Creating ConfigMap with receiver IP..."
RECEIVER_IP=$(kubectl get pod -l app=e2sar-receiver -o jsonpath='{.items[0].status.podIP}')
kubectl create configmap e2sar-config --from-literal=receiver_ip=$RECEIVER_IP

# Deploy the sender
echo "Deploying E2SAR sender..."
kubectl apply -f k8s/e2sar-sender.yaml

# Wait for sender pod to be ready
echo "Waiting for sender pod to be ready..."
kubectl wait --for=condition=ready pod -l app=e2sar-sender --timeout=300s

echo "Deployment complete!"
echo "Receiver service is exposed on NodePort 30522"
echo "You can monitor the pods with: kubectl get pods -w"
echo "View logs with:"
echo "  kubectl logs -f deployment/e2sar-receiver"
echo "  kubectl logs -f deployment/e2sar-sender" 