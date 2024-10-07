# @summary Deploy Prometheus Metrics Exporter
#
# Install and configure a metrics exporter according to Hiera data.
#
# @param targets Nodes to install exporter on
# @param exporter Name of the exporter to install
#
# @see https://github.com/voxpupuli/puppet-prometheus/tree/master/manifests
plan osp_managed_prom::prometheus::deploy_exporter (
  TargetSpec $targets,
  String $exporter,
) {
  apply_prep($targets)

  apply($targets) {
    class { "prometheus::${exporter}_exporter":
      # define parameter values in Hiera
    }
  }.osp_managed_prom::print_report
}
