#! /bin/bash

# keepalived
cp /vagrant/config/keepalived/master01.conf /etc/keepalived/keepalived.conf
cp /vagrant/config/keepalived/check_apiserver.sh /etc/keepalived/check_apiserver.sh
chmod +x /etc/keepalived/check_apiserver.sh
systemctl daemon-reload
systemctl enable --now keepalived
echo "install keepalived success"

# kubeadm init
kubeadm config migrate --old-config /vagrant/config/kubeadm/kubeadm-config.yaml --new-config /vagrant/config/kubeadm/new.yaml
kubeadm init --config /vagrant/config/kubeadm/new.yaml  --upload-certs -v=5

echo "kubeadm init success"

# save configs
config_path="/vagrant/config"

if [ -d $config_path ]; then
   sudo rm -f $config_path/*
else
   sudo mkdir -p $config_path
fi


# worker join
cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/work_join.sh
chmod +x $config_path/work_join.sh       
echo "create work_join.sh success"

# kubeadm token create --print-join-command > $config_path/work_join.sh

# # master join
cp $config_path/work_join.sh $config_path/master_join.sh
echo " --control-plane --certificate-key " >> $config_path/master_join.sh
kubeadm init phase upload-certs  --upload-certs  >> $config_path/master_join.sh
echo "create master_join.sh success"
