---
title: KubeVirt CSI Driver
linktitle: kubevirt-csi-driver
description: Page for the KubeVirt CSI Driver Installation
tags: ['cnv', 'kubevirt', 'storage', 'ocp-v', 'csi']
---

# KubeVirt CSI Driver Installation

Official Repository:

- [KubeVirt CSI Driver](https://github.com/kubevirt/csi-driver)

???+ Important

    This CSI driver is made for a tenant cluster deployed on top of kubevirt VMs, and enables it to get its persistent data
    from the underlying, infrastructure cluster. To avoid confusion, this CSI driver is deployed on the tenant cluster, and does not require kubevirt installation at all.

## Controller deployment on the Infra-Cluster

- Create a `Secret` within the tenant-cluster project/namespace which contains the kube config of your tenant-cluster:

```code
export OCP42PATH='/Users/rguske/dev/openshift/openshift-on-openshift/rguske-ocp42/conf'
```

```code
oc create secret generic kvcluster-kubeconfig --from-file=value=$OCP42PATH/rguske-ocp42-kubeconfig
```

- Label the virtualized nodes (vms) accordingly so that the CSI Driver can pick up the labels in order to operate:

```code
for vm in $(oc get vms -o jsonpath='{.items[*].metadata.name}'); do echo ${vm} ; oc label vm/${vm}  csi-driver/cluster="rguske-ocp42" ; done
```

- Create a `ConfigMap` within the tanant-cluster project which the KubeVirt CSI Controller is using to identify the tenant-cluster name via the label as well as the tenant-cluster namespace:

```yaml
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: driver-config
data:
  infraClusterNamespace: rguske-ocp42
  infraClusterLabels: csi-driver/cluster=rguske-ocp42
EOF
```

- Within the tenant-cluster namespace, create the `ServiceAccount` as well as the controller:

=== "Download"

    ```bash
    curl -L -O {{ page.canonical_url }}/infra-cluster-serviceaccount.yaml
    ```

=== "infra-cluster-serviceaccount"

    ```yaml
    --8<-- "content/kubevirt/kubevirt-csi-driver/infra-cluster-serviceaccount.yaml"
    ```

```code
oc -n $NAMESPACE apply -f infra-cluster-serviceaccount.yaml
```

=== "Download"

    ```bash
    curl -L -O {{ page.canonical_url }}/controller-infra.yaml
    ```

=== "controller-infra"

    ```yaml
    --8<-- "content/kubevirt/kubevirt-csi-driver/controller-infra.yaml"
    ```

```code
oc -n $NAMESPACE apply -f controller-infra.yaml
```

## KubeVirt CSI Driver installation on the Tenant-Cluster

- Create a new project named e.g. `kubevirt-csi-driver`:

```code
oc new-project kubevirt-csi-driver
```

- Annotate the nodes with the annotations `csi.kubevirt.io/infra-vm-name=${node}` as well as `csi.kubevirt.io/infra-vm-namespace=$NAMESPACE`.

If the annotations doesn't exist, it'll fail with:

???+ warning

    F0218 08:58:00.631541 1 kubevirt-csi-driver.go:32] Failed to initialize driver: failed to configure node service: failed to resolve infra VM for node "rguske-ocp42-cp1": vmName or vmNamespace not found. Ensure the node has a valid providerID (kubevirt://) with annotation 'cluster.x-k8s.io/cluster-namespace', or set annotations 'csi.kubevirt.io/infra-vm-name' and 'csi.kubevirt.io/infra-vm-namespace' on the node. After setting the annotations, restart the kubevirt-csi-node pod on this node for the changes to take effect

Resolution on GitHub:

- [Add annotation-based fallback for infra VM node ID resolution](https://github.com/kubevirt/csi-driver/pull/170)

```code
for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}'); do echo ${node} ; oc annotate node/${node} csi.kubevirt.io/infra-vm-name=${node} --overwrite ; done
```

```code
for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}'); do echo ${node} ; oc annotate node/${node} csi.kubevirt.io/infra-vm-namespace=$NAMESPACE --overwrite ; done
```

- Install the complete CSI Driver:

=== "Download"

    ```bash
    curl -L -O {{ page.canonical_url }}/controller-tenant.yaml
    ```

=== "controller-tenant"

    ```yaml
    --8<-- "content/kubevirt/kubevirt-csi-driver/kubevirt-csi-driver-complete-tenant.yaml"
    ```

```code
oc apply -f controler-tenant.yaml
```

In case the above mentioned error message appears anyway, delete the pods:

```code
for pod in $(oc get pods -o jsonpath='{.items[*].metadata.name}'); do echo ${pod} ; oc delete pod ${pod} ; done
```

## Deploy Example Pod with PVC

- create the pvc

```yaml
oc create -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: 1g-kubevirt-disk
spec:
  storageClassName: $STORAGECLASS
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

- deploy the pod

```yaml
oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: testpodwithcsi
spec:
  containers:
  - image: docker.io/busybox:latest
    name: testpodwithcsi
    command: ["sh", "-c", "while true; do ls -la /opt; echo this file system was made availble using kubevirt-csi-driver; mktmp /opt/test-XXXXXX; sleep 1m; done"]
    imagePullPolicy: Always
    volumeMounts:
    - name: pv0002
      mountPath: "/opt"
  volumes:
  - name: pv0002
    persistentVolumeClaim:
      claimName: 1g-kubevirt-disk
EOF
```

## Errors along the way

### Cannot update `subresources`

???+ warning

    I0218 09:56:57.327140 1 controller.go:456] failed adding volume pvc-4b21e668-de61-4df7-b20d-fde66144d747 to VM rguske-ocp42-n3, retrying, err: virtualmachines.subresources.kubevirt.io "rguske-ocp42-n3" is forbidden: User "system:serviceaccount:rguske-ocp42:kubevirt-csi" cannot update resource "virtualmachines/addvolume" in API group "subresources.kubevirt.io" in the namespace "rguske-ocp42"

The `ServiceAccount` (infra-cluster-serviceaccount.yaml) needed to be adjusted with the appropriate priviledges (`resources` + `verbs`). After fixing it, the volume could be attached:

???+ info

    I0218 10:03:06.890836 1 server.go:121] /csi.v1.Controller/ControllerPublishVolume called with request: {"node_id":"rguske-ocp42/rguske-ocp42-n3","volume_capability":{"AccessType":{"Mount":{"fs_type":"ext4"}},"access_mode":{"mode":1}},"volume_context":{"bus":"scsi","serial":"c462f25e-3ba7-4f12-96ef-8013aee36760","storage.kubernetes.io/csiProvisionerIdentity":"1771401314268-2085-csi.kubevirt.io"},"volume_id":"pvc-c08d2bd3-c43c-4157-82ab-3fa81464bbd0"}
    I0218 10:03:06.901504 1 controller.go:403] Attaching DataVolume pvc-c08d2bd3-c43c-4157-82ab-3fa81464bbd0 to Node ID rguske-ocp42/rguske-ocp42-n3
    I0218 10:03:06.907020 1 controller.go:430] Start attaching DataVolume pvc-c08d2bd3-c43c-4157-82ab-3fa81464bbd0 to VM rguske-ocp42-n3. Volume name: pvc-c08d2bd3-c43c-4157-82ab-3fa81464bbd0. Serial: c462f25e-3ba7-4f12-96ef-8013aee36760. Bus: scsi

![attached-dv](assets/Screenshot%202026-02-18%20at%2011.06.56.png)

### Pod can't mount PVC

???+ warning

    AttachVolume.Attach failed for volume "pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9" : timed out waiting for external-attacher of csi.kubevirt.io CSI driver to attach volume pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9

furthermore:

???+ warning

    MountVolume.MountDevice failed for volume "pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9" : rpc error: code = Unknown desc = couldn't find device by serial id

Existing KC articles:

- [Workload on HostedControlPlane with Kubevirt provider fail to start after worker Virtual Machine reboot, "MountDevice failed for volume: couldn't find device by serial"](https://access.redhat.com/solutions/7095010)

### On the Tenant CLuster

```code
oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-c08d2bd3-c43c-4157-82ab-3fa81464bbd0   1Gi        RWO            Delete           Bound    default/1g-kubevirt-disk        kubevirt       <unset>                          89m
pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9   2Gi        RWO            Delete           Bound    rguske-tests/1g-kubevirt-disk   kubevirt       <unset>                          12m
```

```code
oc get pvc
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
1g-kubevirt-disk   Bound    pvc-c08d2bd3-c43c-4157-82ab-3fa81464bbd0   1Gi        RWO            kubevirt       <unset>                 43h
```

```code
PVC_UID=eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9
```

```code
PV=$(oc get pv -o jsonpath='{range .items[?(@.spec.claimRef.uid=="'"$PVC_UID"'")]}{.metadata.name}{"\n"}{end}')
```

```code
oc get pv "$PV" -o jsonpath='{.spec.csi.volumeHandle}{"\n"}'
pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9
```

```code
NODE=rguske-ocp42-n3

oc debug node/$NODE -- chroot /host bash -lc '
  ls -l /dev/disk/by-id | sed -e "s#^#BY-ID: #";
  echo;
  lsblk -o NAME,KNAME,TYPE,SIZE,MODEL,SERIAL'
Starting pod/rguske-ocp42-n3-debug-w9xks ...
To use host binaries, run `chroot /host`. Instead, if you need to access host namespaces, run `nsenter -a -t 1`.
ls: cannot access '/dev/disk/by-id': No such file or directory

NAME   KNAME TYPE   SIZE MODEL SERIAL
loop0  loop0 loop   5.8M
vda    vda   disk   120G
├─vda1 vda1  part     1M
├─vda2 vda2  part   127M
├─vda3 vda3  part   384M
└─vda4 vda4  part 119.5G

Removing debug pod ...
```

```code
oc debug node/$NODE -- chroot /host bash -lc '
  echo "== SCSI hosts ==";
  ls -l /sys/class/scsi_host 2>/dev/null || echo "NO_SCSI_HOST";
  echo;
  echo "== PCI storage controllers ==";
  lspci -nn | egrep -i "scsi|storage|virtio" || true;
  echo;
  echo "== Kernel messages (storage) ==";
  dmesg | egrep -i "scsi|virtio|block|sd[a-z]" | tail -n 50 || true;
'
Starting pod/rguske-ocp42-n3-debug-8qwmm ...
To use host binaries, run `chroot /host`. Instead, if you need to access host namespaces, run `nsenter -a -t 1`.
== SCSI hosts ==
total 0
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host0 -> ../../devices/pci0000:00/0000:00:03.2/0000:0b:00.0/virtio1/host0/scsi_host/host0
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host1 -> ../../devices/pci0000:00/0000:00:1f.2/ata1/host1/scsi_host/host1
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host2 -> ../../devices/pci0000:00/0000:00:1f.2/ata2/host2/scsi_host/host2
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host3 -> ../../devices/pci0000:00/0000:00:1f.2/ata3/host3/scsi_host/host3
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host4 -> ../../devices/pci0000:00/0000:00:1f.2/ata4/host4/scsi_host/host4
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host5 -> ../../devices/pci0000:00/0000:00:1f.2/ata5/host5/scsi_host/host5
lrwxrwxrwx. 1 root root 0 Feb 17 08:47 host6 -> ../../devices/pci0000:00/0000:00:1f.2/ata6/host6/scsi_host/host6

== PCI storage controllers ==
01:00.0 Ethernet controller [0200]: Red Hat, Inc. Virtio 1.0 network device [1af4:1041] (rev 01)
0b:00.0 SCSI storage controller [0100]: Red Hat, Inc. Virtio 1.0 SCSI [1af4:1048] (rev 01)
0c:00.0 Communication controller [0780]: Red Hat, Inc. Virtio 1.0 console [1af4:1043] (rev 01)
0d:00.0 SCSI storage controller [0100]: Red Hat, Inc. Virtio 1.0 block device [1af4:1042] (rev 01)
0e:00.0 Unclassified device [00ff]: Red Hat, Inc. Virtio 1.0 memory balloon [1af4:1045] (rev 01)
0f:00.0 Unclassified device [00ff]: Red Hat, Inc. Virtio 1.0 RNG [1af4:1044] (rev 01)

== Kernel messages (storage) ==
[    0.020071] ACPI: RSDP 0x00000000000F54A0 000014 (v00 BOCHS )
[    0.020078] ACPI: RSDT 0x000000007FFE2E4F 000038 (v01 BOCHS  BXPC     00000001 BXPC 00000001)
[    0.020092] ACPI: DSDT 0x000000007FFDF5C0 0033B7 (v01 BOCHS  BXPC     00000001 BXPC 00000001)
[    0.020118] ACPI: Reserving DSDT table memory at [mem 0x7ffdf5c0-0x7ffe2976]
[    0.333351] x86/mm: Memory block size: 128MB
[    0.379458] ACPI: Enabled 2 GPEs in block 00 to 3F
[    0.706086] SCSI subsystem initialized
[    1.134417] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 246)
[    2.305506] systemd[1]: Listening on Open-iSCSI iscsid Socket.
[    2.306895] systemd[1]: Listening on Open-iSCSI iscsiuio Socket.
[    2.315245] systemd[1]: Check That Initrd Matches Kernel was skipped because of an unmet condition check (ConditionPathIsDirectory=!/usr/lib/modules/5.14.0-570.83.1.el9_6.x86_64).
[    2.440742] Loading iSCSI transport class v2.0-870.
[    2.454825] iscsi: registered transport (iser)
[    2.644810] iscsi: registered transport (tcp)
[    2.682132] iscsi: registered transport (qla4xxx)
[    2.682698] QLogic iSCSI HBA Driver
[    2.694396] libcxgbi:libcxgbi_init_module: Chelsio iSCSI driver library libcxgbi v0.9.1-ko (Apr. 2015)
[    2.762615] Chelsio T4-T6 iSCSI Driver cxgb4i v0.9.5-ko (Apr. 2015)
[    2.763228] iscsi: registered transport (cxgb4i)
[    2.785001] QLogic NetXtreme II iSCSI Driver bnx2i v2.7.10.1 (Jul 16, 2014)
[    2.785574] iscsi: registered transport (bnx2i)
[    2.799647] iscsi: registered transport (be2iscsi)
[    2.800127] In beiscsi_module_init, tt=00000000e3e2ce31
[    3.463881] virtio_blk virtio3: 1/0/0 default/read/poll queues
[    3.466980] virtio_blk virtio3: [vda] 251658240 512-byte logical blocks (129 GB/120 GiB)
[    3.525550] scsi host0: Virtio SCSI HBA
[    3.567813] virtio_net virtio0 enp1s0: renamed from eth0
[    3.573555] scsi host1: ahci
[    3.573805] scsi host2: ahci
[    3.574676] scsi host3: ahci
[    3.574949] scsi host4: ahci
[    3.575552] scsi host5: ahci
[    3.575970] scsi host6: ahci
[    4.985041] systemd[1]: iscsid.socket: Deactivated successfully.
[    4.985652] systemd[1]: Closed Open-iSCSI iscsid Socket.
[    4.998835] systemd[1]: iscsiuio.socket: Deactivated successfully.
[    4.999420] systemd[1]: Closed Open-iSCSI iscsiuio Socket.
[   10.150956] virtio_net virtio0 enp1s0: entered promiscuous mode
[   10.487925] virtio_net virtio0 enp1s0: left promiscuous mode
[   15.282762] virtio_net virtio0 enp1s0: entered promiscuous mode
[   15.835818] virtio_net virtio0 enp1s0: left promiscuous mode
[   15.840535] virtio_net virtio0 enp1s0: entered promiscuous mode

Removing debug pod ...
```

### On the Infra-Cluster

Check the controller logs `oc logs deploy/kubevirt-csi-controller -f`

```code
I0218 10:14:27.668076       1 controller.go:241] creating new DataVolume rguske-ocp42/pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9
I0218 10:14:27.686963       1 server.go:126] /csi.v1.Controller/CreateVolume returned with response: {"volume":{"capacity_bytes":2147483648,"volume_context":{"bus":"scsi","serial":"5bcccca9-2b42-4de8-8b62-a1e72ab38b58"},"volume_id":"pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9"}}
I0218 10:15:29.630238       1 server.go:121] /csi.v1.Controller/ControllerPublishVolume called with request: {"node_id":"rguske-ocp42/rguske-ocp42-n3","volume_capability":{"AccessType":{"Mount":{"fs_type":"ext4"}},"access_mode":{"mode":1}},"volume_context":{"bus":"scsi","serial":"5bcccca9-2b42-4de8-8b62-a1e72ab38b58","storage.kubernetes.io/csiProvisionerIdentity":"1771401314268-2085-csi.kubevirt.io"},"volume_id":"pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9"}
I0218 10:15:29.639135       1 controller.go:403] Attaching DataVolume pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9 to Node ID rguske-ocp42/rguske-ocp42-n3
I0218 10:15:29.644847       1 controller.go:430] Start attaching DataVolume pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9 to VM rguske-ocp42-n3. Volume name: pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9. Serial: 5bcccca9-2b42-4de8-8b62-a1e72ab38b58. Bus: scsi
E0218 10:17:29.674335       1 controller.go:468] volume pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9 failed to be ready in time (2m) in VM rguske-ocp42-n3, client rate limiter Wait returned an error: context deadline exceeded
E0218 10:17:29.674361       1 server.go:124] /csi.v1.Controller/ControllerPublishVolume returned with error: client rate limiter Wait returned an error: context deadline exceeded
```

Checking the scsi controller which is used when hot-plugging a PVC:

```yaml
oc -n rguske-ocp42 get vmi rguske-ocp42-n3 -o yaml | sed -n '1,140p'
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:

[...]

spec:
  architecture: amd64
  domain:
    cpu:
      cores: 1
      maxSockets: 24
      model: IvyBridge-v2
      sockets: 6
      threads: 1
    devices:
      disks:
      - bootOrder: 1
        disk:
          bus: virtio
        name: rootdisk
      - disk:
          bus: scsi
        name: pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9
        serial: 5bcccca9-2b42-4de8-8b62-a1e72ab38b58
      interfaces:
      - bridge: {}
        macAddress: 02:06:b6:02:4d:b6
        model: virtio
        name: coe-bridge
        state: up
      rng: {}

[...]

  volumes:
  - dataVolume:
      name: rguske-ocp42-n3-rootdisk-mig-62fcqw-mig-ctpb
    name: rootdisk
  - dataVolume:
      hotpluggable: true
      name: pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9
    name: pvc-eb7ff8dc-ed38-473f-a5ea-4baa4686b0b9
[...]
```

The hotplug disk is attached as `disk.bus: scsi` and the serial is set correctly (5bcccca9-…).

But inside the guest you never see a second block device (only vda), so the CSI node can’t possibly find /dev/disk/by-id/*<serial>*.

```code
NODE=rguske-ocp42-n3

oc debug node/$NODE -- chroot /host bash -lc '
  ls -l /dev/disk/by-id | sed -e "s#^#BY-ID: #";
  echo;
  lsblk -o NAME,KNAME,TYPE,SIZE,MODEL,SERIAL'
Starting pod/rguske-ocp42-n3-debug-w9xks ...
To use host binaries, run `chroot /host`. Instead, if you need to access host namespaces, run `nsenter -a -t 1`.
ls: cannot access '/dev/disk/by-id': No such file or directory

NAME   KNAME TYPE   SIZE MODEL SERIAL
loop0  loop0 loop   5.8M
vda    vda   disk   120G
├─vda1 vda1  part     1M
├─vda2 vda2  part   127M
├─vda3 vda3  part   384M
└─vda4 vda4  part 119.5G

Removing debug pod ...
```

## StorageClass fixed the Issue

I changed the StorageClass from `odf-replica-two-block` to `ocs-storagecluster-ceph-rbd-virtualization`. The difference between both sc's were the `volumeBindingMode:`. The working one has `volumeBindingMode: Immediate`.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: csi.kubevirt.io
parameters:
  bus: scsi
  infraStorageClassName: ocs-storagecluster-ceph-rbd-virtualization
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

Deployed the Pod with the PVC accordingly and:

```code
I0218 11:07:36.353840       1 controller.go:163] Create Volume Request: name:"pvc-846e7c17-7655-41e1-9668-af5241c1aaad"  capacity_range:{required_bytes:1073741824}  volume_capabilities:{mount:{fs_type:"ext4"}  access_mode:{mode:SINGLE_NODE_WRITER}}  parameters:{key:"bus"  value:"scsi"}  parameters:{key:"infraStorageClassName"  value:"ocs-storagecluster-ceph-rbd-virtualization"}
I0218 11:07:36.358648       1 controller.go:241] creating new DataVolume rguske-ocp42/pvc-846e7c17-7655-41e1-9668-af5241c1aaad
I0218 11:07:36.378859       1 server.go:126] /csi.v1.Controller/CreateVolume returned with response: {"volume":{"capacity_bytes":1073741824,"volume_context":{"bus":"scsi","serial":"0778c423-7c23-49ec-98a5-957183a31639"},"volume_id":"pvc-846e7c17-7655-41e1-9668-af5241c1aaad"}}
I0218 11:08:27.138455       1 server.go:121] /csi.v1.Controller/ControllerPublishVolume called with request: {"node_id":"rguske-ocp42/rguske-ocp42-n3","volume_capability":{"AccessType":{"Mount":{"fs_type":"ext4"}},"access_mode":{"mode":1}},"volume_context":{"bus":"scsi","serial":"0778c423-7c23-49ec-98a5-957183a31639","storage.kubernetes.io/csiProvisionerIdentity":"1771401314268-2085-csi.kubevirt.io"},"volume_id":"pvc-846e7c17-7655-41e1-9668-af5241c1aaad"}
I0218 11:08:27.149209       1 controller.go:403] Attaching DataVolume pvc-846e7c17-7655-41e1-9668-af5241c1aaad to Node ID rguske-ocp42/rguske-ocp42-n3
I0218 11:08:27.154702       1 controller.go:430] Start attaching DataVolume pvc-846e7c17-7655-41e1-9668-af5241c1aaad to VM rguske-ocp42-n3. Volume name: pvc-846e7c17-7655-41e1-9668-af5241c1aaad. Serial: 0778c423-7c23-49ec-98a5-957183a31639. Bus: scsi
I0218 11:08:36.187861       1 controller.go:472] Successfully attached volume pvc-846e7c17-7655-41e1-9668-af5241c1aaad to VM rguske-ocp42-n3
I0218 11:08:36.187881       1 server.go:126] /csi.v1.Controller/ControllerPublishVolume returned with response: {}
```

## StorageProfile Adjustments

Make sure that the `AccessMode` is configured for the `StorageProfile` otherwise, you'll get an error message for the respective `DataVolume` that the `AccessMode` is missing/not specified.

```yaml
oc get storageprofiles.cdi.kubevirt.io kubevirt-ceph-rbd-virt -oyaml

apiVersion: cdi.kubevirt.io/v1beta1
kind: StorageProfile
metadata:
  name: kubevirt-ceph-rbd-virt
spec:
  claimPropertySets:
  - accessModes:
    - ReadWriteMany
    volumeMode: Block
```

## VirtLauncher Pod can't be scheduled

```code
0/6 nodes are available: 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {node-role.kubernetes.io/master: }. preemption: 0/6 nodes are available: 6 Preemption is not helpful for scheduling.
```

Check KubeVirt specific labels:

```code
oc get nodes rguske-ocp42-n1 rguske-ocp42-n2 rguske-ocp42-n3 --show-labels | egrep -o 'kubevirt\.io/schedulable=[^, ]+' || true

kubevirt.io/schedulable=true
kubevirt.io/schedulable=true
kubevirt.io/schedulable=true
```

```code
oc describe pvc rhel-9-ivory-whippet-47-volume

Events:
  Type     Reason                       Age                   From                                                                                           Message
  ----     ------                       ----                  ----                                                                                           -------
  Warning  UnrecognizedDataSourceKind   3m5s (x5 over 3m5s)   volume-data-source-validator                                                                   The datasource for this PVC does not match any registered VolumePopulator
  Normal   Provisioning                 3m5s (x4 over 3m5s)   csi.kubevirt.io_kubevirt-csi-controller-6d7fc974b4-xr4hq_b59c3cb9-66f2-47c1-8f30-2aa3a4e7c7d6  External provisioner is provisioning volume for claim "rguske-tests/rhel-9-ivory-whippet-47-volume"
  Normal   Provisioning                 3m5s (x4 over 3m5s)   external-provisioner                                                                           Assuming an external populator will provision the volume
  Normal   VolumeSnapshotClassSelected  3m4s (x11 over 3m5s)  clone-populator                                                                                VolumeSnapshotClass selected according to StorageProfile kubevirt-csi-snapclass
  Normal   ExternalProvisioning         3s (x18 over 3m5s)    persistentvolume-controller                                                                    Waiting for a volume to be created either by the external provisioner 'csi.kubevirt.io' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
```

### VolumeSnapshotContent Error

???+ warning

    Failed to check and update snapshot content: failed to add VolumeSnapshotBeingCreated annotation on the content snapcontent-4860fa21-076c-49b1-9cbf-5b66407fbe72: "snapshot controller failed to update snapcontent-4860fa21-076c-49b1-9cbf-5b66407fbe72 on API server: VolumeSnapshotContent.snapshot.storage.k8s.io \"snapcontent-4860fa21-076c-49b1-9cbf-5b66407fbe72\" is invalid: spec: Invalid value: \"object\": sourceVolumeMode is required once set"'

Check whether your CRDs enforce `sourceVolumeMode`:

```code
oc get crd volumesnapshotcontents.snapshot.storage.k8s.io -o yaml | egrep -n 'sourceVolumeMode|required once set'

145:                - message: volumeHandle is required once set
147:                - message: snapshotHandle is required once set
153:              sourceVolumeMode:
162:                - message: sourceVolumeMode is immutable
235:            - message: sourceVolumeMode is required once set
236:              rule: '!has(oldSelf.sourceVolumeMode) || has(self.sourceVolumeMode)'
```

In Kubernetes snapshots, there are two relevant components:

- snapshot-controller (cluster-wide) - OpenShift provides this

```code
oc -n openshift-cluster-storage-operator get deploy
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
cluster-storage-operator           1/1     1            1           3d1h
csi-snapshot-controller            2/2     2            2           3d1h
csi-snapshot-controller-operator   1/1     1            1           3d1h
volume-data-source-validator       1/1     1            1           3d1h
```

- csi-snapshotter sidecar – runs inside the CSI driver controller deployment in my case, the KubeVirt CSI driver I've installed in the tenant cluster. It watches VolumeSnapshot/VolumeSnapshotContent and performs the CSI snapshot RPCs, and updates VolumeSnapshotContent objects.

### Solution

I've deleted the associated CRDs:

```code
oc delete crd \
  volumesnapshots.snapshot.storage.k8s.io \
  volumesnapshotcontents.snapshot.storage.k8s.io \
  volumesnapshotclasses.snapshot.storage.k8s.io
customresourcedefinition.apiextensions.k8s.io "volumesnapshots.snapshot.storage.k8s.io" deleted
customresourcedefinition.apiextensions.k8s.io "volumesnapshotcontents.snapshot.storage.k8s.io" deleted
customresourcedefinition.apiextensions.k8s.io "volumesnapshotclasses.snapshot.storage.k8s.io" deleted
```
