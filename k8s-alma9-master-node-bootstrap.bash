#!/bin/bash
#Bootstrap Master
kubeadm init --pod-network-cidr=192.168.0.0/16 --node-name=$NODE_NAME --apiserver-cert-extra-sans=$IP_LOCAL --apiserver-cert-extra-sans=$NODE_NAME

#Configure Credentials
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#Deploy Calico Network
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml

# Deploy Nginx-Ingress
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/refs/heads/main/config/manifests/metallb-native.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/crd/bases/metallb.io_ipaddresspools.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/crd/bases/metallb.io_l2advertisements.yaml
cat <'EOF' > /tmp/metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.20.30.200-10.20.30.210  # Dải IP được chọn
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec: {}
EOF
