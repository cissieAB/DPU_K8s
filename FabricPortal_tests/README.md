# Deploying Kubernetes on FABRIC

This guide provides instructions for deploying Kubernetes (k8s) clusters on FABRIC.

## Prerequisites
- FABRIC account and access
- Basic knowledge of Kubernetes
- Access to FABRIC portal

## Known Issues and Solutions

### 1. Initial Deployment
- Check the FABRIC example documentation for base configuration
- Review and modify the following configuration files:
  - `config_control_plane.sh`
  - `config_worker_plane.sh`
  - Reference scripts are available in "jupyter-examples-rel1.7.0"

### 2. Control Plane Setup
1. Configure the control plane settings
2. Execute the control plane startup script
3. Copy the returned join command to worker nodes
   ```bash
   kubeadm join 10.146.2.2:6443 --token 88mr0p.t91869x8xy2wsdrr \
   --discovery-token-ca-cert-hash sha256:b3d354906c1ef2f37737e9ff62ccd1894c4966bdbbffa00ee8d712c81b1b53d2
   ```
4. Apply this command in the `start_worker_node.sh` file

## Best Practices
1. Always verify control plane is running before adding worker nodes
2. Keep configuration files backed up
3. Monitor node connectivity regularly

## Troubleshooting
- If worker nodes fail to connect, check network configurations
- Verify all required ports are open
- Review logs for potential errors

For more detailed information, refer to the [FABRIC example documentation](FABRIC_example).
