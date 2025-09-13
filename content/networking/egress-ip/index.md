---
title: Egress IP
linktitle:  Egress IP
description: Egress IP demo
tags: ['Egress','v4.19']
---
# Some information

Official documentation: <https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/ovn-kubernetes_network_plugin/configuring-egress-ips-ovn>

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.19.14|

## Deploy Webserver

TODO: Double check source IP

This webserver is our target to check the source ip adress.

```shell
oc new-project rbohne-target
oc apply -k git@github.com:openshift-examples/kustomize/components/simple-http-server
```

## Prepare cluster

```shell
% oc get nodes -l node-role.kubernetes.io/worker
NAME                       STATUS   ROLES    AGE   VERSION
inf44.coe.muc.redhat.com   Ready    worker   74d   v1.32.5
ocp1-worker-0              Ready    worker   79d   v1.32.5
ocp1-worker-1              Ready    worker   79d   v1.32.5
ocp1-worker-2              Ready    worker   79d   v1.32.5

% oc label node/ocp1-worker-0  k8s.ovn.org/egress-assignable=""
node/ocp1-worker-0 labeled
% oc label node/ocp1-worker-1  k8s.ovn.org/egress-assignable=""
node/ocp1-worker-1 labeled
% oc label node/ocp1-worker-2  k8s.ovn.org/egress-assignable=""
node/ocp1-worker-2 labeled

oc apply -f - <<EOF
heredoc> apiVersion: k8s.ovn.org/v1
kind: EgressIP
metadata:
  name: egress-coe
spec:
  egressIPs:
  - 10.32.105.72
  - 10.32.105.73
  namespaceSelector:
    matchLabels:
      egress: coe
heredoc> EOF
egressip.k8s.ovn.org/egress-coe created
```

## Deployment

```shell
oc new-project rbohne-egress
oc deploy -k simple-nginx...
oc rsh deployment/simple-nginx
curl $WEBSERVER

oc label namespace/rbohne-egress egress=coe

```

```log
10.32.96.44 - - [31/Aug/2025:11:54:00 +0200] "GET / HTTP/1.1" 301 247 "-" "curl/7.76.1"
10.32.105.72 - - [31/Aug/2025:11:56:31 +0200] "GET / HTTP/1.1" 301 247 "-" "curl/7.76.1"
```

sh-5.1# ip -br a show dev br-ex
br-ex            UNKNOWN        10.32.105.69/20 169.254.0.2/17 10.32.105.72/32
sh-5.1#