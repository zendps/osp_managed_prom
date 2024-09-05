plan osp_managed_prom::bootstrap {
  $nodes = get_targets('all')

  apply_prep($nodes)

  apply($nodes) {
    $nodes.each |$node| {
      $node_facts = facts($node)
      host { $node.name:
        ip => $node_facts['networking']['ip'],
      }
    }
  }

  $apply_results = apply('osp') {
    class { 'puppet':
      agent_server_hostname => 'osp',
      autosign              => true,
      dns_alt_names         => ['osp'],
      environment           => 'production',
      runmode               => 'none',
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
          'remote'  => 'https://github.com/jameslikeslinux/osp-managed-prom-control-repo.git',
          'basedir' => '/etc/puppetlabs/code/environments',
        },
      },
    }
  }

  $apply_results.each |$result| {
    $result.report['logs'].each |$log| {
      out::message("${result.target.name}: ${log['level'].capitalize}: ${log['source']}: ${log['message']}")
    }
  }

  run_task('r10k::deploy', 'osp')
}
