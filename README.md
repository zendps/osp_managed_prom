# Bolt Managed Prometheus

This module provides the plumbing and automation to set up and maintain a
Prometheus metrics collection stack including metrics exporters and relaying to
Grafana Cloud.

![Workshop Architecture](.architecture.png)

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with osp_managed_prom](#setup)
    * [What osp_managed_prom affects](#what-osp_managed_prom-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with osp_managed_prom](#beginning-with-osp_managed_prom)
1. [Usage - Step by step instructions](#usage)
1. [Cleanup](#cleanup)
<!-- 1. [Limitations - OS compatibility, etc.](#limitations) -->
<!-- 1. [Development - Guide for contributing to the module](#development) -->

## Description

Use [Bolt](https://www.puppet.com/docs/bolt/latest/bolt.html) to orchestrate
the deployment of Prometheus and any number of metrics exporters at a customer
site. This module wraps the
[puppet-prometheus](https://forge.puppet.com/modules/puppet/prometheus/readme)
module with Bolt plans and a Hiera configuration that will let you install and
maintain these services from an administrative workstation.

## Setup

### What osp_managed_prom affects

As this module mostly wraps a well-maintained community module, see the
[upstream
documentation](https://forge.puppet.com/modules/puppet/prometheus/readme#what-this-module-affects).
Bolt will apply that module to the targets you configure with the data you
supply.

### Setup Requirements

Fork this module to a private repo if you want to commit a customer
configuration. Traditionally, Hiera data exists independently of the code and
the module, but for ease of deployment and management, we consolidate it here.

For testing, this module requires a working [Vagrant](https://www.vagrantup.com/)
installation. The `Vagrantfile` provided in this repo expects the libvirt
backend. You may need to modify it to work with other backends, such as
VirtualBox.

### Beginning with osp_managed_prom

This module assumes two hosts named "osp" for the (optional) Puppet Server and
"prometheus" for the Prometheus server and establishes aliases as such, so you
can call them whatever you want.

#### Vagrant

Start by bringing up the two Vagrant instances.

```
vagrant up
```

Assuming they launch successfully, you should be able to log in to each
instance with:

```
vagrant ssh osp
vagrant ssh prometheus
```

and switch to root with `sudo -s`.

Finally, prepare to allow Bolt to connect to these nodes by running:

```
vagrant ssh-config > vagrant-ssh.conf
```

You may need to fixup the resulting config file depending on how you invoke
Bolt. Bolt's `inventory-vagrant.yaml` is configured to use `vagrant-ssh.conf` to tell
it how to connect.

#### AWS

Launch two Puppet-compatible instances (i.e. most modern Linux distros). Modify
`inventory-aws.yaml` to reflect actual IP addresses and usernames, but keep the
names "osp" and "prometheus". We use `/etc/hosts` and the Puppet `certname` to
effectively pin these names as aliases so that the customer's hostnames are
irrelevant and our code will work across different environments. Then continue
with the steps below.

#### Bolt

Install Bolt modules:

```
bolt module install
```

## Usage

This module can be used to deploy the managed configuration directly with Bolt
or with self-healing Puppet infrastructure.

### Deploy with Bolt

For ease of use, Bolt can connect directly to different targets for managing a
Prometheus instance and metrics exporters.

#### Prometheus

Prometheus is managed by the
[`puppet-prometheus`](https://forge.puppet.com/modules/puppet/prometheus/readme)
module and applied by Bolt. It will pull its configuration from Hiera.

1. Copy the example site configuration and modify the remote write config for
   the appropriate, e.g., Grafana Cloud endpoint:
   ```
   cp data/example-site.yaml data/site.yaml
   $EDITOR data/site.yaml
   ```
2. Copy the example node configuration and modify the scrape configs for the
   deployed metrics exporters:
   ```
   cp data/example-prometheus.yaml data/prometheus.yaml
   $EDITOR data/prometheus.yaml
   ```
   If you gave the node a different name in the Bolt inventory, use that name
   for the yaml file.
3. Apply the configuration:
   ```
   bolt plan run -i inventory-foo.yaml osp_managed_prom::prometheus::deploy
   ```
   add `-t NAME` if you used an inventory name other than `prometheus`.

Update the Hiera configurations and redeploy as needed.

#### Metrics Exporters

Metrics exporters are managed by the same 
[`puppet-prometheus`](https://forge.puppet.com/modules/puppet/prometheus/readme)
module. You can see a complete list of exporter types at
https://github.com/voxpupuli/puppet-prometheus/tree/master/manifests. Click on
the manifest to see all the parameters you can set to customize the (usually
OK) defaults. Define any necessary parameters in Hiera, at the site level as
above, or the node level:

1. Create a file named like `data/foo.example.com.yaml` containing parameters like:
   ```yaml
   ---
   prometheus::apache_exporter::scrape_uri: 'http://localhost:8080/server-status/?auto'
   prometheus::node_exporter::scrape_port: 9101
   ```
   This file is excluded from Git by default. Use `git add -f` if you wish to
   add it to your **forked and private** repo.
2. Define a node configuration in the Bolt inventory modeled after the existing
   "osp" and "prometheus" entries that uses the same name as the Hiera data
   file.
3. Apply the configuration:
   ```
   bolt plan run -i inventory-foo.yaml osp_managed_prom::prometheus::deploy_exporter \
    -t foo.example.com,bar.example.com,... exporter=NAME
   ```
   where `NAME` is the exporter type, e.g., `apache`, `nginx_prometheus`,
   `node`, `php_fpm`.

Update the Hiera configurations and redeploy as needed.

##### Example

```
> bolt plan run -i inventory-vagrant.yaml osp_managed_prom::prometheus::deploy_exporter -t prometheus exporter=node
Starting: plan osp_managed_prom::prometheus::deploy_exporter
Starting: install puppet and gather facts on prometheus
Finished: install puppet and gather facts with 0 failures in 25.36 sec
Starting: apply catalog on prometheus
Finished: apply catalog with 0 failures in 28.01 sec
prometheus: Notice: /Stage[main]/Prometheus::Config/File[prometheus.yaml]/content: content changed '{sha256}e2db4b4e4b5006330160dbe7e8c9ebff3be37f7e8459a3a4618a82ab75b99cfe' to '{sha256}74706a13b5e1a236910b54c20d11f20d98964afceb5319410c2451fe154ac83a'
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/Archive[/tmp/node_exporter-1.0.1.tar.gz]/ensure: download archive from https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz to /tmp/node_exporter-1.0.1.tar.gz and extracted in /opt with cleanup
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/File[/opt/node_exporter-1.0.1.linux-amd64/node_exporter]/owner: owner changed 3434 to 'root'
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/File[/opt/node_exporter-1.0.1.linux-amd64/node_exporter]/group: group changed 3434 to 'root'
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/File[/opt/node_exporter-1.0.1.linux-amd64/node_exporter]/mode: mode changed '0755' to '0555'
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/File[/usr/local/bin/node_exporter]/ensure: created
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/Group[node-exporter]/ensure: created
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/User[node-exporter]/ensure: created
prometheus: Notice: /Stage[main]/Prometheus::Service_reload/Exec[prometheus-reload]: Triggered 'refresh' from 1 event
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/Systemd::Manage_unit[node_exporter.service]/Systemd::Unit_file[node_exporter.service]/File[/etc/systemd/system/node_exporter.service]/ensure: defined content as '{sha256}c548b39c93a3d73c52abfc887f3bec7ec8621de7bf457a24362deb45d20fabf5'
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/Systemd::Manage_unit[node_exporter.service]/Systemd::Unit_file[node_exporter.service]/Systemd::Daemon_reload[node_exporter.service]/Exec[systemd-node_exporter.service-systemctl-daemon-reload]: Triggered 'refresh' from 1 event
prometheus: Notice: /Stage[main]/Prometheus::Node_exporter/Prometheus::Daemon[node_exporter]/Service[node_exporter]/ensure: ensure changed 'stopped' to 'running'
prometheus: Notice: Puppet: Applied catalog in 5.43 seconds
Finished: plan osp_managed_prom::prometheus::deploy_exporter in 53.47 sec
Plan completed successfully with no result
```

### Bootstrap OSP infrastructure

This process will kick off self-managing Puppet Server and
Agents with a control repo that maintains Prometheus and
related components.

1. Bootstrap the Puppet instance with the appropriate inventory config:
    ```
    bolt plan run -i inventory-foo.yaml osp_managed_prom::puppet::bootstrap
    ```
2. Run Puppet on the `prometheus` node. This will complete the agent SSL bootstrap
   and install Prometheus based on the contents of the control repo.
    ```
    /opt/puppetlabs/bin/puppet agent --test --certname prometheus --server osp
    ```
3. Run Puppet on the `osp` node. This will ensure the Puppet Server
   configuration has converged to the desired state expressed in the control
   repo.
    ```
    /opt/puppetlabs/bin/puppet agent --test
    ```

### Rebuilding

Sometimes you just need to start over and it can be difficult to reprovision
the OS. The `osp_managed_prom::tear_down` plan intends to destroy managed
infrastructure including the Prometheus service, Puppet Server, PuppetDB, and
Puppet Agent. It is best-effort cleanup of services, packages, configuration
files, and data directories.

## Cleanup

Stop your Vagrant instances with:

```
vagrant halt
```

and remove them completely with:

```
vagrant destroy
```

<!--
## Limitations

In the Limitations section, list any incompatibilities, known issues, or other
warnings.

## Development

In the Development section, tell other users the ground rules for contributing
to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You can also add any additional sections you feel are
necessary or important to include here. Please use the `##` header.

[1]: https://puppet.com/docs/pdk/latest/pdk_generating_modules.html
[2]: https://puppet.com/docs/puppet/latest/puppet_strings.html
[3]: https://puppet.com/docs/puppet/latest/puppet_strings_style.html
-->
