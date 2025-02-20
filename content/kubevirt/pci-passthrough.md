---
title: PCI passthrough
linktitle: PCI passthrough
description: PCI passthrough and OpenShift Virtualizartion
tags: ['cnv','kubevirt','v4.17']
---
# PCI passthrough

* [Official documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/virtualization/index#virt-configuring-pci-passthrough)
* [Upstream documentation](https://kubevirt.io/user-guide/compute/host-devices/)

## Tested with

|Component|Version|
|---|---|
|OpenShift|v4.17.14|
|OpenShift Virt|v4.17.4|

# High-level flow

1) Enable iommu
2) Configure vfio-pci
3) Disable/don't allow orginal kernel driver feels responsible for the device
4) Configure KubeVirt / OpenShift Virt.

PCI devices I want to forward:

```shell
sh-5.1# lspci -nnk -d '1137:0043'
47:00.0 Ethernet controller [0200]: Cisco Systems Inc VIC Ethernet NIC [1137:0043] (rev a2)
        Subsystem: Cisco Systems Inc VIC 1225 PCIe Ethernet NIC [1137:0085]
        Kernel driver in use: enic
48:00.0 Ethernet controller [0200]: Cisco Systems Inc VIC Ethernet NIC [1137:0043] (rev a2)
        Subsystem: Cisco Systems Inc VIC 1225 PCIe Ethernet NIC [1137:0085]
        Kernel driver in use: enic
87:00.0 Ethernet controller [0200]: Cisco Systems Inc VIC Ethernet NIC [1137:0043] (rev a2)
        Subsystem: Cisco Systems Inc VIC 1225 PCIe Ethernet NIC [1137:0085]
        Kernel driver in use: enic
88:00.0 Ethernet controller [0200]: Cisco Systems Inc VIC Ethernet NIC [1137:0043] (rev a2)
        Subsystem: Cisco Systems Inc VIC 1225 PCIe Ethernet NIC [1137:0085]
        Kernel driver in use: enic
8b:00.0 Ethernet controller [0200]: Cisco Systems Inc VIC Ethernet NIC [1137:0043] (rev a2)
        Subsystem: Cisco Systems Inc VIC 1225 PCIe Ethernet NIC [1137:0085]
        Kernel driver in use: enic
sh-5.1#
```

# MachineConfig to achieve Point 1,2 and 3

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 100-virt-node-pci-passthrough
spec:
  config:
    ignition:
      version: 3.4.0
    storage:
      files:
        - contents:
            compression: ""
            source: data:,options%20vfio-pci%20ids%3D1137%3A0043%0A
          mode: 420
          overwrite: true
          path: /etc/modprobe.d/vfio.conf
        - contents:
            compression: ""
            source: data:,vfio-pci
          mode: 420
          overwrite: true
          path: /etc/modules-load.d/vfio-pci.conf
        - contents:
            compression: ""
            source: data:,blacklist%20enic%0A
          mode: 420
          overwrite: true
          path: /etc/modprobe.d/blacklist-enic.conf
  kernelArguments:
    - intel_iommu=on
    - enic.blacklist=1
    - rd.driver.blacklist=enic
```

# KubeVirt / OpenShift Virtualization configuration changes to achive point 4

```yaml
spec:
  permittedHostDevices:
    pciHostDevices:
    - pciDeviceSelector: 1137:0043
      resourceName: cisco.com/VIC_1225
```

# Check the node

```shell
$ oc describe node/ucs57 | grep -A10 'Allocatable:'
Allocatable:
  bridge.network.kubevirt.io/coe-bridge:  1k
  cisco.com/VIC_1225:                     4
  cpu:                                    59780m
  devices.kubevirt.io/kvm:                1k
  devices.kubevirt.io/tun:                1k
  devices.kubevirt.io/vhost-net:          1k
  ephemeral-storage:                      718240181082
  hugepages-1Gi:                          0
  hugepages-2Mi:                          0
  memory:                                 1028260784Ki
```
