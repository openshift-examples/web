---
title: Agent-based non-integrated
linktitle: Agent-based non-integrated
description: Agent-based non-integrated
tags: ['billy','Agent-based','non-integrated','vsphere','vmware']
---

# Agent-based non-integrated installation on vSphere

<https://docs.openshift.com/container-platform/4.13/installing/installing_with_agent_based_installer/preparing-to-install-with-agent-based-installer.html>

## Create all VM's

For example with Govc:

```bash
govc vm.create \
  -on=false \
  -m 16384 \
  -c 8 \
  -net 'VM Network' \
  -disk 120GB \
  -ds ose3-vmware \
  -folder /Boston/vm/rbohne \
  -g rhel9_64Guest \
  cp-{1,2}
..

for i in cp-{0,1,2} wp-{0,1}; do govc vm.change -vm /Boston/vm/rbohne/${i} -e disk.enableUUID=TRUE ;done

# Just for information
#for i in cp-{0,1,2} wp-{0,1}; do govc vm.power -off -force /Boston/vm/rbohne/${i} ;done
#for i in cp-{0,1,2} wp-{0,1}; do govc vm.power -on  /Boston/vm/rbohne/${i} ;done

```

## Collect mac-addresses

```ini
cp-0;00:50:56:89:5b:02
cp-1;00:50:56:89:dd:e4
cp-2;00:50:56:89:0d:fe
wp-0;00:50:56:89:e0:2c
wp-1;00:50:56:89:80:a3
```

## Get rendezvousIP

Boot with RHEL/RHCOS Live ISO cp-0 and get IP from DHCP

## Create configuration

??? example "agent-config.yaml"

    === "agent-config.yaml"

        ```yaml
        --8<-- "content/cluster-installation/vmware/agent-base-non-integrated/agent-config.yaml"
        ```

    === "curl"

        ```bash
        curl -L -O {{ page.canonical_url }}/agent-config.yaml
        ```

??? example "install-config.yaml"

    === "install-config.yaml"

        ```yaml
        --8<-- "content/cluster-installation/vmware/agent-base-non-integrated/install-config.yaml"
        ```

    === "curl"

        ```bash
        curl -L -O {{ page.canonical_url }}/install-config.yaml
        ```

## Create iso

```bash
openshift-install --dir vmw1/ agent create image
```

## Start installation

Attach the agent iso to all VM's and boot it.

Watch the output of cp-0 as rendezvous host and the others.
