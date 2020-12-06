---
title: Local-storage
linktitle: Local-storage
weight: 14200
description: TBD
---
# Configuring local storage for virtual machines

Official documentation: [Configuring local storage for virtual machines
](https://docs.openshift.com/container-platform/latest/cnv/cnv_virtual_machines/cnv_virtual_disks/cnv-configuring-local-storage-for-vms.html)


## Create a backing directory on each node

Label your CNV nodes:
```
oc label node/compute-0 node-role.kubernetes.io/cnv
```

### Create MachineConfigPool

!!! important
    One node can only apply one MachineConfigPool! That's why you have to include all worker machineconfigurations.

```yaml
oc apply -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: cnv
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,cnv]}
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/cnv: ""
EOF
```

Source: [custom-pools](https://github.com/openshift/machine-config-operator/blob/master/docs/custom-pools.md)


### Create MachineConfig

!!! note
    Machine Config Operator do not support the Ignition filesystem.directory method.
    [Supported vs Unsupported Ignition config changes](https://github.com/openshift/machine-config-operator/blob/master/docs/MachineConfigDaemon.md#supported-vs-unsupported-ignition-config-changes)


```yaml
oc apply -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 50-cnv-local-storage
  labels:
    machineconfiguration.openshift.io/role: cnv
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      filesystems:
      - name: storage
        mount:
          device: /dev/vdb
          format: xfs
          wipe_filesystem: false
    systemd:
      units:
        - contents: |
            [Unit]
            Description=Create mountpoint /var/srv/storage
            Before=kubelet.service

            [Service]
            ExecStart=/bin/mkdir -p /var/srv/storage

            [Install]
            WantedBy=var-srv-storage.mount
          enabled: true
          name: create-mountpoint-var-srv-storage.service
        - name: var-srv-storage.mount
          enabled: true
          contents: |
            [Unit]
            Before=local-fs.target
            [Mount]
            What=/dev/vdb
            Where=/var/srv/storage
            Type=xfs
            [Install]
            WantedBy=local-fs.target
        - contents: |
            [Unit]
            Description=Set SELinux chcon for hostpath provisioner
            Before=kubelet.service

            [Service]
            ExecStart=/usr/bin/chcon -Rt container_file_t /var/srv/storage

            [Install]
            WantedBy=multi-user.target
          enabled: true
          name: hostpath-provisioner.service
EOF
```

## Create HostPathProvisioner

```yaml
oc apply -f - <<EOF
apiVersion: hostpathprovisioner.kubevirt.io/v1alpha1
kind: HostPathProvisioner
metadata:
  name: hostpath-provisioner
spec:
  imagePullPolicy: IfNotPresent
  pathConfig:
    path: "/var/srv/storage"
    useNamingPrefix: "false"
EOF
```

## Create StorageClass

```yaml
oc apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath-provisioner
provisioner: kubevirt.io/hostpath-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
```