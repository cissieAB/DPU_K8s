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

# Check if port-forward is running
check_port_forward() {
    if ! curl -s http://localhost:9090/-/healthy > /dev/null; then
        print_error "Prometheus is not accessible. Please ensure port-forward is running:"
        print_error "kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
        exit 1
    fi
}

# Check endpoint health
check_endpoint_health() {
    print_status "Checking Cilium endpoint health..."
    curl -s "http://localhost:9090/api/v1/query?query=cilium_endpoint_state" | grep -v "result\":\[\]" || print_warning "Could not get endpoint state"
}

# Check policy metrics
check_policy_metrics() {
    print_status "Checking Cilium policy metrics..."
    curl -s "http://localhost:9090/api/v1/query?query=cilium_policy" | grep -v "result\":\[\]" || print_warning "Could not get policy metrics"
}

# Check network performance
check_network_performance() {
    print_status "Checking Cilium network performance..."
    echo "Forwarded packets:"
    curl -s "http://localhost:9090/api/v1/query?query=cilium_forward_count_total" | grep -v "result\":\[\]" || print_warning "Could not get forward count"
    echo "Dropped packets:"
    curl -s "http://localhost:9090/api/v1/query?query=cilium_drop_count_total" | grep -v "result\":\[\]" || print_warning "Could not get drop count"
}

# Check BPF map metrics
check_bpf_metrics() {
    print_status "Checking Cilium BPF map metrics..."
    curl -s "http://localhost:9090/api/v1/query?query=cilium_bpf_map_pressure" | grep -v "result\":\[\]" || print_warning "Could not get BPF map pressure"
}

# Check controller metrics
check_controller_metrics() {
    print_status "Checking Cilium controller metrics..."
    curl -s "http://localhost:9090/api/v1/query?query=cilium_controllers_failing" | grep -v "result\":\[\]" || print_warning "Could not get controller metrics"
}

# Check identity metrics
check_identity_metrics() {
    print_status "Checking Cilium identity metrics..."
    curl -s "http://localhost:9090/api/v1/query?query=cilium_identity" | grep -v "result\":\[\]" || print_warning "Could not get identity metrics"
}

# Check process metrics
check_process_metrics() {
    print_status "Checking Cilium process metrics..."
    echo "Memory Usage:"
    curl -s "http://localhost:9090/api/v1/query?query=cilium_process_resident_memory_bytes" | grep -v "result\":\[\]" || print_warning "Could not get memory metrics"
}

# Main execution
main() {
    print_status "Starting Cilium metrics check..."
    
    # Check if port-forward is running
    check_port_forward
    
    # Check various metrics
    check_endpoint_health
    check_policy_metrics
    check_network_performance
    check_bpf_metrics
    check_controller_metrics
    check_identity_metrics
    check_process_metrics
    
    print_status "Metrics check completed"
    print_status "For more detailed metrics, visit http://localhost:9090"
}

# Run main function
main 