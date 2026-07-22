---
title: Hosted Control Plane and Proxy
linktitle: Proxy
description: Solving proxy communication issues between HCP worker nodes and the hosted control plane
tags: ['hcp', 'proxy', 'no_proxy']
---
# Hosted Control Plane and Proxy

## Problem

In proxy environments, worker nodes of a hosted cluster route API server communication through the HTTP proxy. This causes failures because the connection between the worker nodes and the hosted control plane typically does not need (or cannot use) the proxy.

The first indicator is the `service-ca-operator` in namespace `openshift-service-ca-operator` not becoming ready.

```shell title="oc logs -f deployment/service-ca-operator -n openshift-service-ca-operator"
F0603 19:38:28.981007       1 cmd.go:162] failed checking apiserver connectivity: client rate limiter Wait returned an error: context deadline exceeded - error from a previous attempt: read tcp 172.40.0.7:40588->172.50.0.1:443: read: connection reset by peer
```

Other symptoms include:

* Nodes not joining the cluster or reporting `NotReady`
* Pods failing to communicate with the API server
* Konnectivity or kubelet connectivity issues

## Root cause

On HCP worker nodes, the static pod `/etc/kubernetes/manifests/kube-apiserver-proxy.yaml` handles the connection to the hosted control plane's API server:

* **Without proxy**: `kube-apiserver-proxy` runs as a simple HAProxy that forwards traffic directly to the API server.
* **With proxy**: `kube-apiserver-proxy` acts as a reverse proxy that attempts to tunnel API traffic through the configured HTTP proxy.

## Solution

Adding `kubernetes` to `noProxy` forces the rollout of HAProxy with a direct connection instead of routing the traffic through the proxy.

```yaml title="HostedCluster spec.configuration.proxy"
spec:
  configuration:
    proxy:
      httpProxy: 'http://192.168.201.2:3128'
      httpsProxy: 'http://192.168.201.2:3128'
      noProxy: 'kubernetes,192.168.201.0/24,.apps.ocp7.stormshift.coe.muc.redhat.com'
      trustedCA:
        name: 'redhat-root-ca-bundle-v1'
```

!!! warning
    Always include `kubernetes` in `noProxy` when running a hosted cluster behind a proxy. Additionally include your cluster and service network CIDRs and any other endpoints that should be reached directly.

Manual workaround (deploy HAProxy as `kube-apiserver-proxy`): <https://gist.github.com/rbo/d8fe1aee94c53355a6e7e502bfd1cdbf>

## References

* [OCPBUGS-33237](https://issues.redhat.com/browse/OCPBUGS-33237)
* [OCPBUGS-46587](https://issues.redhat.com/browse/OCPBUGS-46587)
* [OCPBUGS-59316](https://issues.redhat.com/browse/OCPBUGS-59316)
