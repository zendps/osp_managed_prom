function osp_managed_prom::print_report(ResultSet $apply_results) {
  $apply_results.each |$result| {
    $result.report['logs'].each |$log| {
      out::message("${result.target.name}: ${log['level'].capitalize}: ${log['source']}: ${log['message']}")
    }
  }
}
