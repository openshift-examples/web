---
title: OpenShift Virtualization (CNV/KubeVirt)
linktitle: "Virtualization"
weight: 14000
description: Running VM's on OpenShift
tags: ['cnv', 'kubevirt','ocp-v']
icon: redhat/Technology_icon-Red_Hat-OpenShift_Virtualization-Standard-RGB
---

# OpenShift Virtualization (CNV/KubeVirt)

OpenShift Virtualization is a fully developed virtualization solution utilizing the type-1 KVM hypervisor from Red Hat Enterprise Linux with the powerful features and capabilities of OpenShift for managing hypervisor nodes, virtual machines, and their consumers.

## Usefull resources:

* [OpenShift Virtualization cookbook](https://redhatquickcourses.github.io/ocp-virt-cookbook/ocp-virt-cookbook/1/index.html)

## Example deployments

??? example "Tiny RHEL 9 VM with pod bridge network"

    === "tiny-rhel-pod-bridge.yaml"

        ```yaml
        --8<-- "content/kubevirt/example/tiny-rhel-pod-bridge.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}example/tiny-rhel-pod-bridge.yaml
        ```

??? example "Red Hat CoreOS with ignition & pod bridge network"

    === "rhcos-pod-bridge.yaml"

        ```yaml
        --8<-- "content/kubevirt/example/rhcos-pod-bridge.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}example/rhcos-pod-bridge.yaml
        ```

??? example "Boot from ISO"

    === "boot-from-iso.yaml"

        ```yaml
        --8<-- "content/kubevirt/example/boot-from-iso.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}example/boot-from-iso.yaml
        ```

??? example "Example Fedora with httpd cloud-init and network"

    === "localnet-fedora-vm.yaml"

        ```yaml
        --8<-- "content/kubevirt/networking/localnet-fedora-vm.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}networking/localnet-fedora-vm.yaml
        ```

## Useful Commands

### Configure a new number of CPUs for a VM

```bash
# Set the number of CPUs which you'd like to configure
export NEW_CPU=8

# This loop will configure the new number of CPUs
for VM in $(kubectl get vm -o jsonpath='{.items[*].metadata.name}'); do
    echo "Updating compute resources for VM: $VM"
    kubectl patch vm "$VM" --type='json' -p="[{'op': 'replace', 'path': '/spec/template/spec/domain/cpu/sockets', 'value': $NEW_CPU}]"
done
```

### Add the OCP Descheduler Annotation to True or False

```bash
# Set the Descheduler Annotation to True or False
export DESCHEDULER=True

# Add the OCP Descheduler Annotation to True or False
for VM in $(kubectl get vm -o jsonpath='{.items[*].metadata.name}'); do
    echo "Updating descheduler annotation: $VM"
    kubectl patch vm "$VM" --type='json' -p="[{'op': 'add', 'path': '/spec/template/metadata/annotations/descheduler.alpha.kubernetes.io~1evict', 'value': '$DESCHEDULER'}]"
done
```

### Create multiple VMs loop

```bash
for i in $(seq 1 15);  do oc process -n openshift rhel9-server-medium  -p NAME=vm${i} | oc apply -f - ; done;
```

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

export REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
export REGISTRY_TOKEN=$(oc whoami -t)
podman login -u $(oc whoami) -p $REGISTRY_TOKEN --tls-verify=false $HOST

podman build -t ${REGISTRY}/cnv/iis:latest .
podman push ${REGISTRY}/cnv/iis:latest

# Deploy template
oc apply -f https://raw.githubusercontent.com/openshift-examples/web/master/content/kubevirt/iis-template.yaml
```

## Resource Capacity Calculation

At a high level, the process is to determine the amount of virtualization resources needed (VM sizes, overhead, burst capacity, failover capacity), add that to the amount of resources needed for cluster services (logging, metrics, ODF/ACM/ACS if hosted in the same cluster, etc.) and customer workload (hosted control planes, other Pods deployed to the hardware, etc.), then find a balance of node size vs node count.

* *Source: [Red Hat Architecting OpenShift Virtualization](https://redhatquickcourses.github.io/architect-the-ocpvirt/Red%20Hat%20OpenShift%20Virtualization%20-%20Architecting%20OpenShift%20Virtualization/1/chapter5/section4.html)*

### CPU capacity calculation

```code
Formula

(((physical_cpu_cores - odf_requirements - control_plane_requirements) * node_count * overcommitment_ratio) * (1 -ha_reserve_percent)) * (1 - spare_capacity_percent)
```

* `physical_cpu_cores` = the number of physical cores available on the node.
* `odf_requirements` = the amount of resources reserved for ODF. A value of 32 cores was used for the example architectures.
* `control_plane_requirements` = the amount of CPU reserved for the control plane workload. A value of 4 cores was used for the example architectures.
* `node_count` = the number of nodes with this geometry. For small, all nodes were equal. For medium, the nodes are mixed-purpose, so the previous steps would need to be repeated for each node type, taking into account the appropriate node type.
* `overcommitment_ratio` = the amount of CPU overcommitment. A ratio of 4:1 was used for this document.
* `spare_capacity` = the amount of capacity reserved for spare/burst. A value of 10% was used for this document.
* `ha_reserve_percent` = the amount of capacity reserved for recovering workload lost in the event of node failure. For the small example, a value of 25% was used, allowing for one node to fail. For the medium example, a value of 20% was used, allowing for two nodes to fail.

### Memory capacity calculation

```code
Formula

((total_node_memory - odf_requirements - control_plane_requirements) * soft_eviction_threshold_percent * node_count) * (1 - ha_reserve_percent)
```

* `total_node_memory` = the total physical memory installed on the node.
* `odf_requirements` = the amount of memory assigned to ODF. A value of 72GiB was used for the example architectures in this document.
* `control_plane_requirements` = the amount of memory reserved for the control plane functions. A value of 24GiB was used for the example architectures.
* `soft_eviction_threshold_percent` = the value at which soft eviction is triggered to rebalance resource utilization on the node. Unless all nodes in the cluster exceed this value, it’s expected that the node will be below this utilization. A value of 90% was used for this document.
* `node_count` = the number of nodes with this geometry. For small, all nodes were equal. For medium, the nodes are mixed-purpose, so the previous steps would need to be repeated for each node type, taking into account the appropriate node type.
* `ha_reserve_percent` = the amount of capacity reserved for recovering workload lost in the event of node failure. For the small example, a value of 25% was used, allowing for one node to fail. For the medium example, a value of 20% was used, allowing for two nodes to fail.

### ODF capacity calculation

```code
Formula

(((disk_size * disk_count) * node_count) / replica_count) * (1 - utilization_percent)
```

* `disk_size` = the size of the disk(s) used. 4TB and 8TB disks were used in the example architectures.
* `disk_count` = the number of disks of disk_size in the node.
* `node_count` = the number of nodes with this geometry. For small, all nodes were equal. For medium, the nodes are mixed-purpose, so the previous steps would need to be repeated for each node type taking into account the appropriate node type.
* `replica_count` = the number of copies ODF stores of the data for protection/resiliency. A value of 3 was used for this document.
* `utilization_percent` = the desired threshold of capacity used in the ODF instance. A value of 65% was used for this document.

## Resources and useful articles

* [Deploying Vms On Kubernetes Glusterfs Kubevirt](https://kubevirt.io/2018/Deploying-VMs-on-Kubernetes-GlusterFS-KubeVirt.html)
* [Kubevirt Network Deep Dive](https://kubevirt.io/2018/KubeVirt-Network-Deep-Dive.html)
* [Upstream containerized-data-importer](https://github.com/kubevirt/containerized-data-importer)
* [Deploy openSUSE Leap15 VM in Kubernetes using KubeVirt](http://panosgeorgiadis.com/blog/2018/03/15/deploy-opensuse-leap15-vm-in-kubernetes-using-kubevirt/)
* [Kubernetes and Virtualization: kubevirt will let you spawn virtual machine on your cluster!](https://medium.com/@alezzandro/kubernetes-and-virtualization-kubevirt-will-let-you-spawn-virtual-machine-on-your-cluster-e809914cc783)
* Very old, please double check: [Know Issue: No IP address in VM after pod deletion #1646](https://github.com/kubevirt/kubevirt/issues/1646)
* <https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/>
* <https://www.praqma.com/stories/debugging-kubernetes-networking/>
