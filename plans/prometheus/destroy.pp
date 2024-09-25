# @summary Destroy Prometheus
#
# Stop, uninstall, purge configs for the Prometheus service managed
# by this module.
#
# @param targets Prometheus node to destroy
plan osp_managed_prom::prometheus::destroy (
  TargetSpec $targets = 'prometheus',
) {
  apply_prep($targets)

  apply($targets) {
    service { 'prometheus':
      ensure => stopped,
      enable => false,
    }
    -> package { 'prometheus':
      ensure => purged,
    }
  }.osp_managed_prom::print_report
}
