plan osp_workshop::bootstrap {
  $nodes = get_targets('all')

  apply_prep($nodes)

  apply($nodes) {
    $nodes.each |$node| {
      $node_facts = facts($node)
      host { $node_facts['networking']['hostname']:
        ip => $node_facts['networking']['ip'],
      }
    }
  }

  apply('osp') {
    class { 'puppet':
      agent_server_hostname => $trusted['certname'],
      autosign              => true,
      environment           => 'production',
      puppet_runmode        => 'none',
      server                => true,
      server_external_nodes => '',
      server_foreman        => false,
      server_reports        => 'puppetdb',
      server_storeconfigs   => true,
    }

    include puppetdb

    class { 'puppet::server::puppetdb':
      server => $trusted['certname'],
    }

    class { 'r10k':
      cachedir => '/var/r10k',
      sources  => {
        'control-repo' => {
          'remote'  => 'https://github.com/jameslikeslinux/osp-workshop-control-repo.git',
          'basedir' => '/etc/puppetlabs/code/environments',
        },
      },
    }
  }

  run_task('r10k::deploy', 'osp')

  # Run manually for demonstration
  #run_command('/opt/puppetlabs/bin/puppet agent --test --server osp || [ $? -eq 2 ]', 'foreman')
}
