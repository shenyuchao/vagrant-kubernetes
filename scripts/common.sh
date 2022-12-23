#! /bin/bash
KUBERNETES_VERSION="1.24.9-0"

cat <<EOF >> /etc/hosts
10.103.236.201 k8s-aster01
10.103.236.202 k8s-master02
10.103.236.203 k8s-master03
10.103.236.236 k8s-master-lb
10.103.236.204 k8s-worker01
10.103.236.205 k8s-worker02
EOF
echo "set hosts"

# install containerd
yum install docker-ce-20.10.* docker-ce-cli-20.10.* -y
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe -- overlay
modprobe -- br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i "s#registry.k8s.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g" /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
echo "install containerd success"


yum install kubeadm-$KUBERNETES_VERSION kubelet-$KUBERNETES_VERSION kubectl-$KUBERNETES_VERSION -y
cat >/etc/sysconfig/kubelet<<EOF
KUBELET_KUBEADM_ARGS="--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF

systemctl daemon-reload
systemctl enable --now kubelet
echo "install k8s components success"