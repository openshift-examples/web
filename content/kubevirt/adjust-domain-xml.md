---
title: Adjust domain.xml
linktitle: Adjust domain.xml
description: Adjust domain.xml via sidecar hook to add a WWN to a disk
tags: ['v4.20','sidecarhook','kubevirt', 'libvirt']
---
# Adjust domain.xml to add a WWN to a disk

This guide demonstrates how to use KubeVirt sidecar hooks to modify the libvirt domain.xml and add a World Wide Name (WWN) to a disk. This is particularly useful when testing IBM Fusion Access for SAN, which requires disks to have a specific WWN.

## Prerequisites

Documentation:

  - [Kubevirt Feature Gates](https://github.com/kubevirt/hyperconverged-cluster-operator/blob/main/docs/cluster-configuration.md#kubevirt-feature-gates)
  - [Hook Sidecar Container](https://kubevirt.io/user-guide/user_workloads/hook-sidecar/#configmap-with-python-script)

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.20.12|
|OpenShift Virt|v4.20.3|

## Problem Statement

To test IBM Fusion Access for SAN, the attached disk needs a WWN (World Wide Name). The libvirt domain.xml must be patched to include this WWN in the disk configuration.

## Current Disk Configuration

The current domain.xml contains a disk without a WWN:

```xml
<disk type='block' device='disk'>
  <driver name='qemu' type='raw' cache='none' error_policy='stop' io='native' discard='unmap'/>
  <source dev='/var/run/kubevirt/hotplug-disks/ibm-fusion-disk' index='1'/>
  <backingStore/>
  <target dev='sda' bus='scsi'/>
  <shareable/>
  <alias name='ua-ibm-fusion-disk'/>
  <address type='drive' controller='0' bus='0' target='0' unit='0'/>
</disk>
```

## Desired Disk Configuration

We need to add `<wwn>5000c500155a3456</wwn>` to the disk configuration. The target configuration should look like this:

```xml
<disk type='block' device='disk'>
  <driver name='qemu' type='raw' cache='none'/>
  <source dev='/dev/mapper/vg0-fusion' index='2'/>
  <backingStore/>
  <target dev='sdb' bus='scsi'/>
  <wwn>5000c500155a3456</wwn>
  <alias name='scsi0-0-0-1'/>
  <address type='drive' controller='0' bus='0' target='0' unit='1'/>
</disk>
```

## Step 1: Enable the Sidecar Feature Gate

The Sidecar feature gate must be enabled to use hook sidecar containers. For more information, see the [Kubevirt Feature Gates documentation](https://github.com/kubevirt/hyperconverged-cluster-operator/blob/main/docs/cluster-configuration.md#kubevirt-feature-gates).

Edit the HyperConverged operator annotation using `oc annotate`:

```shell
oc annotate hco -n openshift-cnv kubevirt-hyperconverged \
  kubevirt.kubevirt.io/jsonpatch='[ {"op": "add", "path": "/spec/configuration/developerConfiguration/featureGates/-","value": "Sidecar"} ]'
```

Alternatively, you can edit the HCO resource directly:

```shell
oc edit hco -n openshift-cnv kubevirt-hyperconverged
```

Add the following annotation:

```yaml
kubevirt.kubevirt.io/jsonpatch: '[ {"op": "add", "path": "/spec/configuration/developerConfiguration/featureGates/-","value": "Sidecar"} ]'
```

Verify that the feature gate is enabled:

```shell
oc get kubevirt -n openshift-cnv kubevirt-kubevirt-hyperconverged \
  -o jsonpath="{.spec.configuration.developerConfiguration.featureGates}" | jq
```

Expected output:

```json
[
  ...
  "Sidecar"
]
```

## Step 2: Create a Sidecar Hook to Inspect domain.xml

!!! tip

    The domain.xml format differs from the running configuration. During hook execution, there are no newlines in the domain.xml, making it a single-line XML string. This is important to consider when developing your modification script.

### Create a ConfigMap for the Hook Script

Create a ConfigMap in the same namespace as your VirtualMachine:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: add-wwn
data:
  add-wwn.sh: |
    #!/bin/sh
    tempFile=`mktemp --dry-run`
    echo $tempFile >> /tmp/onDefineDomain-tmpfile.log
    echo $4 > $tempFile
    cat $tempFile
```

Save this as `add-wwn-configmap.yaml` and apply it:

```shell
oc apply -f add-wwn-configmap.yaml
```

### Add Hook Sidecar Annotation to Your VirtualMachine

Add the `hooks.kubevirt.io/hookSidecars` annotation to your VirtualMachine specification:

```yaml
spec:
  template:
    metadata:
      annotations:
        hooks.kubevirt.io/hookSidecars: >
           [
             {
               "args": ["--version", "v1alpha2"],
               "configMap": {"name": "add-wwn", "key": "add-wwn.sh", "hookPath": "/usr/bin/onDefineDomain"}
             }
           ]
```

### Start the Virtual Machine and Inspect domain.xml

Start the virtual machine:

```shell
oc apply -f your-vm.yaml
```

Wait for the VM to start, then connect to the `hook-sidecar-0` container of the virt-launcher pod:

```shell
oc rsh -c hook-sidecar-0 virt-launcher-<vm-name>-<pod-id>
```

Inside the container, check the log file to see the temporary files created:

```shell
cat /tmp/onDefineDomain-tmpfile.log
```

Example output:

```
/tmp/tmp.Q7YIeHv8cV
/tmp/tmp.XvyR8QbHTi
```

Review the XML content in one of these temporary files:

```shell
cat /tmp/tmp.XvyR8QbHTi
```

This will show you the actual format of the domain.xml that the hook receives. Use this to develop your `sed` command for modifying the XML.

## Step 3: Update the ConfigMap with the sed Command

Now that you've inspected the domain.xml format, update the ConfigMap with the `sed` command to add the WWN. The script reads the domain.xml from `$4`, modifies it, and outputs the modified XML.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: add-wwn
data:
  add-wwn.sh: |
    #!/bin/sh
    tempFile=`mktemp --dry-run`
    echo $tempFile >> /tmp/onDefineDomain-tmpfile.log
    echo $4 > $tempFile
    sed -i "s|<shareable></shareable>|<shareable></shareable><wwn>5000c500155a3456</wwn>|" $tempFile
    cat $tempFile
```

**Explanation of the sed command:**

- `sed -i` - Edit the file in place
- `s|<shareable></shareable>|<shareable></shareable><wwn>5000c500155a3456</wwn>|` - Substitute the `<shareable></shareable>` tag with the same tag followed by the WWN element

Apply the updated ConfigMap:

```shell
oc apply -f add-wwn-configmap.yaml
```

Restart the VirtualMachine to apply the changes:

```shell
oc apply -f your-vm.yaml
virtctl restart <your-vm-name>
```

## Step 4: Verify the WWN

Once the VM has restarted, connect to it and verify that the disk has the WWN:

```shell
virtctl ssh <your-vm-name>  or ssh ...
```

Inside the VM, check the disk WWN:

```shell
lsblk -o +WWN
```

Expected output:

```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS                      WWN
loop0    7:0    0   5.8M  1 loop
sda      8:0    0   500G  0 disk                                  0x5000c500155a3456
vda    252:0    0   120G  0 disk
├─vda1 252:1    0     1M  0 part
├─vda2 252:2    0   127M  0 part
├─vda3 252:3    0   384M  0 part /boot
└─vda4 252:4    0 119.5G  0 part /var
                                 /sysroot/ostree/deploy/rhcos/var
                                 /etc
                                 /sysroot
```

The disk `sda` should now show the WWN `0x5000c500155a3456`.

## Troubleshooting

If the WWN is not appearing:

1. **Check the hook sidecar logs:**
   ```shell
   oc logs -c hook-sidecar-0 virt-launcher-<vm-name>-<pod-id>
   ```

2. **Verify the sed pattern matches your domain.xml:**
   - Connect to the hook-sidecar-0 container and check the actual XML format
   - Adjust the sed pattern if your XML structure differs

3. **Ensure the feature gate is enabled:**
   ```shell
   oc get kubevirt -n openshift-cnv kubevirt-kubevirt-hyperconverged \
     -o jsonpath="{.spec.configuration.developerConfiguration.featureGates}"
   ```

4. **Check that the ConfigMap is correctly referenced:**
   - Verify the ConfigMap name and namespace match your VM annotation
   - Ensure the key name matches (`add-wwn.sh`)

## Summary

You have successfully configured a KubeVirt sidecar hook to modify the libvirt domain.xml and add a WWN to a disk. This enables testing with IBM Fusion Access for SAN, which requires disks to have specific WWNs.
