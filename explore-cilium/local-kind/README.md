# Local Kind Cluster Setup & Performance Testing

This directory contains scripts and configurations to set up a local [Kind](https://kind.sigs.k8s.io/) Kubernetes cluster with either the default CNI (kindnet) or [Cilium](https://cilium.io/), and to run network performance tests.

---

## Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (required by Kind)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/) (for Cilium installation)

---

## Cluster Setup

All setup is managed by the script: `setup_test_clusters.sh`.

### 1. Create a Cluster with Default CNI (kindnet)
```bash
./setup_test_clusters.sh default
```
- This creates a Kind cluster with 1 control-plane and 2 worker nodes using the default CNI.
- Context will be renamed to `default-cni`.
- To use this context:
  ```bash
  kubectl config use-context default-cni
  ```

### 2. Create a Cluster with Cilium CNI
```bash
./setup_test_clusters.sh cilium
```
- This creates a Kind cluster with 1 control-plane and 2 worker nodes, disables the default CNI, and installs Cilium via Helm.
- Uses the configs in `cluster/kind-config-cilium.yaml` and `cluster/cilium-config.yaml`.
- Context will be renamed to `cilium-cni`.
- To use this context:
  ```bash
  kubectl config use-context cilium-cni
  ```

> **Note:** The script will delete any existing Kind clusters before creating a new one.

---

## Running Performance Tests

All test scripts are in the `performance/` directory. Each test saves results to a file in this directory.

### 1. HTTP Performance Test (Apache Benchmark)
```bash
cd performance
./run_http_test.sh [cni_type] [duration] [requests] [concurrency]
# Example:
./run_http_test.sh default 30 1000 10
./run_http_test.sh cilium 30 1000 10
```
- **cni_type:** `default` or `cilium` (default: `default`)
- **duration:** Test duration in seconds (default: 30)
- **requests:** Total number of requests (default: 1000)
- **concurrency:** Number of concurrent clients (default: 10)
- **Results:** `http_results_<cni_type>_c<concurrency>.txt`

### 2. Network Throughput Test (iperf3)
```bash
cd performance
./run_iperf3_test.sh [cni_type]
# Example:
./run_iperf3_test.sh default
./run_iperf3_test.sh cilium
```
- **cni_type:** `default` or `cilium` (default: `default`)
- **Results:** `iperf3_results_<cni_type>.txt`

### 3. High-Load HTTP Test (wrk)
```bash
cd performance
./run_wrk_test.sh [cni_type] [duration] [connections] [threads]
# Example:
./run_wrk_test.sh default 30s 1000 8
./run_wrk_test.sh cilium 30s 1000 8
```
- **cni_type:** `default` or `cilium` (default: `default`)
- **duration:** Test duration (e.g., `30s`, default: `30s`)
- **connections:** Number of concurrent connections (default: 1000)
- **threads:** Number of threads (default: 8)
- **Results:** `wrk_results_<cni_type>_c<connections>_t<threads>.txt`

---

## Cleanup
- Each test script will clean up its own resources (pods, services, temp files) after completion.
- The cluster setup script will delete all existing Kind clusters before creating a new one.

---

## Test Results
- See `CNI_Performance_Test_Summary.md` for a summary and analysis of test results.
- Raw results are saved in this directory as text files.

---

## References
- [Kind Documentation](https://kind.sigs.k8s.io/docs/)
- [Cilium Documentation](https://docs.cilium.io/en/stable/)
- [Helm Documentation](https://helm.sh/docs/) 