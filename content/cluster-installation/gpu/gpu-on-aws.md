---
title: GPU on AWS
linktitle: GPU on AWS
weight: 1600
description: How to install GPU cluster on AWS
tags:
  - GPU
---
# Install & use GPU on AWS

Tested with OpenShift 4.4.5 at region `eu-central-1`

## Install OpenShift 4 on AWS

Follow the OpenShift [documentation](https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-aws-account.html).

!!! note
    Choose a region where GPUs are available.

## Create machineset with an GPU

You can create a new machineset as [documented](https://docs.openshift.com/container-platform/4.4/machine_management/creating_machinesets/creating-machineset-aws.html) or copy an existing one.

I use an existing one (required jq):

### Prepare new machineset with gpu

```bash
# Select the first machineset
SOURCE_MACHINESET=$(oc get machineset -n openshift-machine-api -o name | head -n1)

# Reformat with jq, for better diff result.
oc get -o json -n openshift-machine-api $SOURCE_MACHINESET  | jq -r > /tmp/source-machineset.json

OLD_MACHINESET_NAME=$(jq '.metadata.name' -r /tmp/source-machineset.json )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/worker-gpu}

# Change instanceType and delete some stuff
jq -r '.spec.template.spec.providerSpec.value.instanceType = "p3.2xlarge"
  | del(.metadata.selfLink)
  | del(.metadata.uid)
  | del(.metadata.creationTimestamp)
  | del(.metadata.resourceVersion)
  ' /tmp/source-machineset.json > /tmp/gpu-machineset.json

# Change machineset name
sed -i "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" /tmp/gpu-machineset.json

# Check changes via diff
diff -Nuar /tmp/source-machineset.json /tmp/gpu-machineset.json
```

### Example diff
```diff
--- /tmp/source-machineset.json 2020-06-04 07:25:20.590127131 +0200
+++ /tmp/gpu-machineset.json    2020-06-04 07:29:30.422321768 +0200
@@ -2,23 +2,19 @@
   "apiVersion": "machine.openshift.io/v1beta1",
   "kind": "MachineSet",
   "metadata": {
-    "creationTimestamp": "2020-06-04T04:36:57Z",
     "generation": 1,
     "labels": {
       "machine.openshift.io/cluster-api-cluster": "demo-zwgq6"
     },
-    "name": "demo-zwgq6-worker-eu-central-1a",
-    "namespace": "openshift-machine-api",
-    "resourceVersion": "15003",
-    "selfLink": "/apis/machine.openshift.io/v1beta1/namespaces/openshift-machine-api/machinesets/demo-zwgq6-worker-eu-central-1a",
-    "uid": "168f3805-e1dc-4cc1-984a-a9000a5f037a"
+    "name": "demo-zwgq6-worker-gpu-eu-central-1a",
+    "namespace": "openshift-machine-api"
   },
   "spec": {
     "replicas": 1,
     "selector": {
       "matchLabels": {
         "machine.openshift.io/cluster-api-cluster": "demo-zwgq6",
-        "machine.openshift.io/cluster-api-machineset": "demo-zwgq6-worker-eu-central-1a"
+        "machine.openshift.io/cluster-api-machineset": "demo-zwgq6-worker-gpu-eu-central-1a"
       }
     },
     "template": {
@@ -28,7 +24,7 @@
           "machine.openshift.io/cluster-api-cluster": "demo-zwgq6",
           "machine.openshift.io/cluster-api-machine-role": "worker",
           "machine.openshift.io/cluster-api-machine-type": "worker",
-          "machine.openshift.io/cluster-api-machineset": "demo-zwgq6-worker-eu-central-1a"
+          "machine.openshift.io/cluster-api-machineset": "demo-zwgq6-worker-gpu-eu-central-1a"
         }
       },
       "spec": {
@@ -57,7 +53,7 @@
             "iamInstanceProfile": {
               "id": "demo-zwgq6-worker-profile"
             },
-            "instanceType": "m4.large",
+            "instanceType": "p3.2xlarge",
             "kind": "AWSMachineProviderConfig",
             "metadata": {
               "creationTimestamp": null
```

### Create machine set

```bash
oc create -f /tmp/gpu-machineset.json
```

**Wait until node is available...**

## Entitle your openshift cluster

If not you run into: [Bug 1835446 - Special resource operator gpu-driver-container pod error related to elfutils-libelf-devel](https://bugzilla.redhat.com/show_bug.cgi?id=1835446)

These instructions assume you downloaded an entitlement encoded in base64 from access.redhat.com or extracted it from an existing node.

In the following commands, the entitlement certificate is copied to nvidia.pem, but it can be copied to any accessible location.
```bash
# On RHEL8 machine pick entitlement from  /etc/pki/entitlement/
# If you like to check the entitlement rct cat-cert /etc/pki/entitlement/xxx.pem

cat /etc/pki/entitlement/xxxxxx*.pem > nvidia.pem

curl -O  https://raw.githubusercontent.com/openshift-psap/blog-artifacts/master/how-to-use-entitled-builds-with-ubi/0003-cluster-wide-machineconfigs.yaml.template

sed -i -f - 0003-cluster-wide-machineconfigs.yaml.template << EOF
s/BASE64_ENCODED_PEM_FILE/$(base64 -w0 nvidia.pem)/g
EOF

oc apply -f 0003-cluster-wide-machineconfigs.yaml.template
```
[Based on nvidia docs](https://docs.nvidia.com/datacenter/kubernetes/openshift-on-gpu-install-guide/index.html#openshift-gpu-install-gpu-operator-via-helmv3)

### Wait for machineconfigpool is updated
```
oc wait --timeout=1800s --for=condition=Updated machineconfigpool/worker
# or check via oc get
oc get machineconfigpool/worker
```


## Install NVIDIA Gpu Operator

NVIDIA Documentation: [OpenShift on NVIDIA GPU Accelerated Clusters](https://docs.nvidia.com/datacenter/kubernetes/openshift-on-gpu-install-guide/index.html)



### Create new project/namespace
```
oc new-project gpu-operator-resources
```

### Install Operators

Actions:

 * Install NVIDIA Operator (installs the Node Feature Discovery operator as a dependency.)
 * Instantiate Node Feature Discovery Operator

<center>
<iframe width="784" height="441" src="https://www.youtube-nocookie.com/embed/C7o96ph4f0k" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

### Instantiate NVIDIA Gpu Operator

```bash
oc apply -f - <<EOF
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: cluster-policy
spec:
  dcgmExporter:
    image: dcgm-exporter
    repository: nvidia
    version: 1.7.2-2.0.0-rc.11-ubi8
  devicePlugin:
    image: k8s-device-plugin
    repository: nvidia
    version: 1.0.0-beta6-ubi8
  driver:
    image: driver
    repository: nvidia
    version: 440.64.00
  operator:
    defaultRuntime: crio
  toolkit:
    image: container-toolkit
    repository: nvidia
    version: 1.0.2-ubi8
EOF
```

### Check if all pods are running or completed

```bash
$ oc get pods
NAME                                       READY   STATUS      RESTARTS   AGE
gpu-operator-76d9bd6c65-7782f              1/1     Running     0          33m
nfd-master-jkdmw                           1/1     Running     0          81m
nfd-master-l82dp                           1/1     Running     0          81m
nfd-master-sdggd                           1/1     Running     0          81m
nfd-operator-684fcd5c8d-p7qcc              1/1     Running     0          82m
nfd-worker-6btp5                           1/1     Running     0          81m
nfd-worker-ch56g                           1/1     Running     0          81m
nfd-worker-jc572                           1/1     Running     1          81m
nfd-worker-llggg                           1/1     Running     0          81m
nvidia-container-toolkit-daemonset-jbv2b   1/1     Running     0          82m
nvidia-dcgm-exporter-mfnb9                 1/1     Running     0          2m23s
nvidia-device-plugin-daemonset-wdfhq       1/1     Running     0          82m
nvidia-device-plugin-validation            0/1     Completed   0          18m
nvidia-driver-daemonset-2tzpb              1/1     Running     0          29m
nvidia-driver-validation                   0/1     Completed   0          32m
```

!!! note
    Pod `nvidia-device-plugin-validation` stuck in Pending, problem was my gpu node had no capacity nvidia.com/gpu.
    A reboot of the node helped.

    `oc debug node/...`

    `chroot /host`

    `reboot`




## Run test workload

```bash
$ oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nvidia-smi
spec:
  containers:
  - image: nvidia/cuda
    name: nvidia-smi
    command: [ nvidia-smi ]
    resources:
      limits:
        nvidia.com/gpu: 1
      requests:
        nvidia.com/gpu: 1
EOF

$ oc logs nvidia-smi
Thu Jun  4 07:24:52 2020
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 440.64.00    Driver Version: 440.64.00    CUDA Version: 10.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  On   | 00000000:00:1E.0 Off |                    0 |
| N/A   32C    P0    24W / 300W |      0MiB / 16160MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+

```






