---
title: Add Node to an existing cluster
linktitle: Add Node
description: Add Node to an existing cluster
tags: ['node', 'v4.17']
---

# Add Node to an existing cluster

Tested with OpenShift 4.17

Doc bug to improve RH Documentation: [OSDOCS-13020](https://issues.redhat.com/browse/OSDOCS-13020)

## Documentation

|Documetation|Notes|
|---|---|
|[Adding worker nodes to an on-premise cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/nodes/working-with-nodes#adding-node-iso)| <li>Supports only to add worker nodes</li>|
|Single Node documentation: [10.1.3. Adding worker nodes using the Assisted Installer API](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/nodes/worker-nodes-for-single-node-openshift-clusters#adding-worker-nodes-using-the-assisted-installer-api)|<li>*Ignored, because all my clusters are install without assisted isntaller (SaaS)*</li>|
|Single Node documentation: [10.1.4. Adding worker nodes to single-node OpenShift clusters manually](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/nodes/worker-nodes-for-single-node-openshift-clusters#sno-adding-worker-nodes-to-single-node-clusters-manually_add-workers)|<li>This works with all cluster types, doesn't matter which cluster size or installation type</li>|

## How to get RHEL CoreOS boot image

### Download generic Version from Red Hat resources

* Download from [console.redhat.com](https://console.redhat.com/openshift/install/platform-agnostic/user-provisioned) for latest version
* To download a specific one: <https://mirror.openshift.com/pub/openshift-v4/>
    * x86_64 => <https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/>
    * arm64 => <https://mirror.openshift.com/pub/openshift-v4/arm64/dependencies/rhcos/>
    * ...

### Download cluster specific one from Red Hat resources (recommended)

#### via oc

```bash
% oc -n openshift-machine-config-operator \
    get configmap/coreos-bootimages \
    -o jsonpath='{.data.stream}' \
    | jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location'
https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202410090854-0/x86_64/rhcos-417.94.202410090854-0-live.x86_64.iso

curl -L -O ...
```

#### via openshift-install

```bash
% openshift-install coreos print-stream-json \
  | jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location'
https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202410090854-0/x86_64/rhcos-417.94.202410090854-0-live.x86_64.iso

```

## Add node in my case

### Configure DHCP & DNS

DHCP

```config
host ocp1-cp-4 {
  hardware ethernet 0E:C0:EF:20:69:48;
  fixed-address 10.32.105.72;
  option host-name "ocp1-cp-4";
  option domain-name "stormshift.coe.muc.redhat.com";
}
```

DNS

```named
72.105.32.10.in-addr.arpa. 120  IN      PTR     ocp1-cp-4.stormshift.coe.muc.redhat.com.
ocp1-cp-4.stormshift.coe.muc.redhat.com. 60 IN A 10.32.105.72
```

### At target cluster (stormshift-ocp1)

Get RHCOS and Download it

```bash
% oc -n openshift-machine-config-operator     get configmap/coreos-bootimages     -o jsonpath='{.data.stream}'     | jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location'
https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202410090854-0/x86_64/rhcos-417.94.202410090854-0-live.x86_64.iso
curl -L -O https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202410090854-0/x86_64/rhcos-417.94.202410090854-0-live.x86_64.iso
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1187M  100 1187M    0     0  30.4M      0  0:00:39  0:00:39 --:--:-- 32.9M
```

Extract ignition and put it into a Webserver

|Role|Command|
|---|---|
|Control plane|`oc extract -n openshift-machine-api secret/master-user-data-managed --keys=userData --to=- > master.ign`|
|Worker|`oc extract -n openshift-machine-api secret/worker-user-data-managed --keys=userData --to=- > worker.ign`|

### At hosting cluster (ISAR)

#### Upload ISO

```bash
% oc project stormshift-ocp1-infra
Now using project "stormshift-ocp1-infra" on server "https://api.isar.coe.muc.redhat.com:6443".
% virtctl image-upload dv rhcos-417-94-202410090854-0-live --size=2Gi --storage-class coe-netapp-nas --image-path rhcos-417.94.202410090854-0-live.x86_64.iso
PVC stormshift-ocp1-infra/rhcos-417-94-202410090854-0-live not found
DataVolume stormshift-ocp1-infra/rhcos-417-94-202410090854-0-live created
Waiting for PVC rhcos-417-94-202410090854-0-live upload pod to be ready...
Pod now ready
Uploading data to https://cdi-uploadproxy-openshift-cnv.apps.isar.coe.muc.redhat.com

 1.16 GiB / 1.16 GiB [===================================================================================================================================] 100.00% 11s

Uploading data completed successfully, waiting for processing to complete, you can hit ctrl-c without interrupting the progress
Processing completed successfully
Uploading rhcos-417.94.202410090854-0-live.x86_64.iso completed successfully
```

#### Create VM

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: ocp1-cp-4
  namespace: stormshift-ocp1-infra
spec:
  dataVolumeTemplates:
    - metadata:
        creationTimestamp: null
        name: ocp1-cp-4-root
      spec:
        source:
          blank: {}
        storage:
          accessModes:
            - ReadWriteMany
          resources:
            requests:
              storage: 120Gi
          storageClassName: coe-netapp-san
  running: true
  template:
    metadata:
      creationTimestamp: null
    spec:
      architecture: amd64
      domain:
        cpu:
          cores: 8
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: root
            - bootOrder: 2
              cdrom:
                bus: sata
              name: cdrom
          interfaces:
            - bridge: {}
              macAddress: '0E:C0:EF:20:69:48'
              model: virtio
              name: coe
        machine:
          type: pc-q35-rhel9.4.0
        memory:
          guest: 16Gi
        resources:
          limits:
            memory: 16706Mi
          requests:
            memory: 16Gi
      networks:
        - multus:
            networkName: coe-bridge
          name: coe
      volumes:
        - name: cdrom
          persistentVolumeClaim:
            claimName: rhcos-417-94-202410090854-0-live
        - dataVolume:
            name: ocp1-cp-4-root
          name: root
```

* ToDo: Serial consol does not work

#### Install coreos via Console

```bash
curl -L -O http://10.32.96.31/stormshift-ocp1-master.ign
sudo coreos-installer install -i stormshift-ocp1-master.ign /dev/vda
sudo reboot
```
