---
title: Multus
linktitle: Multus
weight: 16090
description: TBD
---
# Multus

!!! notice
    Not comlete yet....

* [Introduction to Linux interfaces for virtual networking](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking)
* OpenShift Documentation: [Understanding multiple networks](https://docs.openshift.com/container-platform/4.2/networking/multiple-networks/understanding-multiple-networks.html)

## ipvlan example

Example based on my lab build with [hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4)

### Configure additional network
```
oc edit networks.operator.openshift.io cluster
```

Add `additionalNetworks`:
```
  additionalNetworks:
  - name: extra-network-1
    namespace: cni-test
    simpleMacvlanConfig:
      ipamConfig:
        type: DHCP
    type: SimpleMacvlan
```

Check the network attachment definitions:
```
$ oc get network-attachment-definitions/extra-network-1 -n cni-test
NAME              AGE
extra-network-1   14h
```

### Create a pod


```
oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: multus
  namespace: cni-test
  annotations:
    k8s.v1.cni.cncf.io/networks: extra-network-1
spec:
  containers:
    - name: rhel
      image: registry.access.redhat.com/rhel7/rhel-tools
      command: [ "/bin/sh", "-c", "while true ; do date; sleep 10; done;" ]
  restartPolicy: Never
EOF
```