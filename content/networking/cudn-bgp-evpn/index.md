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
