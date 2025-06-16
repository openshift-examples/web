---
title: LLDP
linktitle: LLDP
description: Run LLDPd as DaemonSet
tags: ['lldp','v4.18']
---
# Run LLDPd as DaemonSet

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18.14|

## Create project/namespace

!!! info Node selector
    Empty node selector, to run the lldpd on all nodes

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}namespace.yaml
    ```

=== "namespace.yaml"

    ```yaml
    --8<-- "content/networking/lldpd/namespace.yaml"
    ```

## Build the LLDPd Image (RHEL Image)

* To install and configure entitelt builds, please follo: [Entitled builds and OpenShift 4](../../build/entitled.md)

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}build.yaml
    ```

=== "build.yaml"

    ```yaml
    --8<-- "content/networking/lldpd/build.yaml"
    ```

## Run lldpd

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}daemonset.yaml
    ```

=== "daemonset.yaml"

    ```yaml
    --8<-- "content/networking/lldpd/daemonset.yaml"
    ```

## Check lldpd

??? example "Run daemonset/lldpd lldpcli show neighbors"

    ```shell
    oc rsh daemonset/lldpd lldpcli show neighbors
    -------------------------------------------------------------------------------
    LLDP neighbors:
    -------------------------------------------------------------------------------
    Interface:    enp79s0f0, via: LLDP, RID: 1, Time: 0 day, 00:01:16
    Chassis:
        ChassisID:    mac 00:1c:73:7f:b4:d7
        SysName:      arista-rj45.coe.muc.redhat.com
        SysDescr:     Arista Networks EOS version 4.27.0F running on an Arista Networks DCS-7050TX-64
        MgmtIP:       10.32.104.2
        MgmtIface:    999001
        Capability:   Bridge, on
        Capability:   Router, off
    Port:
        PortID:       ifname Ethernet20
        TTL:          120
    -------------------------------------------------------------------------------
    Interface:    enp79s0f1, via: LLDP, RID: 1, Time: 0 day, 00:01:17
    Chassis:
        ChassisID:    mac 00:1c:73:7f:b4:d7
        SysName:      arista-rj45.coe.muc.redhat.com
        SysDescr:     Arista Networks EOS version 4.27.0F running on an Arista Networks DCS-7050TX-64
        MgmtIP:       10.32.104.2
        MgmtIface:    999001
        Capability:   Bridge, on
        Capability:   Router, off
    Port:
        PortID:       ifname Ethernet15
        TTL:          120
    -------------------------------------------------------------------------------
    Interface:    veth543afbbd, via: CDPv2, RID: 3, Time: 0 day, 00:01:05
    Chassis:
        ChassisID:    local ocp1-worker-0.ocp1.stormshift.coe.muc.redhat.com
        SysName:      ocp1-worker-0.ocp1.stormshift.coe.muc.redhat.com
        SysDescr:     Linux running on
                    Red Hat Enterprise Linux 9.6 (Plow) Linux 5.14.0-427.72.1.el9_4.x86_64 #1 SMP PREEMPT_DYNAMIC Fri May 30 09:53:21 EDT 2025 x86_64
        MgmtIP:       10.131.0.2
        Capability:   Station, on
    Port:
        PortID:       ifname enp1s0
        PortDescr:    enp1s0
        TTL:          120
    -------------------------------------------------------------------------------
    ```

??? example "Run daemonset/lldpd lldpcli show neighbors"

    ```shell
    arista-rj45#show lldp neighbors
    Last table change time   : 0:02:13 ago
    Number of table inserts  : 80
    Number of table deletes  : 53
    Number of table drops    : 0
    Number of table age-outs : 1

    Port            Neighbor Device ID                   Neighbor Port ID    TTL
    ------------ ------------------------------------ ---------------------- ---
    Et1             sw01-dist-lab.muc.redhat.com         ge-0/0/1            120
    Et9             ucs56.isar.coe.muc.redhat.com        80e0.1d36.ffac      120
    Et11            ecf4.bbf1.0470                       00f4.bbf1.0470      120
    Et13            storm2.isar.coe.muc.redhat.com       ecf4.bbf1.6b28      120
    Et15            ucs55.isar.coe.muc.redhat.com        70e4.22c4.290c      120
    Et17            ceph10.isar.coe.muc.redhat.com       a036.9f07.ffff      120
    Et19            ceph11.isar.coe.muc.redhat.com       a036.9f07.ffff      120
    Et20            ucs55.isar.coe.muc.redhat.com        70e4.22c4.290a      120
    Et21            ceph12.isar.coe.muc.redhat.com       a036.9f06.8e2e      120
    Et22            ucs56.isar.coe.muc.redhat.com        80e0.1d36.ffae      120
    Et24            storm6.isar.coe.muc.redhat.com       a036.9fe5.0d9e      120
    Et31            storm3.isar.coe.muc.redhat.com       ecf4.bbf1.4ef2      120
    Et32            storm5.isar.coe.muc.redhat.com       a036.9fe5.14bc      120
    Et33            storm2.isar.coe.muc.redhat.com       ecf4.bbf1.6b2a      120
    Et34            storm5.isar.coe.muc.redhat.com       a036.9fe5.14be      120
    Et35            ucs57.isar.coe.muc.redhat.com        58ac.7803.18b2      120
    Et36            ucs57.isar.coe.muc.redhat.com        58ac.7803.18b0      120
    Et37            storm6.isar.coe.muc.redhat.com       a036.9fe5.0d9c      120
    Et40            storm3.isar.coe.muc.redhat.com       ecf4.bbf1.4ef0      120
    Et41            ceph11.isar.coe.muc.redhat.com       a036.9f07.032c      120
    Et45            ceph10.isar.coe.muc.redhat.com       a036.9f07.04c0      120
    Et47            ceph12.isar.coe.muc.redhat.com       a036.9f06.8e2c      120
    Et52/1          arista-sfp.coe.muc.redhat.com        Ethernet19/1        120
    Et52/2          arista-sfp.coe.muc.redhat.com        Ethernet19/2        120
    Et52/3          arista-sfp.coe.muc.redhat.com        Ethernet19/3        120
    Et52/4          arista-sfp.coe.muc.redhat.com        Ethernet19/4        120
    Ma1             sw01-dist-lab.muc.redhat.com         ge-0/0/43           120
    ```
