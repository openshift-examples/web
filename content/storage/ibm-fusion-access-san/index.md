---
title: IBM Fusion Access SAN
linktitle: IBM Fusion Access SAN
description: IBM Fusion Access SAN
tags: ['storage','v4.20']
icon: ibm/logo
---
# IBM Fusion Access SAN

Official documentation: [Deploying IBM Fusion Access for SAN](https://www.ibm.com/docs/en/fusion-software/2.12.0?topic=san-deploying-fusion-access)

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.20.4|
|OpenShift Virt|v4.20.x|
|IBM Fusion Access for SAN|2.12.0|

## Prerequisites

* IBM account (IBMid). Create an account via <https://www.ibm.com/account/reg/us-en/signup?formid=urx-19776>
* Access to IBM Storage Fusion, for example via the [60-day trial](https://www.ibm.com/docs/en/storage-fusion/storage/2.6.0?topic=overview-storage-fusion-trial-version)
* IBM Entitlement key to allow your OpenShift cluster to pull images from IBM Registry: <https://myibm.ibm.com/products-services/containerlibrary>
* OpenShift cluster with at least three worker nodes, each with ~32 GB memory
    * All nodes (at least 3) need a shared disk (via iSCSI, FC, or shared disks in a KVM lab).
    * RHEL 10 capable nodes (suppport of x86-64-v3). If not some Pods crash with `Fatal glibc error: CPU does not support x86-64-v3`
* Access to a container registry for the GPFS kernel modules
    * Internal registry (requires registry storage)
    * External registry, for example quay.io with a private repository
* If Secure Boot is enabled: Create and roll out your signing key. (IBM Fusion Access for SAN builds and loads its own kernel module via [KMM](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/specialized_hardware_and_driver_enablement/kernel-module-management-operator))

## Let's start the installation

### If Secure Boot is enabled: Create and roll out your signing key

Documentation:

* [4.11. Adding the keys for secureboot](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/specialized_hardware_and_driver_enablement/kernel-module-management-operator#kmm-adding-the-keys-for-secureboot_kernel-module-management-operator)
* [21.6. Generating a public and private key pair](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/signing-a-kernel-and-modules-for-secure-boot_managing-monitoring-and-updating-the-kernel?extIdCarryOver=true&sc_cid=7013a000002w14NAAQ#generating-a-public-and-private-key-pair_signing-a-kernel-and-modules-for-secure-boot)

#### Create an key pair

Here are the commands executed on RHEL 10.

* Create public and private key

    ```shell
    efikeygen --dbdir /etc/pki/pesign \
      --self-sign \
      --module \
      --common-name 'CN=Organization signing key' \
      --nickname 'Custom Secure Boot key'
    ```

* Export public key to `sb_cert.cer`

    ```shell
    certutil -d /etc/pki/pesign \
      -n 'Custom Secure Boot key' \
      -Lr \
      > sb_cert.cer
    ```

* Export private key to `sb_cert.p12`

    ```shell
    pk12util -o sb_cert.p12 \
      -n 'Custom Secure Boot key' \
      -d /etc/pki/pesign
    ```

* Export the unencrypted private key:

    ```shell
    openssl pkcs12 \
      -in sb_cert.p12 \
      -out sb_cert.priv \
      -nocerts \
      -noenc
    ```

#### Roll out the public key

This may differ in your environment.

In my virtual lab environment running on KVM/libvirt with [hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4/):

* Copy the public key to the VM via SSH

    ```shell
    scp sb_cert.cer core@compute-X:~/
    ```

* Check & import the key via `mokutil` on the node:

    ```shell
    % sudo mokutil --list-enrolled | grep 'Subject:'
            Subject: O=Red Hat, Inc., CN=Red Hat Secure Boot CA 5/emailAddress=secalert@redhat.com
            Subject: CN=Red Hat Secure Boot CA 8/emailAddress=secalert@redhat.com

    # Set a simple password; it will be needed later in the UEFI shell.
    % sudo mokutil --import sb_cert.cer
    input password:
    input password again:
    ```

* Reboot the node, enter the MOK manager, and enroll the key

    [![](mok.png)](https://www.youtube.com/watch?v=fgtSxcTE7_o)

* Check the key via `mokutil` at the Node:

    ```shell
    % mokutil --list-enrolled | grep 'Subject:'
            Subject: O=Red Hat, Inc., CN=Red Hat Secure Boot CA 5/emailAddress=secalert@redhat.com
            Subject: CN=Red Hat Secure Boot CA 8/emailAddress=secalert@redhat.com
            Subject: CN=Organization signing key
    ```

## In case you want to run this in a disconnected/air-gapped environment

In a disconnected environment, you need to mirror the required container images to your local registry. This includes the IBM Fusion Access for SAN operator, the Kernel Module Management (KMM) operator, and the specific IBM Spectrum Scale images.

### Mirroring images via oc-mirror v2

Use [oc-mirror v2](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/disconnected_environments/about-installing-oc-mirror-v2) to mirror the images.

Example `imageset-configuration.yaml`:

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  platform:
    channels:
    - name: stable-4.20
      type: ocp
      minVersion: 4.20.4
    graph: true
  operators:
  - catalog: registry.redhat.io/redhat/certified-operator-index:v4.20
    packages:
      - name: openshift-fusion-access-operator
        channels:
          - name: stable-v1
            minVersion: 1.1.0-1
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.20
    packages:
    - name: kernel-module-management
      channels:
      - name: stable
        minVersion: '2.5.1'
  additionalImages:
    # Required for KMM & GPFS Build
    - name: registry.redhat.io/ubi9/ubi-minimal:latest
    # IBM Fusion Access for SAN images
    # Gathered from https://github.com/openshift-storage-scale/openshift-fusion-access-operator/tree/main/files
    - name: cp.icr.io/cp/gpfs/erasure-code/ibm-spectrum-scale-daemon@sha256:fa389056d2489eae1da98be08fc553806ad3817b2875329e51674134cc425f8a
    - name: cp.icr.io/cp/gpfs/data-management/ibm-spectrum-scale-daemon@sha256:07ae36c1a8539aee091cff19261aa14a9d220e6994132a14d2d8c537d596f9ec
    - name: cp.icr.io/cp/gpfs/data-access/ibm-spectrum-scale-daemon@sha256:539f31bb5691b636f2a7236b3fa617ba38e7ed35b7a3b1e71de5e84fd16f4d26
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-core-init@sha256:51dc287dd9ae2f8dcb60c1678fe8b535bb72e29faad24108d55b7cfe62362777
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-gui@sha256:57ea64cdd612aef7a5f01dfbd41677092c0f565c35ef7e5394e50799dc3796e1
    - name: cp.icr.io/cp/gpfs/postgres@sha256:0bcc5bbbb2aa9c9b4c6505845918c7eb55d783cf5c1f434fac33012579fb149d
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-logs@sha256:3b48c09f3641c10c63378a2dda806673fe7ea9c43774112f67bd8f8bd4e53b93
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-pmcollector@sha256:ad1e25622e325f4aa3000e680bd747bea50a22b65a8472cbc20640b730c86fa4
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-monitor@sha256:c77c0b3c6f7373136b581dabf2f57899c8a742d1cb4501d739af95cba151a438
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-grafana-bridge@sha256:b3b91b2f6729ecb3544b6b9fc539e2abbe425dfe497ce88deba7deed55305c7c
    - name: cp.icr.io/cp/gpfs/ibm-spectrum-scale-coredns@sha256:6a317b23fee629c0b07eb95d34ab7593bb38d41bffc5d1cd4cb2870539c66cd4
    - name: icr.io/cpopen/ibm-spectrum-scale-must-gather@sha256:798559d9dfabfbd2cca1224fde8f6b0cbc4c96fd9d01212ea07bfdb4e40c8818
    - name: cp.icr.io/cp/gpfs/csi/csi-snapshotter@sha256:5f4bb469fec51147ce157329dab598c758da1b018bad6dad26f0ff469326d769
    - name: cp.icr.io/cp/gpfs/csi/csi-attacher@sha256:69888dba58159c8bc0d7c092b9fb97900c9ca8710d088b0b7ea7bd9052df86f6
    - name: cp.icr.io/cp/gpfs/csi/csi-provisioner@sha256:d5e46da8aff7d73d6f00c761dae94472bcda6e78f4f17b3802dc89d44de0111b
    - name: cp.icr.io/cp/gpfs/csi/livenessprobe@sha256:2c5f9dc4ea5ac5509d93c664ae7982d4ecdec40ca7b0638c24e5b16243b8360f
    - name: cp.icr.io/cp/gpfs/csi/csi-node-driver-registrar@sha256:d7138bcc3aa5f267403d45ad4292c95397e421ea17a0035888850f424c7de25d
    - name: cp.icr.io/cp/gpfs/csi/csi-resizer@sha256:8ddd178ba5d08973f1607f9b84619b58320948de494b31c9d7cd5375b316d6d4
    - name: cp.icr.io/cp/gpfs/csi/ibm-spectrum-scale-csi-driver@sha256:711f9fc45969639da712b0823139549cdbedead0be9453c4243e1a873e7737f1
    - name: icr.io/cpopen/ibm-spectrum-scale-csi-operator@sha256:2c2e9c630a45da80321bbf1b63e9152e0cb7cc14390ee3879fd736e0a6974464
    - name: icr.io/cpopen/ibm-spectrum-scale-operator@sha256:6dcb6ca5430deea044cfd029df4a9f0576586e824af07d9c61f4630ee4798e11
```

### Extracting image names for a specific version

To get the exact list of images for a different version, you can use this one-liner:

```shell
export VERSION=v5.2.3.5
curl -s https://raw.githubusercontent.com/openshift-storage-scale/openshift-fusion-access-operator/refs/heads/main/files/${VERSION}/install.yaml | grep -i -e "icr.io" -e "quay.io" | awk '{ print "  - name: "  $2 }' | sort -u
```

### Applying the mirrored configuration

After mirroring, apply the generated `CatalogSource`, `ImageContentSourcePolicy` (or `ImageDigestMirrorSet`), and `ImageTagMirrorSet` as usual.

### Important: Internal Registry for Kernel Module Builds

IBM Fusion Access for SAN uses KMM to build kernel modules on the fly. In a disconnected environment, you **must** provide a registry where KMM can push the newly built images and where the nodes can pull them from.

Refer to the [Configure external registry for kernel module container image](#optional-configure-external-registry-for-kernel-module-container-image) section for details on how to set this up. In a disconnected environment, this "external" registry would be your local/internal registry (e.g., Quay, Harbor, or the OpenShift integrated registry).

### Install IBM Fusion Access for SAN operator

<https://www.ibm.com/docs/en/fusion-software/2.12.0?topic=san-installing-fusion-access-operator>

Do **NOT** create the `FusionAccess` custom resource yet!

At this point there is a [YouTube video](https://www.youtube.com/watch?v=ayXgD4e61K4) available that does not cover Secure Boot or an external registry.

![](operatorhub.png)

### Create a pull secret with IBM Entitlement Key

You can get/review the entitlement keys at the [IBM Container library](https://myibm.ibm.com/products-services/containerlibrary)

```shell
oc create secret -n ibm-fusion-access generic fusion-pullsecret \
--from-literal=ibm-entitlement-key=<ibm-entitlement-key>
```

### If Secure Boot is enabled: provide signing key

Create the key pair in the earlier section [If Secure Boot is enabled: Create and roll out your signing key](#if-secure-boot-is-enabled-create-and-roll-out-your-signing-key), then create the following secrets:

* Private key

    ```shell
    oc create secret generic secureboot-signing-key \
      -n ibm-fusion-access \
      --from-file=key=sb_cert.priv
    ```

* Public key

    ```shell
    oc create secret generic secureboot-signing-key-pub \
      -n ibm-fusion-access \
      --from-file=cert=sb_cert.cer
    ```

### Optional: Configure external registry for kernel module container image

* Create ConfigMap with external registry information:

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kmm-image-config
      namespace: ibm-fusion-access
    data:
      kmm_image_registry_url: quay.io
      kmm_image_repo: rbohne/kernel-ibm-fusion-access
      # kmm_tls_insecure: "false"
      # kmm_tls_skip_verify: "false"

      # Contains the Red Hat pull secret and the secret used to push
      kmm_image_registry_secret_name: rbohne-robot-kernel-ibm-fusion-access-pull-secret
    ```

* Provide push secret to quay.io

    ```yaml hl_lines="10"
    apiVersion: v1
    kind: Secret
    metadata:
    name: rbohne-robot-kernel-ibm-fusion-access-pull-secret
    namespace: ibm-fusion-access
    stringData:
    .dockerconfigjson: |
        {
        "auths": {
            "quay.io/rbohne/kernel-ibm-fusion-access": {
            "auth": "...",
            "email": "..."
            }
        }
        }
    type: kubernetes.io/dockerconfigjson
    ```

    !!! note

        It's important to be as specific as possible here. If I only specify quay.io, the pull secret will also be used for pulling OpenShift images, which will then cause the build to fail.

### Creating the `FusionAccess` custom resource

<https://www.ibm.com/docs/en/fusion-software/2.12.0?topic=san-creating-fusionaccess-cr>

Wait until the Web Console plugin is available to create the storage cluster.

![](create-storage-cluster.png)

### Creating a storage cluster

<https://www.ibm.com/docs/en/fusion-software/2.12.0?topic=san-creating-storage-cluster>

After creating the storage cluster, it's building the kernel module container image. Check builds in ibm-fusion-access project.

Check the pods in the following projects:

* `ibm-fusion-access`
* `ibm-spectrum-scale`

To check which devices are found, you can run:

```shell
oc describe LocalVolumeDiscoveryResult -n ibm-fusion-access
```

Or check the pod logs of the following pods:

```shell
oc get pods -l app=devicefinder-discovery -o wide -n ibm-fusion-access
```

To check the kernel module build settings, look at:

```shell
oc get module -n ibm-fusion-access gpfs-module -o yaml
```

Here's an example:

```yaml hl_lines="23 27-36"
apiVersion: kmm.sigs.x-k8s.io/v1beta1
kind: Module
metadata:
  finalizers:
    - kmm.node.kubernetes.io/module-finalizer
  name: gpfs-module
  namespace: ibm-fusion-access
spec:
  imageRepoSecret:
    name: kmm-registry-push-pull-secret
  moduleLoader:
    container:
      imagePullPolicy: Always
      inTreeModuleToRemove: ''
      kernelMappings:
        - build:
            baseImageRegistryTLS: {}
            buildArgs:
              - name: IBM_SCALE
                value: 'cp.icr.io/cp/gpfs/ibm-spectrum-scale-core-init@sha256:51dc287dd9ae2f8dcb60c1678fe8b535bb72e29faad24108d55b7cfe62362777'
            dockerfileConfigMap:
              name: kmm-dockerfile
          containerImage: 'quay.io/rbohne/kernel-ibm-fusion-access:${KERNEL_FULL_VERSION}-51dc287dd9ae2f8dcb60c1678fe8b535'
          inTreeModuleToRemove: ''
          literal: ''
          regexp: ^.*\.x86_64$
          sign:
            certSecret:
              name: secureboot-signing-key-pub
            filesToSign:
              - '/opt/lib/modules/${KERNEL_FULL_VERSION}/mmfslinux.ko'
              - '/opt/lib/modules/${KERNEL_FULL_VERSION}/mmfs26.ko'
              - '/opt/lib/modules/${KERNEL_FULL_VERSION}/tracedev.ko'
            keySecret:
              name: secureboot-signing-key
            unsignedImageRegistryTLS: {}
      modprobe:
        dirName: /opt
        firmwarePath: /opt/lxtrace/
        moduleName: mmfs26
        modulesLoadingOrder:
          - mmfs26
          - mmfslinux
          - tracedev
      registryTLS: {}
    serviceAccountName: fusion-access-operator-controller-manager
  selector:
    kubernetes.io/arch: amd64
    scale.spectrum.ibm.com/role: storage
status:
  devicePlugin: {}
  moduleLoader:
    nodesMatchingSelectorNumber: 3
```

To watch the build logs:

```shell
oc get builds -n ibm-fusion-access -l node.kubernetes.io/module.name=gpfs-module -l app.kubernetes.io/name=kmm
```

After a successful build, the build objects disappear.

### Creating a filesystem

<https://www.ibm.com/docs/en/fusion-software/2.12.0?topic=san-creating-filesystem>

![](create-fs.png)

Check the details of the FileSystem if it takes too long.

In case you recognize the following message:

> Disk has Spectrum Scale filesystem data structures on it. Set the 'existingDataSkipVerify' spec-parameter of the LocalDisk 0x5000c500155a3456 to true if the disk should be formatted and re-used nevertheless.

Check the LocalDisk:

```shell
% oc get LocalDisk -n ibm-spectrum-scale
NAME                 TYPE   READY   USED    AVAILABLE   FILESYSTEM   SIZE   AGE
0x5000c500155a3456          False   False   Unknown                         26m
```

If you are sure the shared disk can be wiped, set `existingDataSkipVerify` to `true`:

```shell
oc patch LocalDisk -n ibm-spectrum-scale 0x5000c500155a3456 --type merge -p '{"spec":{"existingDataSkipVerify":true}}'
```

### Don't forget to review the IBM Fusion dashboard

![](dashboard-link.png)

![](dashboard.png)

## Notes for various lab environments

Add a shared disk to all worker nodes.

### Plain KVM environment

I deployed via [hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4).
Now let's add a shared LVM disk because everything is running on one node.

!!! info

    The following issue is related to Secure Boot:

    ```log
    I0105 18:25:24.083670 1 funcs_kmod.go:12] "Starting worker" logger="kmm-worker" version="" git commit=""
    I0105 18:25:24.083696 1 funcs_kmod.go:24] "Reading config" logger="kmm-worker" path="/etc/kmm-worker/config.yaml"
    I0105 18:25:24.083968 1 worker.go:77] "preparing firmware for loading" logger="kmm-worker" image directory="/tmp/opt/lxtrace" host mount directory="/var/lib/firmware"
    I0105 18:25:24.084219 1 modprobe.go:33] "Running modprobe" logger="kmm-worker" command="/usr/sbin/modprobe -vd /tmp/opt mmfs26"
    I0105 18:25:24.086346 1 cmdlog.go:70] "modprobe: ERROR: could not insert 'mmfs26': Key was rejected by service" logger="kmm-worker.modprobe.stderr"
    I0105 18:25:24.086394 1 cmdlog.go:70] "insmod /tmp/opt/lib/modules/5.14.0-570.72.1.el9_6.x86_64/tracedev.ko " logger="kmm-worker.modprobe.stdout"
    E0105 18:25:24.086679 1 cmdutils.go:11] "Fatal error" err="error while waiting on the command: exit status 1" logger="kmm-worker"
    ```

    Two options to solve:

    * Disable Secure Boot
    * Work with a KMM signing key / Machine Owner Key (MOK), documented above.

```shell
lvcreate -L1T -n fusion vg0
```

```shell
export CLUSTER_NAME=pluto
for node in ${CLUSTER_NAME}-compute-0  ${CLUSTER_NAME}-compute-1  ${CLUSTER_NAME}-compute-2 ; do
    virsh attach-disk $node /dev/mapper/vg0-fusion sdb --targetbus scsi --cache none --persistent --live --wwn 5000c500155a3456
done
```

### iSCSI & RHCOS

This is ugly as hell, but works for quick testing.

=== "Apply iSCSI helper"

    ```
    oc apply -f {{ page.canonical_url }}iscsi-helper.yaml
    ```

=== "iscsi-helper.yaml"

    ```yaml
    --8<-- "content/storage/ibm-fusion-access-san/iscsi-helper.yaml"
    ```
