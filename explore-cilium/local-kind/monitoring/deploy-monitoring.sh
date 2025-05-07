#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to cleanup port-forward
cleanup() {
    print_status "Cleaning up..."
    pkill -f "kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090" || true
    exit 0
}

# Set up trap for cleanup
trap cleanup SIGINT SIGTERM

print_status "Starting Cilium monitoring deployment..."

# Create monitoring namespace if it doesn't exist
print_status "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Prometheus Helm repo if not already added
print_status "Adding Prometheus Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy Prometheus using Helm
print_status "Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values prometheus-values.yaml \
    --wait

# Apply ServiceMonitor configurations
print_status "Applying ServiceMonitor configurations..."
kubectl apply -f service-monitor.yaml

# Wait for Prometheus to be ready
print_status "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Kill any existing port-forward process
print_status "Cleaning up any existing port-forward processes..."
pkill -f "kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090" || true

# Set up port-forwarding for Prometheus
print_status "Setting up port-forwarding for Prometheus..."
print_status "Prometheus will be available at http://localhost:9090"
print_status "Press Ctrl+C to stop port-forwarding"

# Start port-forwarding in background
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
PF_PID=$!

# Wait for port-forward to be ready
sleep 5

# Check if port-forward is working
if ! curl -s http://localhost:9090/-/healthy > /dev/null; then
    print_error "Failed to connect to Prometheus. Please check the logs above."
    cleanup
    exit 1
fi

print_status "Prometheus is ready! You can now access it at http://localhost:9090"
print_status "To check Cilium metrics, run: ./check-cilium-metrics.sh"

# Keep script running and handle cleanup
wait $PF_PID 