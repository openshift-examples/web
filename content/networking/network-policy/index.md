---
title: Network Policy
linktitle: Network Policy
weight: 16100
description: TBD
---

# Network Policy

Official documentation: [About network policy
](https://docs.openshift.com/container-platform/latest/networking/network_policy/about-network-policy.html)

## Basics

1. Based on labeling or annotations
2. Empty label selector match all
3. Rules for allowing
    * Ingress -&gt; who can connect to this POD
    * Egress -&gt; where can this POD connect to
4. **Rules**
    * traffic is allowed unless a Network Policy selecting the POD
    * traffic is denied if pod is selected in policie but none of them have any rules allowing it
    * => You can only write rules that allow traffic!
    * Scope: Namespace

## Demo Network Policies

Please check

* [OVNKubernetes](OVNKubernetes.md)
* [OpenShiftSDN](OpenShiftSDN.md)
