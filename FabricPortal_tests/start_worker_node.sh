#!/bin/bash

ip=$1

{

echo ${ip}
yes | sudo kubeadm reset

sudo kubeadm join 10.146.4.2:6443 --token l255bp.wqi5i6br0jg7f4z2 \
	--discovery-token-ca-cert-hash sha256:069646097e377bcd9e6d66ee7779a0d3e0930d95d1e6a79f73f22f70b1098b5e
}  2>&1 | tee -a start_worker_node.log
