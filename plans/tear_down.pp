# @summary Destroy managed services
#
# Essentially the bootstrap in reverse.
#
# @param osp Puppet Server node
# @param prometheus Prometheus server node
plan osp_managed_prom::tear_down (
  TargetSpec $osp        = 'osp',
  TargetSpec $prometheus = 'prometheus',
) {
  run_plan('osp_managed_prom::prometheus::destroy', $prometheus)
  run_plan('osp_managed_prom::puppet::destroy', $osp, 'nodes' => [$osp, $prometheus])
}
