#! /bin/bash

# Haproxy
yum install keepalived haproxy -y
cp /vagrant/config/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl daemon-reload
systemctl enable --now haproxy
echo "install haproxy success"

# keepalived
cp /vagrant/config/keepalived/master03.conf /etc/keepalived/keepalived.conf
cp /vagrant/config/keepalived/check_apiserver.sh /etc/keepalived/check_apiserver.sh
chmod +x /etc/keepalived/check_apiserver.sh
systemctl daemon-reload
systemctl enable --now keepalived

# join master
/bin/bash /vagrant/config/master_join.sh -v

# calico install
PODCIDR="172.16.0.0/12"
wget https://docs.projectcalico.org/manifests/calico.yaml --no-check-certificate
sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/'  calico.yaml
sed -i "s|#   value: \"192.168.0.0/16\"|  value: \"$PODCIDR\"|"  calico.yaml
kubectl --kubeconfig /vagrant/config/config apply -f calico.yaml
echo "calico install success"