# # #!/bin/bash

# subnet=$1
# ip=$2

# {

# yes | sudo kubeadm reset

# sudo kubeadm init --pod-network-cidr=${subnet} --apiserver-advertise-address=${ip}

# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# kubectl get nodes

# }  2>&1 | tee -a start_control_plane.log


#!/bin/bash

subnet=$1
ip=$2

{

yes | sudo kubeadm reset

sudo kubeadm init --pod-network-cidr=${subnet} --apiserver-advertise-address=${ip}

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Wait for Calico pods to be ready
echo "Waiting for Calico pods to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

# Install calicoctl if not present
if ! command -v calicoctl &> /dev/null; then
    echo "Installing calicoctl..."
    curl -L https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o calicoctl
    chmod +x calicoctl
    sudo mv calicoctl /usr/local/bin/
fi

# Configure node-to-node mesh
echo "Configuring node-to-node mesh..."
cat << EOF | calicoctl apply -f -
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  nodeToNodeMeshEnabled: true
  logSeverityScreen: Info
EOF

# Configure Calico IPPool with larger CIDR
echo "Configuring Calico IPPool with larger CIDR..."
cat << EOF | calicoctl apply -f -
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  cidr: ${subnet}
  blockSize: 30
  ipipMode: Always
  natOutgoing: true
EOF

# Verify the configurations
echo "Verifying configurations..."
echo "BGP Configuration:"
calicoctl get bgpconfig default -o yaml
echo "IPPool Configuration:"
calicoctl get ippool -o yaml
echo "Node Status:"
calicoctl node status

kubectl get nodes

}  2>&1 | tee -a start_control_plane.log