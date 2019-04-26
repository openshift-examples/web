# KubeVirt

My Information braindump:

http://panosgeorgiadis.com/blog/2018/03/15/deploy-opensuse-leap15-vm-in-kubernetes-using-kubevirt/

https://kubevirt.io/2018/Deploying-VMs-on-Kubernetes-GlusterFS-KubeVirt.html

https://kubevirt.io/2018/KubeVirt-Network-Deep-Dive.html


`qemu-img convert -O raw rhel-server-7.6-x86_64-kvm.qcow2 /mnt/local-storage/pv001/disk.img`


https://medium.com/@alezzandro/kubernetes-and-virtualization-kubevirt-will-let-you-spawn-virtual-machine-on-your-cluster-e809914cc783


https://github.com/kubevirt/containerized-data-importer







https://github.com/kubevirt/kubevirt/issues/1646

## Build RHEL VM image
```
oc create secret generic builder \
    --from-file=ssh-privatekey=~/.ssh/github_rsa \
    --type=kubernetes.io/ssh-auth

oc new-build git@gitlab.com:robertbohne/kubevirt-rhel-server-7.git --source-secret=builder --strategy=docker  --name=kubevirt-rhel7

```