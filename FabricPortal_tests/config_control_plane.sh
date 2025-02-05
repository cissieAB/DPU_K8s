#!/bin/bash
# Run the following command to configure the control plane.

{

sudo apt update
sudo apt install -y docker.io apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# sudo sh -c "echo deb https://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list"
#cat /etc/apt/sources.list.d/kubernetes.list



sudo sh -c "echo deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ / | sudo tee /etc/apt/sources.list.d/kubernetes.list"
#cat /etc/apt/sources.list.d/kubernetes.list

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg




sudo apt update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a

sudo sh -c "echo {                                                  >  /etc/docker/daemon.json"
sudo sh -c 'echo \"exec-opts\": [\"native.cgroupdriver=systemd\"]  >>  /etc/docker/daemon.json'
sudo sh -c "echo }                                                 >>  /etc/docker/daemon.json"


sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

}   2>&1 | tee -a config_control_plane.log


# Run the following command to start the control plane.

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