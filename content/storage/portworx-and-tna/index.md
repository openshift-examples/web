---
title: Portworx on Two-Node with Arbiter
linktitle: Portworx on Two-Node with Arbiter
description: Deploy Portworx on an OpenShift compact (two-node + arbiter) cluster with notes on disks, labels, and replica-2 storage.
tags: ['storage','portworx','TNA','v4.20']
icon: portworx/portworx
---
# Running Portworx on OpenShift Two-Node with Arbiter

**Two-Node with Arbiter (TNA)** is a compact OpenShift topology: two control-plane nodes that also run workloads, plus a third **arbiter** node that participates in quorum for etcd and—for storage—typically hosts **witness / KVDB** services without holding application data replicas. Portworx can run in that layout if you size disks and node roles correctly and align replication with the number of storage nodes.

Official documentation: [Portworx on OpenShift](https://docs.portworx.com/install-portworx/openshift/) (use the version that matches your Portworx release).

**Tested with:**

| Component | Version   |
| --------- | --------- |
| OpenShift | v4.20.15  |
| Portworx  | v3.5.2.1  |
| Portworx Operator | v25.6.1 |

## Prerequisites

Use a **Two-Node with Arbiter** cluster. Example node list:

```shell
% oc get nodes
NAME              STATUS   ROLES                         AGE     VERSION
ocp21-arbiter-0   Ready    arbiter                       3d11h   v1.33.6
ocp21-cp-0        Ready    control-plane,master,worker   3d11h   v1.33.6
ocp21-cp-1        Ready    control-plane,master,worker   3d11h   v1.33.6
```

**Additional disks** (example sizing from a lab):

| Node            | Additional disks |
| --------------- | ---------------- |
| ocp21-arbiter-0 | `/dev/vdb` — KVDB, min 32&nbsp;GiB |
| ocp21-cp-0      | `/dev/vdb` — data (~256&nbsp;GiB)<br/>`/dev/vdc` — metadata, min 64&nbsp;GiB |
| ocp21-cp-1      | `/dev/vdb` — data (~256&nbsp;GiB)<br/>`/dev/vdc` — metadata, min 64&nbsp;GiB |

**Node labels** (storage vs storageless + running on control-plane nodes):

| Node            | Labels |
| --------------- | ------ |
| ocp21-arbiter-0 | `portworx.io/node-type=storageless` |
| ocp21-cp-0      | `portworx.io/node-type=storage`, `portworx.io/run-on-master=true` |
| ocp21-cp-1      | `portworx.io/node-type=storage`, `portworx.io/run-on-master=true` |

## Install the operator

Install the **Portworx Operator** operator from **OperatorHub** into the `openshift-operaotrs` namespace (default). Wait until the operator deployment is **Available**.

If your cluster uses a private registry or disconnected mirrors, follow Portworx’s air-gapped / mirror steps for that release—image references in `StorageCluster` must resolve in your environment.

## Apply the StorageCluster

The manifest below maps **two storage nodes** to metadata + data devices and uses the **arbiter** for internal KVDB on a dedicated disk. `clusterDomain` values (`master1`, `master2`, `witness`) tie each block to the matching node; adjust names and devices to match your cluster.

```yaml
apiVersion: core.libopenstorage.org/v1
kind: StorageCluster
metadata:
  annotations:
    portworx.io/is-openshift: 'true'
    portworx.io/misc-args: '-rt_opts small_conf=1 -T px-storev2'
    portworx.io/disable-storage-class: "true"
  name: px-cluster
  namespace: portworx
spec:
  startPort: 17001
  runtimeOptions:
    default-io-profile: '6'
  stork:
    args:
      webhook-controller: 'true'
    enabled: true
  monitoring:
    prometheus:
      exportMetrics: true
    telemetry:
      enabled: true
      metricsCollector:
        enabled: true
  kvdb:
    enableTLS: false
    internal: true
  nodes:
    - clusterDomain: master1
      selector:
        nodeName: ocp21-cp-0
      storage:
        systemMetadataDevice: /dev/vdc
        useAll: true
    - clusterDomain: master2
      selector:
        nodeName: ocp21-cp-1
      storage:
        systemMetadataDevice: /dev/vdc
        useAll: true
    - clusterDomain: witness
      selector:
        nodeName: ocp21-arbiter-0
      storage:
        kvdbDevice: /dev/vdb
        useAll: false
  imagePullPolicy: Always
  secretsProvider: k8s
  version: 3.5.2.1
  csi:
    enabled: true
    installSnapshotController: true
  image: 'portworx/oci-monitor:3.5.2.1'
  storage:
    useAll: true
  updateStrategy:
    rollingUpdate:
      disruption:
        allow: true
      maxUnavailable: 1
    type: RollingUpdate
```

For **lab** clusters where you want a clean teardown, you can add:

```yaml
  deleteStrategy:
    type: UninstallAndWipe
```

!!! warning

    `UninstallAndWipe` removes Portworx data from disks allocated to Portworx when the `StorageCluster` is deleted. Use only in non-production or when you accept full data loss on those devices.

## Replica-2 storage class

With **two** data nodes, a **replica factor of 2** matches the topology: each volume is mirrored across both storage nodes. (Higher replication is not meaningful with only two storage members.)

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-replica-two
  annotations:
    storageclass.kubevirt.io/is-default-virt-class: 'true'
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: pxd.portworx.com
parameters:
  io_profile: db_remote
  repl: '2'
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

## Appendix: present virtual disks as non-rotational

Portworx expects **non-rotational** (SSD/NVMe) storage. Some lab hypervisors still report virtio disks as rotational, which can block or complicate install. A common workaround is a **udev** rule that sets `queue/rotational` to `0` (and a suitable scheduler) for `vd*` devices.

Rule content:

```log
ACTION=="add|change", KERNEL=="vd[a-z]", ATTR{queue/rotational}="0", ATTR{queue/scheduler}="deadline"
```

Apply per **MachineConfig** pool—for example, arbiter and master roles:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: arbiter
  name: 99-arbiter-disk-rotational
spec:
  config:
    ignition:
      version: 3.5.0
    storage:
      files:
        - contents:
            source: data:text/plain;charset=utf-8;base64,QUNUSU9OPT0iYWRkfGNoYW5nZSIsIEtFUk5FTD09InZkW2Etel0iLCBBVFRSe3F1ZXVlL3JvdGF0aW9uYWx9PSIwIiwgQVRUUntxdWV1ZS9zY2hlZHVsZXJ9PSJkZWFkbGluZSIK
            mode: 420
            overwrite: true
            path: /etc/udev/rules.d/99-disk-rotational.rules
```

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-disk-rotational
spec:
  config:
    ignition:
      version: 3.5.0
    storage:
      files:
        - contents:
            source: data:text/plain;charset=utf-8;base64,QUNUSU9OPT0iYWRkfGNoYW5nZSIsIEtFUk5FTD09InZkW2Etel0iLCBBVFRSe3F1ZXVlL3JvdGF0aW9uYWx9PSIwIiwgQVRUUntxdWV1ZS9zY2hlZHVsZXJ9PSJkZWFkbGluZSIK
            mode: 420
            overwrite: true
            path: /etc/udev/rules.d/99-disk-rotational.rules
```

After the nodes reconcile, confirm with `cat /sys/block/vd*/queue/rotational` on each node if needed.
