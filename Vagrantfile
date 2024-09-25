Vagrant.configure('2') do |config|
  config.vm.box = 'generic/ubuntu2004'

  config.vm.provider :libvirt do |domain|
    domain.cpu_mode = 'custom'
    domain.cpu_model = 'kvm64'
  end

  config.vm.define :osp do |node|
    node.vm.hostname = 'vagrant-osp' # do not assume hostname
    node.vm.provider :libvirt do |domain|
      domain.cpus = 2
      domain.machine_virtual_size = 50
      domain.memory = 4096
    end
  end

  config.vm.define :prometheus do |node|
    node.vm.hostname = 'vagrant-prometheus' # do not assume hostname
    node.vm.provider :libvirt do |domain|
      domain.cpus = 2
      domain.machine_virtual_size = 50
      domain.memory = 4096
    end
  end
end

# vim:ft=ruby
