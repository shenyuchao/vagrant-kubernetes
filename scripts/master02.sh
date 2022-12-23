#! /bin/bash

# Haproxy
yum install keepalived haproxy -y
cp /vagrant/config/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl daemon-reload
systemctl enable --now haproxy
echo "install haproxy success"

# keepalived
cp /vagrant/config/keepalived/master02.conf /etc/keepalived/keepalived.conf
cp /vagrant/config/keepalived/check_apiserver.sh /etc/keepalived/check_apiserver.sh
chmod +x /etc/keepalived/check_apiserver.sh
systemctl daemon-reload
systemctl enable --now keepalived

# join master
/bin/bash /vagrant/config/master_join.sh -v