---
title: Agent-based (proxy)
linktitle: Agent-based (proxy)
description: Agent-based OpenShift install behind a proxy on OpenShift Virtualization—DNS, Squid, bastion-built agent ISO, and cluster VMs on a dedicated VLAN.
tags: ['ocp-v','kubevirt','cnv','mno','installation', 'agent-base']
---
# Agent-based installation with Proxy on OpenShift Virt

This walkthrough installs an **on-premise cluster with the Agent-based Installer** on **OpenShift Virtualization** (lab: **ISAR**). Cluster nodes live on a **dedicated VLAN (2001)**; outbound HTTP/HTTPS uses a **Squid proxy**, cluster DNS is served on the same segment, and a **bastion** builds the agent ISO and uploads it for the control-plane and worker VMs.

**Official documentation:** [Installing an on-premise cluster with the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_an_on-premise_cluster_with_the_agent-based_installer/index)

## Overview

**What you deploy:** On VLAN 2001 DNS, an HTTP proxy, and a bastion with `openshift-install`, `oc`, and `virtctl`—then six VMs (three control plane, three workers) that boot the generated `agent.x86_64.iso`.

**Why a proxy:** Restricted networks do not allow nodes to reach Red Hat mirrors and APIs directly. Traffic is sent to the proxy (for example `192.168.201.2:3128`) so pulls and related traffic leave the segment in a controlled way. DNS (for example `192.168.201.3`) resolves API and ingress names for the install.

**Flow:**

1. Create a project on ISAR and attach VLAN 2001 (bridge manifest).
2. Deploy DNS and the Squid proxy.
3. Deploy the bastion; verify proxy and DNS; install client tools.
4. Author `install-config.yaml` and `agent-config.yaml`, run `openshift-install agent create image`, upload the ISO to the cluster, and create VMs from the template using the MACs in the table below.

**Tested with:**

|Component|Version|
|---|---|
|OpenShift|v4.20.14|

## VLAN 2001 IP Overview

|IP|MAC|Usage|
|---|---|---|
|192.168.201.3|0E:C0:EF:A8:C9:03|DNS|
|192.168.201.2|0E:C0:EF:A8:C9:02|Proxy|
|192.168.201.4|0E:C0:EF:A8:C9:04|bastion|
|192.168.201.10||API VIP|
|192.168.201.11||INGRESS VIP|
|192.168.201.12|0E:C0:EF:A8:C9:0C|cp-0|
|192.168.201.13|0E:C0:EF:A8:C9:0D|cp-1|
|192.168.201.14|0E:C0:EF:A8:C9:0E|cp-2|
|192.168.201.15|0E:C0:EF:A8:C9:0F|worker-0|
|192.168.201.16|0E:C0:EF:A8:C9:10|worker-1|
|192.168.201.17|0E:C0:EF:A8:C9:11|worker-2|

## Prepare the project/namespace on ISAR

```shell
oc new-project rbohne-2026-03-13-proxy
```

Let's attach vlan 2001:

=== "oc apply"

    ```
    oc apply -f {{ page.canonical_url }}coe-bridge-2001.yaml
    ```

=== "coe-bridge-2001.yaml"

    ```yaml
    --8<-- "content/cluster-installation/agent-base-proxy/coe-bridge-2001.yaml"
    ```

### Deploy dns server

=== "oc apply"

    ```
    oc apply -f {{ page.canonical_url }}dns-config.yaml
    ```

=== "dns-config.yaml"

    ```yaml
    --8<-- "content/cluster-installation/agent-base-proxy/dns-config.yaml"
    ```

### Deploy proxy server

=== "oc apply"

    ```
    oc apply -f {{ page.canonical_url }}squid-proxy.yaml
    ```

=== "squid-proxy.yaml"

    ```yaml
    --8<-- "content/cluster-installation/agent-base-proxy/squid-proxy.yaml"
    ```

### Deploy bastion

```shell
oc process -n openshift rhel9-desktop-medium -p=NAME=bastion | oc apply -f -
```

Configure VM at WebUI

- Attach to "public" network
- Attach to vlan 201
- Boot VM: `virtctl start bastion`
- Connect to console
- Configure vlan 201 interface
- Test proxy `curl http://192.168.201.2:3128/`
- Test dns `dig api.proxy.test @192.168.201.3`
- Download and install: openshift-install-fips [openshift-install-rhel9-amd64.tar.gz](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.20.14/openshift-install-rhel9-amd64.tar.gz)
- Download and install: oc [openshift-client-linux-amd64-rhel9-4.20.14.tar.gz](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.20.14/openshift-client-linux-amd64-rhel9-4.20.14.tar.gz)
- Download and install: virtctl

## OpenShift installation

### Create agent.iso on bastion

!!! example "install-config.yaml"

    ```yaml
    --8<-- "content/cluster-installation/agent-base-proxy/install-config.yaml"
    ```

!!! example "agent-config.yaml"

    ```yaml
    --8<-- "content/cluster-installation/agent-base-proxy/agent-config.yaml"
    ```

Create ISO:

```shell
[cloud-user@bastion ~]$ openshift-install-fips agent create image --dir=conf/
INFO Configuration has 3 master replicas, 0 arbiter replicas, and 3 worker replicas
INFO The rendezvous host IP (node0 IP) is 192.168.201.12
INFO Extracting base ISO from release payload
INFO Verifying cached file
INFO Using cached Base ISO /home/cloud-user/.cache/agent/image_cache/coreos-x86_64.iso
INFO Consuming Install Config from target directory
INFO Consuming Agent Config from target directory
INFO Generated  ISO at conf/agent.x86_64.iso
```

Upload ISO to ISAR:

```shell
virtctl image-upload pvc agent-iso \
    --size=2Gi \
    --image-path=agent.x86_64.iso \
    --storage-class coe-netapp-nas \
    --volume-mode=filesystem \
    --access-mode=ReadWriteMany \
    --force-bind --insecure
```

### Deploy VirtualMachines

```shell
oc process -f vm-template.yaml -p NAME=cp-0 -p MAC=0E:C0:EF:A8:C9:0C | oc apply -f  -
oc process -f vm-template.yaml -p NAME=cp-1 -p MAC=0E:C0:EF:A8:C9:0D | oc apply -f  -
oc process -f vm-template.yaml -p NAME=cp-2 -p MAC=0E:C0:EF:A8:C9:0E | oc apply -f  -
oc process -f vm-template.yaml -p NAME=worker-0 -p MAC=0E:C0:EF:A8:C9:0F | oc apply -f  -
oc process -f vm-template.yaml -p NAME=worker-1 -p MAC=0E:C0:EF:A8:C9:10 | oc apply -f  -
oc process -f vm-template.yaml -p NAME=worker-2 -p MAC=0E:C0:EF:A8:C9:11 | oc apply -f  -
```
