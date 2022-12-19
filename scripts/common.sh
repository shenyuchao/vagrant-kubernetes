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

# diables firewall
systemctl disable --now firewalld 
systemctl disable --now dnsmasq 
systemctl disable --now NetworkManager
echo "disabled firewalld"

# diable swap
swapoff -a 
sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab
echo "disabled swap..."

# disable seliux
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
echo "disabled selinux"

# yum repo mirror
# curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
echo "added docker and kubernetes repo"

yum install wget jq psmisc vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git kexec-tools -y
echo "installed tools"

# install ntpdate
rpm -ivh http://mirrors.wlnmp.com/centos/wlnmp-release-centos.noarch.rpm
yum install ntpdate -y
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' >/etc/timezone
echo "*/5 * * * * /usr/sbin/ntpdate time2.aliyun.com" >> /var/spool/cron/root
echo "ntdate installed"

# upgrade kernel
# wget http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-devel-4.19.12-1.el7.elrepo.x86_64.rpm -qO /root/kernel-ml-devel-4.19.12-1.el7.elrepo.x86_64.rpm
# wget http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-4.19.12-1.el7.elrepo.x86_64.rpm -qO /root/kernel-ml-4.19.12-1.el7.elrepo.x86_64.rpm

# yum localinstall -y /vagrant/tools/kernel-ml*
# grub2-set-default  0 && grub2-mkconfig -o /etc/grub2.cfg
# grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

# ipvs config
yum install ipvsadm ipset sysstat conntrack libseccomp -y
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh

cat <<EOF > /etc/modules-load.d/ipvs.conf 
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
ip_vs_sh
nf_conntrack
ip_tables
ip_set
xt_set
ipt_set
ipt_rpfilter
ipt_REJECT
ipip
EOF
systemctl enable --now systemd-modules-load.service
echo "install ipvs success"

# system kernel
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.may_detach_mounts = 1
net.ipv4.conf.all.route_localnet = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720

net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF
sysctl --system
echo "kernel config"


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

# HA
yum install keepalived haproxy -y
cp /vagrant/config/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl daemon-reload
systemctl enable --now haproxy
echo "install haproxy success"