# Troubleshooting Guide

## Common Issues and Solutions

### Cilium Service Cleanup Warnings

#### Symptoms
- Warnings in `cilium status` about service cleanup
- Messages about unable to delete service entries
- Errors mentioning "key does not exist" in service maps

#### Solution
These warnings are non-critical and don't affect service functionality. They occur due to race conditions during service cleanup. To address:

1. Monitor the frequency of these warnings
2. If warnings persist after service updates:
   ```bash
   # Restart Cilium pods
   kubectl rollout restart -n kube-system daemonset/cilium
   ```

### DNS Resolution Issues

#### Verification Steps
1. Check CoreDNS pods:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. Verify CoreDNS service:
   ```bash
   kubectl get svc -n kube-system kube-dns
   ```

3. Test DNS resolution:
   ```bash
   kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup kubernetes.default
   ```

### Service Health Monitoring

#### Checking Service Status
1. View service endpoints:
   ```bash
   kubectl get endpoints
   ```

2. Check service connectivity:
   ```bash
   # Test specific service
   kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- wget -qO- http://service-name
   ```

### Cluster Health Verification

#### Node Status
```bash
kubectl get nodes
kubectl describe nodes
```

#### Cilium Status
```bash
cilium status
kubectl -n kube-system logs -l k8s-app=cilium
```

## Monitoring

### Metrics Collection
- Cilium metrics are available through the metrics endpoint
- Service monitors are configured for:
  - Cilium components
  - CoreDNS
  - Application services

### Accessing Metrics
1. Port-forward the Prometheus service:
   ```bash
   kubectl port-forward svc/prometheus-operated 9090:9090
   ```

2. View metrics in the Prometheus UI:
   - Navigate to http://localhost:9090
   - Check Cilium-specific metrics under cilium_* labels

## Best Practices

1. Regular Health Checks
   - Monitor node status
   - Check service endpoints
   - Review Cilium status

2. Service Management
   - Use service monitors for automated health checking
   - Implement readiness probes
   - Configure appropriate timeout values

3. Troubleshooting Steps
   - Check logs first
   - Verify service endpoints
   - Test connectivity with test pods
   - Review Cilium status 