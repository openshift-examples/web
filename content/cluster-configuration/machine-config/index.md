---
title: MachineConfig
linktitle: MachineConfig
description: Some infos about MachineConfig
tags: ['MachineConfig', 'MCO','v4.17']
---
# Machine Config

Create MachineConfig objects that modify files, systemd unit files, and other operating system features running on OpenShift Container Platform nodes. OpenShift Container Platform supports Ignition specification version 3.2. All new machine configs you create going forward should be based on Ignition specification version 3.2.

## Force Machine Config

Inspired by <https://bugzilla.redhat.com/show_bug.cgi?id=1766513>

```bash
oc debug node/worker0 -- chroot /host touch /run/machine-config-daemon-force
```

## Pause rebooting

```bash
oc patch --type=merge --patch='{"spec":{"paused":true}}' machineconfigpool/master
```

## Rollout sshd config example

* *Tested with OpenShift v4.17*
* Documentation: [1.1. Creating machine configs with Butane](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/installation_configuration/installing-customizing#installation-special-config-butane-create_installing-customizing)

???+ quote "Butane Config for worker node"

    ```yaml
    ---8<---- "content/cluster-configuration/machine-config/sshd-config-example/sshd-worker.yaml"
    ```

???+ quote "Butane Config for worker node"

    ```yaml
    ---8<---- "content/cluster-configuration/machine-config/sshd-config-example/sshd-master.yaml"
    ```

### Convert butane in Machine Config

```bash
butane sshd-worker.yaml -o sshd-worker.machineconfig.yaml
butane sshd-master.yaml -o sshd-master.machineconfig.yaml
```

??? quote "Machine Config for worker node"

    ```yaml
    ---8<---- "content/cluster-configuration/machine-config/sshd-config-example/sshd-worker.machineconfig.yaml"
    ```

??? quote "Machine Config for worker node"

    ```yaml
    ---8<---- "content/cluster-configuration/machine-config/sshd-config-example/sshd-master.machineconfig.yaml"
    ```

### Apply changes to cluster

```bash
oc apply -f sshd-worker.machineconfig.yaml
oc apply -f sshd-master.machineconfig.yaml
```

All nodes (worker&master) will be drained and rebooted.

Watch rollout: `watch 'oc get mcp,nodes'`
