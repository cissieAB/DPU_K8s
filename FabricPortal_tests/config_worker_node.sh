#!/bin/bash

# First part: Install and configure prerequisites
{
    sudo apt update
    sudo apt install -y docker.io apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

    # sudo sh -c "echo deb https://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list"
    # #cat /etc/apt/sources.list.d/kubernetes.list

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
}  2>&1 | tee -a config_worker_node.log

# Second part: Join the cluster
# All arguments after the script name are considered part of the join command
{
    echo "Resetting any previous kubeadm configuration..."
    yes | sudo kubeadm reset

    # Combine all arguments into the join command
    join_cmd="$*"
    echo "Executing join command: ${join_cmd}"
    
    eval "${join_cmd}"
}  2>&1 | tee -a start_worker_node.log
