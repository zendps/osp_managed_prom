# @summary Destroy Puppet
#
# Stop, uninstall, and purge configs for the Puppet server and client
# infrastructure this module bootstrapped.
#
# @param targets Server node to destroy
# @param osp Alias for 'targets'
# @param nodes Agent nodes to destroy
plan osp_managed_prom::puppet::destroy (
  TargetSpec $targets = 'osp',
  TargetSpec $osp     = $targets,
  TargetSpec $nodes   = ['osp', 'prometheus'],
) {
  $osp_target = get_targets($osp)[0]

  apply_prep([$osp_target, $nodes])

  apply($osp_target, '_description' => 'Purge servers') {
    service { [
      'puppetserver',
      'puppetdb',
    ]:
      ensure => stopped,
      enable => false,
    }
    -> package { [
      'puppetserver',
      'puppetdb',
    ]:
      ensure => purged,
    }

    include 'postgresql::params'

    service { $postgresql::params::service_name:
      ensure  => stopped,
      enable  => false,
      require => Service['puppetdb'],
    }
    -> package { $postgresql::params::server_package_name:
      ensure => purged,
    }
  }.osp_managed_prom::print_report

  apply($nodes, '_description' => 'Purge agents') {
    service { 'puppet':
      ensure => stopped,
      enable => false,
    }
    -> package { 'puppet-agent':
      ensure => purged,
    }
    -> file { '/etc/puppetlabs/puppet/ssl':
      ensure => absent,
      force  => true,
    }
  }.osp_managed_prom::print_report
}
