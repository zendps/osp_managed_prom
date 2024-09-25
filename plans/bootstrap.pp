# @summary Bootstrap Open Source Puppet infrastructure
#
# Use Forge modules to deploy Puppet Server, PuppeotDB, and r10k with a
# control repo for a managed Prometheus service.
#
# @param osp Puppet Server node
# @param prometheus Prometheus server node
plan osp_managed_prom::bootstrap (
  TargetSpec $osp        = 'osp',
  TargetSpec $prometheus = 'prometheus',
) {
  $osp_target = get_targets($osp)[0]

  apply_prep([$osp_target, $prometheus])

  apply([$osp_target, $prometheus], '_description' => 'Create /etc/hosts entry for Puppet Server') {
    host { $osp_target.name:
      ip => facts($osp_target)['networking']['ip'],
    }
  }.osp_managed_prom::print_report

  apply($osp_target, '_description' => 'Manage Puppet Server') {
    class { 'puppet':
      agent_server_hostname => $osp_target.name,
      autosign              => true,
      dns_alt_names         => [$osp_target.name],
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
      server => $osp_target.name,
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
  }.osp_managed_prom::print_report

  run_task('r10k::deploy', $osp_target)
}
