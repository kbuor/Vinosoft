#!/bin/bash
# Bootstrap Master
kubeadm init --pod-network-cidr=192.168.0.0/16 --node-name=$NODE_NAME --apiserver-cert-extra-sans=$IP_LOCAL --apiserver-cert-extra-sans=$NODE_NAME

# Configure Credentials
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy Calico Network
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
sleep 10
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml
sleep 10

# Deploy Nginx-Ingress
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/refs/heads/main/config/manifests/metallb-native.yaml
sleep 10
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/crd/bases/metallb.io_ipaddresspools.yaml
sleep 10
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/crd/bases/metallb.io_l2advertisements.yaml
sleep 10

cat <'EOF' > /tmp/metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.1.201-10.0.1.209  # Node Network
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec: {}
EOF

kubectl apply -f /tmp/metallb-config.yaml
sleep 10

# Install Helm Chart
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install Nginx Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
sleep 10
