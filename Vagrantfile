Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.box = "shenyuchao/centos7-k8s"
  # config.vm.synced_folder ".", "/vagrant", type: "nfs"
  # config.vm.provider "vmware_desktop" do |v|
  #   v.vmx["memsize"] = "2048"
  #   v.vmx["numvcpus"] = "2"
  # end
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 2048
  end

  # master
  config.vm.define "k8s-master01" do |node|
    node.vm.hostname = "k8s-master01"
    node.vm.network "private_network", ip: "10.103.236.201"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master01"
    end
    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/master01.sh"
  end
  
  config.vm.define "k8s-master02" do |node|
    node.vm.hostname = "k8s-master02"
    node.vm.network "private_network", ip: "10.103.236.202"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master02"
    end
    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/master02.sh"
  end

  config.vm.define "k8s-master03" do |node|
    node.vm.hostname = "k8s-master03"
    node.vm.network "private_network", ip: "10.103.236.203"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master03"
    end
    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/master03.sh"
  end

  # worker
  config.vm.define "k8s-node01" do |node|
    node.vm.hostname = "k8s-node01"
    node.vm.network "private_network", ip: "10.103.236.204"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-node01"
    end
    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/worker.sh"
  end

  config.vm.define "k8s-node02" do |node|
    node.vm.hostname = "k8s-node02"
    node.vm.network "private_network", ip: "10.103.236.205"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-node02"
    end
    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/worker.sh"
  end
end

