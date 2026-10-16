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
|VyOS|TBD|

## Architecture

The lab environment runs on a single Hetzner bare-metal server using
[hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4) to
provision OpenShift 4.22 via libvirt/KVM. A VyOS virtual machine acts as the
BGP edge router peering with the OVN-Kubernetes cluster network.

<!-- TODO: Add .drawio diagram of the lab topology -->

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
