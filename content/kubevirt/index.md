---
title: OpenShift Virtualization (CNV/KubeVirt)
linktitle: "OpenShift Virtualization"
weight: 14000
description: TBD
tags: ['cnv', 'kubevirt','ocp-v']
ignore_macros: true
icon: material/new-box
---
# OpenShift Virtualization (CNV/KubeVirt)

## Containerized Data Importer (CDI) / DataVolume

```yaml
apiVersion: cdi.kubevirt.io/v1alpha1
kind: DataVolume
metadata:
  name: registry-image-datavolume
spec:
  pvc:
    accessModes:
    - ReadWriteMany
    resources:
      requests:
        storage: 5Gi
  source:
    registry:
      url: docker://image-registry.openshift-image-registry.svc:5000/cnv-demo/build-vm-image-container:latest
      certConfigMap: "tls-certs"
```

Source: [cdi-examples](https://github.com/kubevirt/containerized-data-importer/tree/master/manifests/example)

## OpenShift Virtualization & Container Storage

Recommended storage settings:

```bash
$ oc edit cm kubevirt-storage-class-defaults -n openshift-cnv

accessMode: ReadWriteMany
ocs-storagecluster-ceph-rbd.accessMode: ReadWriteMany
ocs-storagecluster-ceph-rbd.volumeMode: Block
ocs-storagecluster-cephfs.accessMode: ReadWriteMany
ocs-storagecluster-cephfs.volumeMode: Filesystem
volumeMode: Block
```

<!-- Internal Source: https://docs.google.com/document/d/1nIPev5h_pMCVz-G0K6xmtTmw7mv2L_J-cRKt9tVXtC4/edit#heading=h.szdpr1v81fo2 -->

## Build container image with OS disk

```bash
oc new-build --name cirros \
    --build-arg image_url=http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img \
    https://github.com/openshift-examples/cnv-container-disk-build.git
```

### Local IIS build in my lab

```bash
qemu-img convert -f raw -O qcow2 disk.img iis.qcow2

cat - > Dockerfile <<EOF
FROM scratch
LABEL maintainer="Robert Bohne <robert.bohne@redhat.com>"
ADD iis.qcow2 /disk/rhel.qcow2
EOF

oc create is iis -n cnv

export REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
export REGISTRY_TOKEN=$(oc whoami -t)
podman login -u $(oc whoami) -p $REGISTRY_TOKEN --tls-verify=false $HOST

podman build -t ${REGISTRY}/cnv/iis:latest .
podman push ${REGISTRY}/cnv/iis:latest

# Deploy template
oc apply -f https://raw.githubusercontent.com/openshift-examples/web/master/content/kubevirt/iis-template.yaml
```

## Resources and useful articles

- [Deploying Vms On Kubernetes Glusterfs Kubevirt](https://kubevirt.io/2018/Deploying-VMs-on-Kubernetes-GlusterFS-KubeVirt.html)
- [Kubevirt Network Deep Dive](https://kubevirt.io/2018/KubeVirt-Network-Deep-Dive.html)
- [Upstream containerized-data-importer](https://github.com/kubevirt/containerized-data-importer)
- [Deploy openSUSE Leap15 VM in Kubernetes using KubeVirt](http://panosgeorgiadis.com/blog/2018/03/15/deploy-opensuse-leap15-vm-in-kubernetes-using-kubevirt/)
- [Kubernetes and Virtualization: kubevirt will let you spawn virtual machine on your cluster!](https://medium.com/@alezzandro/kubernetes-and-virtualization-kubevirt-will-let-you-spawn-virtual-machine-on-your-cluster-e809914cc783)
- Very old, please double check: [Know Issue: No IP address in VM after pod deletion #1646](https://github.com/kubevirt/kubevirt/issues/1646)
- <https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/>
- <https://www.praqma.com/stories/debugging-kubernetes-networking/>
