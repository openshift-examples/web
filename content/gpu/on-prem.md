# Install & use GPU on-prem

Official solution: [How to install the NVIDIA GPU Operator with OpenShift](https://access.redhat.com/solutions/4908611)

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


