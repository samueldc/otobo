# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vagrant.plugins = "vagrant-libvirt"

  config.vm.box = "generic/ubuntu2004"

  config.vm.network "private_network", type: "dhcp"

  config.vm.provider :libvirt do |lv|
    lv.driver = "kvm"
    lv.memory = "2048"
  end
  
  config.vm.define "otobo", primary: true do |app|
    app.vm.network "forwarded_port", guest: 80, host: 8081, host_ip: "127.0.0.1"
    app.vm.hostname = "otobo.localhost"
    app.vm.synced_folder "./", "/opt/otobo"
    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "otobo.yml"
    end
  end  
  
  config.vm.define "otobo_database" do |db|
    # db.vm.network "forwarded_port", guest: 3306, host: 3316, host_ip: "127.0.0.1"
    db.vm.hostname = "otobo-db.localhost"
    db.vm.synced_folder ".db/", "/var/lib/mysql"
    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "otobo-db.yml"
    end
  end

end