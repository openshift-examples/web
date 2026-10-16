---
title: CUDN with BGP EVPN
linktitle: CUDN with BGP EVPN
description: Cluster User Defined Network (CUDN) with BGP EVPN on OpenShift
tags: ['CUDN','BGP','EVPN','VyOS','networking','v4.22']
---
# CUDN with BGP EVPN

Cluster User Defined Networks (CUDN) with BGP EVPN extends OVN-Kubernetes
user-defined networks beyond the cluster boundary. By using BGP EVPN as the
interconnect, external routers can participate in the overlay network, enabling
seamless Layer 2 and Layer 3 connectivity between workloads inside OpenShift
and services outside the cluster.

Official documentation:

* [User-defined networks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/networking/multiple-networks#about-user-defined-networks)

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.22|
|VyOS|rolling (nightly)|

## Lab environment

The lab runs on a single Hetzner bare-metal server using
[hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4) to
provision OpenShift 4.22 via libvirt/KVM. A compact cluster (3 control-plane
nodes, no dedicated workers) is used. A VyOS virtual machine acts as the
external BGP router peering with OpenShift's FRR.

## Network design

### Libvirt networks

|Network|Subnet|Purpose|DHCP|
|---|---|---|---|
|`demo`|`192.168.52.0/24`|OCP machine network + BGP/VXLAN underlay|Yes (hetzner-ocp4)|
|`evpn-tenant`|No IP (pure L2)|Bridge segment between VyOS and external VM|No|

### IP assignments (underlay)

|VM|IP|Role|
|---|---|---|
|control-plane-0|`192.168.52.10`|CP + workloads, FRR/VTEP (AS 65001)|
|control-plane-1|`192.168.52.11`|CP + workloads, FRR/VTEP (AS 65001)|
|control-plane-2|`192.168.52.12`|CP + workloads, FRR/VTEP (AS 65001)|
|VyOS|`192.168.52.200`|BGP router / VTEP (AS 65011)|
|External VM (Fedora)|underlay: none|Connected via `evpn-tenant` only|

### CUDN overlay

|Property|Value|
|---|---|
|CUDN name|`cudn-bgp-evpn`|
|Topology|Layer2|
|Overlay subnet|`10.100.0.0/24`|
|VNI|Assigned by OVN-K (or manually set)|
|Participants|CUDN pods/VMs on OCP + external VM via VyOS bridge|

### BGP EVPN peering

```text
  control-plane-0 (FRR) ◄──► VyOS (FRR)
  control-plane-1 (FRR) ◄──► VyOS (FRR)
  control-plane-2 (FRR) ◄──► VyOS (FRR)
  AS 65001                    AS 65011
```

* **Type**: eBGP (different ASNs)
* **Address family**: L2VPN EVPN
* **Route types**: Type-2 (MAC/IP), Type-3 (Inclusive Multicast for BUM)
* **VXLAN tunnels**: Formed automatically over `192.168.52.0/24` underlay

### VyOS role

VyOS serves two functions:

1. **BGP peering** — peers with FRR on each OCP control-plane node, exchanges
   EVPN routes
2. **Bridging** — bridges the VXLAN interface (bound to the CUDN's VNI) with
   the `evpn-tenant` libvirt network, so the external VM lands on the overlay

```text title="VyOS internals"
eth0 (demo network, 192.168.52.200) ── underlay for BGP + VXLAN
vxlan0 (VNI matching CUDN) ──┐
                              ├── bridge → eth1
eth1 (evpn-tenant network) ──┘
```

### Topology overview

```text
┌───────────────────────────────────────────────────────────────┐
│  Hetzner bare-metal                                           │
│                                                               │
│  libvirt: demo (192.168.52.0/24) ─── underlay                 │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │
│  │ CP-0       │ │ CP-1       │ │ CP-2       │ │   VyOS     │ │
│  │ .10        │ │ .11        │ │ .12        │ │ .200       │ │
│  │ FRR/VTEP   │ │ FRR/VTEP   │ │ FRR/VTEP   │ │ FRR/VTEP   │ │
│  │ AS 65001   │ │ AS 65001   │ │ AS 65001   │ │ AS 65011   │ │
│  └────────────┘ └────────────┘ └────────────┘ │eth0↑ eth1↓ │ │
│                                               │    bridge  │ │
│                                               └─────┬──────┘ │
│  libvirt: evpn-tenant (L2 only) ────────────────────┤        │
│  ┌──────────────┐                                   │        │
│  │ External VM  ├───────────────────────────────────┘        │
│  │ 10.100.0.x   │  (overlay IP, L2 adjacent to CUDN)        │
│  └──────────────┘                                            │
│                                                               │
│  CUDN overlay: 10.100.0.0/24 (Layer2, BGP EVPN)              │
│  Pod on CP-0: 10.100.0.10 ◄──► Ext VM: 10.100.0.50          │
└───────────────────────────────────────────────────────────────┘
```

### External VM

* Connected only to `evpn-tenant` libvirt network
* Gets an IP from `10.100.0.0/24` (static or via DHCP from VyOS)
* Layer 2 adjacent to CUDN pods inside OCP
* Can ping/curl pods on the CUDN directly

### Extensibility

The design supports extending the EVPN fabric beyond the single server:

* **Second Hetzner server** — VyOS on server 2 peers with VyOS on server 1
  over Hetzner internal network
* **Remote VM/site** — wrap the underlay in WireGuard/IPsec, BGP + VXLAN runs
  inside the tunnel
* **Another OCP cluster** — FRR on cluster 2 peers with VyOS

VyOS acts as the border gateway — remote peers only need to talk to VyOS, not
to every OCP node.

## Setup

### Prerequisites

* OpenShift 4.22 compact cluster deployed via
  [hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4)
* SSH access to the Hetzner bare-metal host
* VyOS rolling ISO downloaded from
  [VyOS rolling releases](https://vyos.net/get/nightly-builds/)

### hetzner-ocp4 cluster.yml

=== "Download: cluster.yml"

    ```shell
    curl -L -O {{ page.canonical_url }}cluster.yml
    ```

=== "cluster.yml"

    ```yaml
    --8<-- "content/networking/cudn-bgp-evpn/cluster.yml"
    ```

!!! info

    `masters_schedulable: true` is required for a compact cluster (0 workers)
    so that workloads (including CUDN pods) can be scheduled on the
    control-plane nodes.

### Step 1: Create the evpn-tenant libvirt network

Create an L2-only libvirt network on the Hetzner host for the bridge segment
between VyOS and the external VM. This network has no IP addresses or DHCP —
it is a pure Layer 2 segment.

=== "Download: evpn-tenant-net.xml"

    ```shell
    curl -L -O {{ page.canonical_url }}evpn-tenant-net.xml
    ```

=== "evpn-tenant-net.xml"

    ```xml
    --8<-- "content/networking/cudn-bgp-evpn/evpn-tenant-net.xml"
    ```

```shell title="Define, start and autostart the network"
virsh net-define evpn-tenant-net.xml
virsh net-start evpn-tenant
virsh net-autostart evpn-tenant
```

```shell title="Verify"
% virsh net-list
 Name          State    Autostart   Persistent
-------------------------------------------------
 demo          active   yes         yes
 evpn-tenant   active   yes         yes
```

### Step 2: Deploy VyOS VM

Download the VyOS rolling ISO and create the VM with two NICs using
`virt-install`:

```shell title="Deploy VyOS VM via virt-install"
virt-install \
  --name vyos \
  --ram 2048 \
  --vcpus 2 \
  --os-variant debian11 \
  --cdrom /var/lib/libvirt/images/vyos-rolling-latest.iso \
  --network network=demo,model=virtio \
  --network network=evpn-tenant,model=virtio \
  --disk size=10,bus=virtio \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole
```

After boot, install VyOS to disk:

```shell title="Install VyOS to disk (run inside VyOS)"
install image
```

Then shut down, remove the CDROM, and start again:

```shell title="Remove CDROM and restart"
virsh destroy vyos
virsh change-media vyos --path /var/lib/libvirt/images/vyos-rolling-latest.iso --eject
virsh start vyos
```

### Step 3: Configure VyOS

Connect to the VyOS console and enter configuration mode:

```shell
configure
```

Configure eth0 (underlay on the demo network) and eth1 (bridge to
evpn-tenant, no IP):

```shell title="Interface configuration"
set interfaces ethernet eth0 address '192.168.52.200/24'
set interfaces ethernet eth0 description 'Underlay - demo network'
set interfaces ethernet eth1 description 'EVPN tenant bridge'
```

Create the VXLAN interface (VNI must match the CUDN VNI) and bridge it with
eth1:

```shell title="VXLAN and bridge configuration"
set interfaces vxlan vxlan100 vni 100
set interfaces vxlan vxlan100 source-address '192.168.52.200'
set interfaces vxlan vxlan100 port 4789
set interfaces bridge br100 member interface vxlan100
set interfaces bridge br100 member interface eth1
set interfaces bridge br100 description 'EVPN tenant bridge'
```

Configure BGP with AS 65011, enable EVPN, and add the three OCP control-plane
nodes as neighbors (AS 65001):

```shell title="BGP EVPN configuration"
set protocols bgp system-as '65011'
set protocols bgp address-family l2vpn-evpn advertise-all-vni
set protocols bgp neighbor 192.168.52.10 remote-as '65001'
set protocols bgp neighbor 192.168.52.10 address-family l2vpn-evpn
set protocols bgp neighbor 192.168.52.11 remote-as '65001'
set protocols bgp neighbor 192.168.52.11 address-family l2vpn-evpn
set protocols bgp neighbor 192.168.52.12 remote-as '65001'
set protocols bgp neighbor 192.168.52.12 address-family l2vpn-evpn
```

Commit and save:

```shell
commit
save
exit
```

### Step 4: Configure OpenShift CUDN with BGP EVPN

!!! warning

    The exact CRDs and FRR configuration for CUDN with BGP EVPN interconnect
    on OpenShift 4.22 depend on the OVN-Kubernetes version and feature gates.
    Verify against the official documentation before applying.

Create the `ClusterUserDefinedNetwork` with BGP EVPN:

```yaml title="cudn-bgp-evpn.yaml"
apiVersion: k8s.ovn.org/v1
kind: ClusterUserDefinedNetwork
metadata:
  name: cudn-bgp-evpn
spec:
  namespaceSelector:
    matchLabels:
      network: bgp-evpn
  network:
    layer2:
      subnets:
        - cidr: "10.100.0.0/24"
      role: Primary
    topology: Layer2
```

```shell
oc apply -f cudn-bgp-evpn.yaml
```

Configure FRR on the OCP side to peer with VyOS. This is typically done via
the MetalLB operator's `FRRConfiguration` or the OVN-Kubernetes BGP
configuration:

```yaml title="frr-config.yaml"
apiVersion: frrk8s.metallb.io/v1beta1
kind: FRRConfiguration
metadata:
  name: bgp-evpn-peering
  namespace: metallb-system
spec:
  bgp:
    routers:
      - asn: 65001
        neighbors:
          - address: 192.168.52.200
            asn: 65011
            toReceive:
              allowed:
                prefixes:
                  - prefix: 10.100.0.0/24
            toAdvertise:
              allowed:
                prefixes:
                  - prefix: 10.100.0.0/24
```

```shell
oc apply -f frr-config.yaml
```

### Step 5: Deploy external test VM

Create a Fedora VM connected only to the `evpn-tenant` network:

```shell title="Deploy external Fedora VM"
virt-install \
  --name fedora-evpn-test \
  --ram 2048 \
  --vcpus 2 \
  --os-variant fedora-unknown \
  --location https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/os/ \
  --network network=evpn-tenant,model=virtio \
  --disk size=20,bus=virtio \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --extra-args "console=ttyS0"
```

After installation, configure a static IP on the overlay subnet:

```shell title="Configure static IP on the external VM"
nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 10.100.0.50/24 \
  ipv4.gateway 10.100.0.1
nmcli con up "Wired connection 1"
```

## Validation

### Check BGP sessions on VyOS

```shell title="VyOS: show BGP summary"
show bgp summary
```

Expected: 3 established sessions with the control-plane nodes.

### Check EVPN routes on VyOS

```shell title="VyOS: show EVPN routes"
show bgp l2vpn evpn
```

### Test connectivity

From the external VM, test connectivity to a pod on the CUDN:

```shell title="Ping a CUDN pod from the external VM"
ping -c4 10.100.0.x
```

```shell title="Curl a service on the CUDN"
curl http://10.100.0.x:8080
```

## Content

{% set section = page.parent %}
{% if section and section.children %}
{% for c in section.children if c.title != page.title %}
{% if c.abs_url is string %}

* [{{ c.title }}]({{ c.canonical_url }})

{% else %}

* **[{{ c.title }}]({{ c.children[0].canonical_url }})**

{% endif %}
{% endfor %}
{% endif %}
