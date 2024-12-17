---
title: CSI Driver NFS
linktitle: CSI Driver NFS
description: How to configure / setup CSI Driver NFS for OpenShift Virtualization
tags: ['nfs','csi','ocp-v','kubevirt']
---
# CSI Driver NFS

Based on

* <https://github.com/kubernetes-csi/csi-driver-nfs>
* <https://hackmd.io/@johnsimcall/BJeW2Y5mT>
* <https://hackmd.io/@kincl/csi-driver-nfs-with-console>

???+ warning "Snapshots are very slow!"

    Snapshots are coping data via tar .. $source $targert and that is incredible slow. OpenShift Virtualization runs in timeout, for example, during VM cloning via WebUI. Possible solution, create an VM snapshot with an extralong timeout:
    ```yaml
    apiVersion: snapshot.kubevirt.io/v1beta1
    kind: VirtualMachineSnapshot
    metadata:
      name: snapshot-with-60-minute-timeout
    spec:
      failureDeadline: 1h0m0s
      source:
        apiGroup: kubevirt.io
        kind: VirtualMachine
        name: rhel9-violet-halibut-12
    ```

## Deployment via helm

### Prepare namespace

```bash
export NAMESPACE=openshift-csi-driver-nfs
oc create namespace ${NAMESPACE}
oc adm policy add-scc-to-user -n  ${NAMESPACE}  privileged -z csi-nfs-controller-sa
oc adm policy add-scc-to-user -n  ${NAMESPACE}  privileged -z csi-nfs-node-sa
```

### Deploy

=== "helm"

    ```bash
    curl -L -O  {{ page.canonical_url }}values.yaml
    ```

=== "values.yaml"

    ```yaml
    --8<-- "content/cluster-configuration/storage/csi-driver-nfs/values.yaml"
    ```

```bash

# Do use openshift/csi-driver-nfs because csi resizer is missing
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

#  v0.0.0, because we want latest with csi-resizer

helm install csi-driver-nfs \
  csi-driver-nfs/csi-driver-nfs \
  --namespace openshift-csi-driver-nfs \
  --version v0.0.0 \
  --values values.yaml
```

### Create VolumeSnapshotClass

It's missing in the HelmChart: <https://github.com/kubernetes-csi/csi-driver-nfs/issues/825>

```bash
oc apply -f <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: nfs-csi-snapclass
driver: nfs.csi.k8s.io
deletionPolicy: Delete
EOF
```
