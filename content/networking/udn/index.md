---
title: User-defined networks
linktitle: User-defined networks
description: User-defined networks (UDN)
tags: ['UDN','v4.18']
---
# User-defined networks (UDN)

![](udn.drawio)

Official documentation:

* [16.2.1. About user-defined networks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking/multiple-networks#about-user-defined-networks)

Resources:

* <https://github.com/maiqueb/fosdem2025-p-udn/tree/main>
* <https://asciinema.org/a/699323>
* `203.0.113.0/24` - [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml)

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18.8|
|OpenShift Virt|v4.18.2|

![](overview.drawio)

## Namespaces

|Tanent|Namespace|Color|UDN or CUDN|P-UDN IP Range|
|---|---|---|---|---|
|tanent-1|namespace-1|red|UDN (udn-1)|`192.0.2.0/24`|
|tanent-2|namespace-2|green|UDN (udn-2)|`10.255.0.0/16`|
|tanent-3|namespace-3|blue|CUDN (cudn-3)|`203.0.113.0/24`|
|tanent-4|namespace-4|orange|CUDN (cudn-3)|`203.0.113.0/24`|

## Deploy

```shell
oc apply -k overlays/tentant-1
oc apply -k overlays/tentant-2
oc apply -k overlays/tentant-3
```

```shell
$ oc get namespaces -l tentant -L tentant
NAME          STATUS   AGE     TENTANT
namespace-1   Active   4m1s    tentant-1
namespace-2   Active   3m51s   tentant-2
namespace-3   Active   3m14s   tentant-3
namespace-4   Active   3m13s   tentant-3

$ oc get pods -o go-template-file=podlist-with-p-udn.gotemplate -A -l tentant  | jq ' (.[] | [.node,.namespace, .udn[1].ips[0], .udn[0].ips[0], .name]) | @tsv' -r
ocp1-worker-0   namespace-1     192.0.2.10      10.131.0.201    agnhost-7f79bb7dc-t8rfg
ocp1-worker-0   namespace-1     192.0.2.9       10.131.0.202    rhel-support-tools-7c89889f94-wq2gj
ocp1-worker-1   namespace-1     192.0.2.17      10.128.3.55     simple-http-server-bb9ccffd4-74j47
ocp1-worker-2   namespace-1     192.0.2.11      10.129.2.131    simple-http-server-bb9ccffd4-jq4bb
ocp1-worker-0   namespace-1     192.0.2.16      10.131.0.223    simple-http-server-bb9ccffd4-xll6x
ocp1-worker-0   namespace-2     10.255.2.6      10.131.0.220    agnhost-59964fb864-hp46z
ocp1-worker-0   namespace-2     10.255.2.8      10.131.0.221    rhel-support-tools-7cfb68d78f-89jkl
ocp1-worker-0   namespace-2     10.255.2.7      10.131.0.222    simple-http-server-7c567b8c4c-2pph6
ocp1-worker-1   namespace-2     10.255.3.4      10.128.3.54     simple-http-server-7c567b8c4c-brqtl
ocp1-worker-2   namespace-2     10.255.0.4      10.129.2.137    simple-http-server-7c567b8c4c-mjgwc
ocp1-worker-2   namespace-3     203.0.113.22    10.129.2.135    agnhost-f4b987769-kcmvs
ocp1-worker-0   namespace-3     203.0.113.25    10.131.0.207    rhel-support-tools-5b999555b4-w2qv5
ocp1-worker-2   namespace-3     203.0.113.23    10.129.2.134    simple-http-server-6b84977478-7kkhd
ocp1-worker-1   namespace-3     203.0.113.29    10.128.3.56     simple-http-server-6b84977478-pbj4d
ocp1-worker-0   namespace-3     203.0.113.30    10.131.0.224    simple-http-server-6b84977478-wn6kl
ocp1-worker-0   namespace-4     203.0.113.26    10.131.0.203    agnhost-f4b987769-vxtl7
ocp1-worker-0   namespace-4     203.0.113.24    10.131.0.204    rhel-support-tools-5b999555b4-5kgbs
ocp1-worker-0   namespace-4     203.0.113.33    10.131.0.225    simple-http-server-6b84977478-mqhj4
ocp1-worker-2   namespace-4     203.0.113.21    10.129.2.133    simple-http-server-6b84977478-rnc2c
ocp1-worker-1   namespace-4     203.0.113.35    10.128.3.57     simple-http-server-6b84977478-v7xhz
```

* Why is ip's of UDN nocht in pod status `podIPs` ?

## Testing

### ⚠️ Network Policy

### ⚠️ MultiNetworkPolicy

### ⚠️ Services

### ✅ Ingress

Works only because of pod annotation

```yaml
        k8s.ovn.org/open-default-ports: |
          - protocol: tcp
            port: 8080
```

### ⚠️ Direct access

### ⚠️ VM Live Migration

### ⚠️ Secondary-UDN

### ✅ Layer2

* Tentant 1 is Layer 2

### ✅ Layer3

* Tentant 2 is Layer 3

### ⏱️ Local (Available with 4.19)
