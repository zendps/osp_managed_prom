# @summary Deploy Prometheus
#
# Install and configure Prometheus according to Hiera data.
#
# @param targets Prometheus node to deploy
plan osp_managed_prom::prometheus::deploy (
  TargetSpec $targets = 'prometheus',
) {
  apply_prep($targets)

  apply($targets) {
    include prometheus
  }.osp_managed_prom::print_report
}
