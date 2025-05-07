# Cilium CNI with Kind Cluster

This project demonstrates the setup and testing of a Kubernetes cluster using Kind with Cilium CNI, including network policies and service mesh capabilities.

## Project Structure

```
.
├── setup.sh                 # Main setup script
├── cluster/                 # Cluster configuration files
│   ├── kind-config.yaml    # Kind cluster configuration
│   └── cilium-config.yaml  # Cilium CNI configuration
├── coredns/                # CoreDNS setup files
│   ├── coredns-config.yaml
│   ├── coredns-deployment.yaml
│   ├── coredns-serviceaccount.yaml
│   └── coredns-service.yaml
├── app/                    # Application files
│   ├── app-deployment.yaml # Main application with Cilium policies
│   └── app-test.yaml      # Application test pods
└── tests/                  # Test files
    └── dns-test.yaml      # DNS testing pod
```

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/) - For running local Kubernetes clusters
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes command-line tool
- [Helm](https://helm.sh/) - Kubernetes package manager

## Setup Process

The setup script (`setup.sh`) performs the following steps:

1. **Requirements Check**
   - Verifies that required tools (kind, kubectl, helm) are installed

2. **Cluster Creation**
   - Creates a Kind cluster using `cluster/kind-config.yaml`

3. **Cilium Installation**
   - Installs Cilium CNI using Helm
   - Configures Cilium using `cluster/cilium-config.yaml`
   - Enables KubeProxy replacement and service mesh features

4. **CoreDNS Setup**
   - Deploys CoreDNS with custom configuration
   - Sets up necessary service accounts and services

5. **Testing**
   - DNS Testing
     - Verifies internal and external DNS resolution
   - Application Testing
     - Deploys a sample application with Cilium network policies
     - Tests service-to-service communication
     - Verifies L7 (HTTP) policy enforcement

## Application Architecture

The sample application consists of three components:

1. **Frontend**
   - Nginx web server
   - Can only communicate with Backend on `/api/*` paths

2. **Backend**
   - HTTP echo server
   - Can communicate with Frontend and Database
   - Enforces path-based access control

3. **Database**
   - Redis server
   - Only accessible by Backend

## Network Policies

Cilium network policies enforce the following rules:

- Frontend → Backend: Only HTTP GET requests to `/api/*` paths
- Backend → Database: Only Redis protocol (port 6379)
- All other communication is blocked

## Testing

The setup includes two types of tests:

1. **DNS Tests**
   - Verifies internal DNS resolution (kubernetes.default)
   - Verifies external DNS resolution (google.com)

2. **Application Tests**
   - Frontend test pod: Tests communication to Backend
   - Backend test pod: Tests communication to Database
   - Verifies that network policies are correctly enforced

## Usage

1. Clone the repository
2. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```
3. Run the setup script:
   ```bash
   ./setup.sh
   ```

## Troubleshooting

### DNS Resolution Issues

If pods cannot resolve service names:

1. Check CoreDNS status:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. Verify CoreDNS service:
   ```bash
   kubectl get service -n kube-system kube-dns
   ```

3. Test DNS resolution from a pod:
   ```bash
   kubectl exec -it dnsutils -- nslookup kubernetes.default
   ```

### Network Policy Issues

If network policies are not working:

1. Check Cilium status:
   ```bash
   kubectl -n kube-system exec -it ds/cilium -- cilium status
   ```

2. Verify policy status:
   ```bash
   kubectl get cnp
   ```

3. Check pod logs for policy violations:
   ```bash
   kubectl logs <pod-name>
   ```

### Common Issues

1. **KubeProxy Replacement**: Ensure Cilium is configured with:
   ```yaml
   kubeProxyReplacement: strict
   k8sServiceHost: cilium-cluster-control-plane
   k8sServicePort: 6443
   ```

2. **Service Load Balancing**: If services are not accessible, check:
   - Service endpoints are correctly configured
   - Network policies allow the traffic
   - Cilium service load balancer status

3. **Pod Communication**: If pods cannot communicate:
   - Verify network policies are correctly configured
   - Check pod labels match policy selectors
   - Ensure services are running and have endpoints

## Cleanup

To delete the Kind cluster:
```bash
kind delete cluster
```

For a complete cleanup:
```bash
kind delete clusters --all
``` 