# Container-native virtualization (CNV) / KubeVirt

## My lab environment 

build with [hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4/blob/master/docs/cnv.md)



## Put rhel into pvc

```bash
qemu-img convert -O raw rhel-server-7.6-x86_64-kvm.qcow2 /mnt/local-storage/pv001/disk.img
```

## Build RHEL VM image

```bash
oc create secret generic builder \
    --from-file=ssh-privatekey=~/.ssh/github_rsa \
    --type=kubernetes.io/ssh-auth

oc new-build git@gitlab.com:robertbohne/kubevirt-rhel-server-7.git --source-secret=builder --strategy=docker  --name=kubevirt-rhel7
```

## Resources and useful articles 

 - [Deploying Vms On Kubernetes Glusterfs Kubevirt](https://kubevirt.io/2018/Deploying-VMs-on-Kubernetes-GlusterFS-KubeVirt.html)
 - [Kubevirt Network Deep Dive](https://kubevirt.io/2018/KubeVirt-Network-Deep-Dive.html)
 - [Upstream containerized-data-importer](https://github.com/kubevirt/containerized-data-importer)

 - [Deploy openSUSE Leap15 VM in Kubernetes using KubeVirt](http://panosgeorgiadis.com/blog/2018/03/15/deploy-opensuse-leap15-vm-in-kubernetes-using-kubevirt/)
 - [Kubernetes and Virtualization: kubevirt will let you spawn virtual machine on your cluster!](https://medium.com/@alezzandro/kubernetes-and-virtualization-kubevirt-will-let-you-spawn-virtual-machine-on-your-cluster-e809914cc783)

 - Very old, please double check: [Know Issue: No IP address in VM after pod deletion #1646](https://github.com/kubevirt/kubevirt/issues/1646)
 - https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/
 - https://www.praqma.com/stories/debugging-kubernetes-networking/
