# OSP Managed Prometheus

This module provides the plumbing and automation to set up a basic reference
architecture for Open Source Puppet Server, PuppetDB, and Prometheus.

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

Using Vagrant and Bolt, bootstrap a monolithic Puppet instance with two nodes:
`osp` and `prometheus`. This module will install and configure Puppet Server and
PuppetDB on the `osp` node using
[`theforeman-puppet`](https://forge.puppet.com/modules/theforeman/puppet/readme)
module, configure `/etc/hosts` to ease communication between the nodes, and set
up agents. Then, it configures [r10k](https://github.com/puppetlabs/r10k) to
deploy a [special control
repo](https://github.com/jameslikeslinux/osp-managed-prom-control-repo.git) containing
roles and profiles to complete the Prometheus installation and configuration.

## Setup

### What osp_managed_prom affects

This module is primarily a [Bolt
project](https://www.puppet.com/docs/bolt/latest/bolt.html) that targets the
Vagrant instances that this module also provides. Exercise caution before
attempting to apply this module to other resources.

### Setup Requirements

This module requires a working [Vagrant](https://www.vagrantup.com/)
installation. The `Vagrantfile` provided in this repo expects the libvirt
backend. You may need to modify it to work with other backends, such as
VirtualBox.

### Beginning with osp_managed_prom

This module assumes two hosts named "osp" for the Puppet Server and
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

Launch two Puppet-compatible instances and install Puppet Agent. Modify
`inventory-aws.yaml` to reflect actual IP addresses and usernames, but keep the
names "osp" and "prometheus". We use `/etc/hosts` and the Puppet `certname` to
effectively pin these names as aliases so that the customer's hostnames are
irrelevant and our code will work across different environments. Then continue
with the steps below.

## Usage

1. Install Bolt modules:
    ```
    bolt module install
    ```
2. Bootstrap the Puppet instance with the appropriate inventory config:
    ```
    bolt plan run -i inventory-foo.yaml osp_managed_prom::bootstrap
    ```
3. Run Puppet on the `prometheus` node. This will complete the agent SSL bootstrap
   and install Prometheus based on the contents of the control repo.
    ```
    /opt/puppetlabs/bin/puppet agent --test --certname prometheus --server osp
    ```
4. Run Puppet on the `osp` node. This will ensure the Puppet Server
   configuration has converged to the desired state expressed in the control
   repo.
    ```
    /opt/puppetlabs/bin/puppet agent --test
    ```

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
