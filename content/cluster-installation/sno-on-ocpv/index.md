---
title: SNO on OCP-V
linktitle: SNO on OCP-V
description: Single Node OpenShift on OpenShift Virtualization
tags: ['ocp-v','kubevirt','cnv','sno','installation']
---

# Single Node OpenShift on OpenShift Virtualization

## DNS Records

### Kubernetes Service type load balancer

=== "service.yaml"

    ```yaml
    --8<-- "content/cluster-installation/sno-on-ocpv/service.yaml"
    ```

=== "oc apply"

    ```bash
    oc apply -f {{ page.canonical_url }}/service.yaml
    ```

Get EXTERNAL-IP `oc get svc sno1-rbohne-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`

Create DNS Records to EXTERNAL-IP

* api-int.*cluster-name*.*baseDomain*
* api.*cluster-name*.*baseDomain*
* \*.apps.*cluster-name*.*baseDomain*

## Installations

Official documentation: <https://docs.openshift.com/container-platform/latest/installing/installing_sno/install-sno-installing-sno.html>

=== "install-config.yaml"

    ```yaml
    --8<-- "content/cluster-installation/sno-on-ocpv/install-config.yaml"
    ```

=== "Download"

    ```bash
    curl -L -O {{ page.canonical_url }}/install-config.yaml
    ```

### Create ignition config & Upload it

```bash
openshift-install --dir=ocp create single-node-ignition-config
```

### Preare installation ISO

```bash

curl -L -O https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.14/4.14.0/rhcos-4.14.0-x86_64-live.x86_64.iso

alias coreos-installer='podman run --privileged --pull always --rm -v /dev:/dev -v /run/udev:/run/udev -v $PWD:/data -w /data quay.io/coreos/coreos-installer:release'

coreos-installer iso ignition embed -fi ocp/bootstrap-in-place-for-live-iso.ign rhcos-4.14.0-x86_64-live.x86_64.iso

virtctl image-upload pvc live-iso-sno  \
  --size 2Gi --storage-class ocs-storagecluster-ceph-rbd \
  --access-mode ReadWriteOnce \
  --image-path rhcos-4.14.0-x86_64-live.x86_64.iso

```

### Create VM

=== "vm.yaml"

    ```yaml
    --8<-- "content/cluster-installation/sno-on-ocpv/vm.yaml"
    ```

=== "oc apply"

    ```bash
    oc apply -f {{ page.canonical_url }}/vm.yaml
    ```
