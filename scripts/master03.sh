#! /bin/bash

# keepalived
cp /vagrant/config/keepalived/master03.conf /etc/keepalived/keepalived.conf
cp /vagrant/config/keepalived/check_apiserver.sh /etc/keepalived/check_apiserver.sh
chmod +x /etc/keepalived/check_apiserver.sh
systemctl daemon-reload
systemctl enable --now keepalived