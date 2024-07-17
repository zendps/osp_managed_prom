Vagrant.configure('2') do |config|
  config.vm.box = 'generic/ubuntu2004'

  config.vm.provider :libvirt do |domain|
    domain.cpu_mode = 'custom'
    domain.cpu_model = 'kvm64'
  end

  config.vm.provision :shell, inline: <<-SHELL
    wget https://apt.puppet.com/puppet8-release-focal.deb
    sudo dpkg -i puppet8-release-focal.deb
    sudo apt-get update
    sudo apt-get install puppet-agent
  SHELL

  config.vm.define :osp do |node|
    node.vm.hostname = 'osp'
    node.vm.provider :libvirt do |domain|
      domain.cpus = 2
      domain.machine_virtual_size = 50
      domain.memory = 4096
    end
  end

  config.vm.define :prometheus do |node|
    node.vm.hostname = 'prometheus'
    node.vm.provider :libvirt do |domain|
      domain.cpus = 2
      domain.machine_virtual_size = 50
      domain.memory = 4096
    end
  end
end

# vim:ft=ruby
