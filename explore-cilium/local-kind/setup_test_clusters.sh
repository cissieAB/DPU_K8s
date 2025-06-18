#!/bin/bash

# Script to set up Kind cluster with chosen CNI
# Usage: ./setup_test_clusters.sh [cni_type]
# Example: ./setup_test_clusters.sh default
# Example: ./setup_test_clusters.sh cilium

set -e  # Exit on error

# Check if CNI type is provided
if [ -z "$1" ]; then
    echo "Error: Please specify CNI type (default or cilium)"
    echo "Usage: ./setup_test_clusters.sh [cni_type]"
    exit 1
fi

CNI_TYPE=$1
if [ "$CNI_TYPE" != "default" ] && [ "$CNI_TYPE" != "cilium" ]; then
    echo "Error: CNI type must be either 'default' or 'cilium'"
    exit 1
fi

# Function to create a Kind cluster
create_cluster() {
    local cluster_name=$1
    local config_file=$2
    local use_cilium=$3

    echo "Creating ${cluster_name} cluster..."
    kind create cluster --name ${cluster_name} --config ${config_file}

    if [ "${use_cilium}" = "true" ]; then
        echo "Installing Cilium CNI..."
        helm repo add cilium https://helm.cilium.io/ || true
        helm repo update
        helm install cilium cilium/cilium --version 1.15.3 \
            --namespace kube-system \
            --values cluster/cilium-config.yaml

        echo "Waiting for Cilium to be ready..."
        kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=cilium --timeout=120s
    fi

    echo "${cluster_name} cluster is ready!"
}

# Clean up existing clusters
echo "Cleaning up existing clusters..."
kind delete clusters --all || true

# Create a temporary config file with 2 workers
cat > /tmp/kind-config.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.29.2
- role: worker
  image: kindest/node:v1.29.2
- role: worker
  image: kindest/node:v1.29.2
EOF

if [ "$CNI_TYPE" = "default" ]; then
    # Create default CNI cluster
    create_cluster "default-cni-cluster" "/tmp/kind-config.yaml" "false"
    
    # Save the default cluster context
    kubectl config use-context kind-default-cni-cluster
    kubectl config rename-context kind-default-cni-cluster default-cni
    
    echo "Default CNI cluster is ready!"
    echo "To use the cluster: kubectl config use-context default-cni"
else
    # Create Cilium CNI cluster
    create_cluster "cilium-cluster" "/tmp/kind-config.yaml" "true"
    
    # Save the Cilium cluster context
    kubectl config use-context kind-cilium-cluster
    kubectl config rename-context kind-cilium-cluster cilium-cni
    
    echo "Cilium CNI cluster is ready!"
    echo "To use the cluster: kubectl config use-context cilium-cni"
fi

# Clean up temporary config
rm /tmp/kind-config.yaml 