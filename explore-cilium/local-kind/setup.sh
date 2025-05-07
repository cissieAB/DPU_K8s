#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."
    
    # Check if kind is installed
    if ! command -v kind &> /dev/null; then
        print_error "kind is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install it first."
        exit 1
    fi
}

# Create Kind cluster
create_cluster() {
    print_status "Creating Kind cluster..."
    kind create cluster --config cluster/kind-config.yaml
}

# Install Cilium
install_cilium() {
    print_status "Installing Cilium..."
    
    # Add Cilium Helm repository
    helm repo add cilium https://helm.cilium.io/
    helm repo update
    
    # Install Cilium
    helm install cilium cilium/cilium --version 1.15.3 \
        --namespace kube-system \
        --values cluster/cilium-config.yaml
    
    # Wait for Cilium to be ready
    print_status "Waiting for Cilium to be ready..."
    kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=cilium --timeout=120s
    
    # Check Cilium status
    print_status "Checking Cilium status..."
    if ! cilium status; then
        print_warning "Cilium status check showed some warnings. Please check the output above."
    fi
}

# Install CoreDNS
install_coredns() {
    print_status "Installing CoreDNS..."
    
    # Apply CoreDNS configurations
    kubectl apply -f coredns/coredns-config.yaml
    kubectl apply -f coredns/coredns-deployment.yaml
    kubectl apply -f coredns/coredns-serviceaccount.yaml
    kubectl apply -f coredns/coredns-service.yaml
    
    # Wait for CoreDNS to be ready
    print_status "Waiting for CoreDNS to be ready..."
    kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=kube-dns --timeout=120s
    
    # Verify CoreDNS service
    print_status "Verifying CoreDNS service..."
    if ! kubectl get svc -n kube-system kube-dns &> /dev/null; then
        print_error "CoreDNS service not found"
        exit 1
    fi
}

# Test DNS functionality
test_dns() {
    print_status "Testing DNS functionality..."
    
    # Create test pod
    kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup kubernetes.default
    
    # Test external DNS resolution
    print_status "Testing external DNS resolution..."
    kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup google.com
}

# Verify cluster health
verify_cluster_health() {
    print_status "Verifying cluster health..."
    
    # Check node status
    print_status "Checking node status..."
    kubectl get nodes
    
    # Check Cilium status
    print_status "Checking Cilium status..."
    cilium status
    
    # Check service endpoints
    print_status "Checking service endpoints..."
    kubectl get endpoints
}

# Main execution
main() {
    print_status "Starting cluster setup..."
    
    # Check requirements
    check_requirements
    
    # Create cluster
    create_cluster
    
    # Install Cilium
    install_cilium
    
    # Install CoreDNS
    install_coredns
    
    # Test DNS
    test_dns
    
    # Verify cluster health
    verify_cluster_health
    
    print_status "Cluster setup completed successfully!"
    print_status "Note: Some Cilium service cleanup warnings may appear - these are non-critical"
    print_status "For troubleshooting, check the documentation in docs/troubleshooting.md"
    print_status "To set up monitoring, run: ./monitoring/deploy-monitoring.sh"
}

# Run main function
main 