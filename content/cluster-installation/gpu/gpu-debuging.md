---
title: GPU debugging
linktitle: GPU debugging
weight: 1610
description: Know Issues and debugging around gpu
tags:
  - GPU
---
# Know-Issues / Debugging

## ImagePullBackOff of nvidia-driver-daemonset-* pods

```
$ oc describe pods -l app=nvidia-driver-daemonset  | grep image
  Normal   Pulling         116s (x4 over 3m36s)  kubelet, compute-0  Pulling image "nvidia/driver:440.64.00-rhel8.2"
  Warning  Failed          112s (x4 over 3m31s)  kubelet, compute-0  Failed to pull image "nvidia/driver:440.64.00-rhel8.2": rpc error: code = Unknown desc = Error reading manifest 440.64.00-rhel8.2 in docker.io/nvidia/driver: manifest unknown: manifest unknown
  Normal   BackOff         86s (x6 over 3m31s)   kubelet, compute-0  Back-off pulling image "nvidia/driver:440.64.00-rhel8.2"
```

Double check if the image is available:
```
$ curl -s https://registry.hub.docker.com/v1/repositories/nvidia/driver/tags | jq -r ' .[] | .name' | grep rhel8
418.87.01--rhel8
418.87.01-4.18.0-80.11.2.el8_0.x86_64-rhel8
418.87.01-rhel8
440.33.01-1.0.0-custom-rhel8
440.33.01-4.18.0-80.11.2.el8_0.x86_64-rhel8
440.33.01-rhel8
440.64.00-1.0.0-custom-rhel8
440.64.00-1.0.0-rhel8
```

**Image is missing**

How the GPU operator build the Image tag:
1) All fields of `clusterpolicy.spec.driver`
2) OS Version of the node in case of OpenShift it use the node labels `feature.node.kubernetes.io/system-os_release.VERSION_ID` and `feature.node.kubernetes.io/system-os_release.ID` [Source](https://github.com/NVIDIA/gpu-operator/blob/master/pkg/controller/clusterpolicy/object_controls.go#L178-L196) If you like to check the node labels please run: `oc get nodes -L feature.node.kubernetes.io/system-os_release.VERSION_ID -L feature.node.kubernetes.io/system-os_release.ID`


### **Solution use a local image copy with matching tag**

Create local image copy with matching tag:
```bash
oc -n gpu-operator-resources import-image \
  nvidia-driver:440.64.00-rhel8.2 \
  --from=docker.io/nvidia/driver:440.64.00-rhcos4.5 \
  --reference-policy=local --confirm
```

Update the clusterpolicy/cluster-policy  `oc edit clusterpolicy/cluster-policy ` to
```yaml
spec:
...
  driver:
    image: nvidia-driver
    repository: image-registry.openshift-image-registry.svc:5000/gpu-operator-resources
    version: 440.64.00
...
```

## Error: Unable to find a match: kernel-headers-4.18.0-193.23.1.el8_2.x86_64 kernel-devel-4.18.0-193.23.1.el8_2.x86_64

The package [kernel-headers-4.18.0-193.23.1.el8_2.x86_64](https://access.redhat.com/downloads/content/kernel-headers/4.18.0-193.23.1.el8_2/x86_64/fd431d51/package)
 is only available in repo:
 * rhocp-4.5-for-rhel-8-x86_64-rpms
 * rhocp-4.3-for-rhel-8-x86_64-rpms

rhocp-4.5-for-rhel-8-x86_64-rpms

Try to install by hand:
```bash
$ oc debug nvidia-driver-daemonset-95bfc
Starting pod/nvidia-driver-daemonset-95bfc-debug, command was: nvidia-driver init
Pod IP: 10.131.0.24
If you don't see a command prompt, try pressing enter.
sh-4.4# dnf -q -y install kernel-headers-4.18.0-193.23.1.el8_2.x86_64 kernel-devel-4.18.0-193.23.1.el8_2.x86_64
Error: Unable to find a match: kernel-headers-4.18.0-193.23.1.el8_2.x86_64 kernel-devel-4.18.0-193.23.1.el8_2.x86_64
sh-4.4# dnf install --enablerepo=rhocp-4.5-for-rhel-8-x86_64-rpms -q -y kernel-headers-4.18.0-193.23.1.el8_2.x86_64 kernel-devel-4.18.0-193.23.1.el8_2.x86_6
sh-4.4#
```
Adding `--enablerepo=rhocp-4.5-for-rhel-8-x86_64-rpms` solve the problem, let's patch the driver image.

### **Patching driver image**

Fork the repo [https://gitlab.com/nvidia/container-images/driver](https://gitlab.com/nvidia/container-images/driver)

!!! warning
    This is the upstream version and will be different from the product.
    Might be hard to get it running.

Adjust the script `rhel8/nvidia-driver` in your fork.

Build the container image:
```bash
oc create -n gpu-operator-resources is/nvidia-driver
oc apply -n gpu-operator-resources -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: nvidia-driver
  labels:
    name: nvidia-driver
spec:
  triggers:
    - type: ConfigChange
  source:
    contextDir: "rhel8/"
    type: Git
    git:
      uri: https://gitlab.com/rbohne/driver.git
  strategy:
    type: Docker
    dockerStrategy:
      env:
      - name: DRIVER_VERSION
        value: 440.64.00
      buildArgs:
      - name: DRIVER_VERSION
        value: 440.64.00
  output:
    to:
      kind: ImageStreamTag
      name: 'nvidia-driver:440.64.00-rhel8.2'
EOF
```

Update the clusterpolicy/cluster-policy  `oc edit clusterpolicy/cluster-policy ` to
```yaml
spec:
...
  driver:
    image: nvidia-driver
    repository: image-registry.openshift-image-registry.svc:5000/gpu-operator-resources
    version: 440.64.00
...
```

### Problems with OCP >=4.4.11

 * [Enable OpenShift Extended Update Support](https://gitlab.com/nvidia/container-images/driver/-/issues/9)


From nvidia-driver-daemonset, from (Server Version: 4.4.12, 4.18.0-147.20.1.el8_1.x86_64):
```
...
Installing Linux kernel headers...
+ dnf -q -y install kernel-headers-4.18.0-147.20.1.el8_1.x86_64 kernel-devel-4.18.0-147.20.1.el8_1.x86_64
Error: Unable to find a match: kernel-headers-4.18.0-147.20.1.el8_1.x86_64 kernel-devel-4.18.0-147.20.1.el8_1.x86_64
...
```

| OpenShift Version | CoreOS Version | Kernel Version | Kernel Header available in repo |
|---|---|---|---|
|`4.4.5` |`44.81.202005180831-0`|`4.18.0-147.8.1.el8_1.x86_64`|[rhel-8-for-x86_64-baseos-rpms,...](https://access.redhat.com/downloads/content/kernel-headers/4.18.0-147.8.1.el8_1/x86_64/fd431d51/package)|
|`4.4.12`|`44.81.202007070223-0`|`4.18.0-147.20.1.el8_1.x86_64`|[rhel-8-for-x86_64-baseos-**eus**-rpms (8.1)](https://access.redhat.com/downloads/content/kernel-headers/4.18.0-147.8.1.el8_1/x86_64/fd431d51/package)|
|`4.5.2`|`45.82.202007141718-0`|`4.18.0-193.13.2.el8_2.x86_64`|[rhel-8-for-x86_64-baseos-rpms,...](https://access.redhat.com/downloads/content/kernel-headers/4.18.0-193.13.2.el8_2/x86_64/fd431d51/package)

Get OS Version of OpenShift Release
```
$ oc adm release info 4.5.3 -o jsonpath="{.displayVersions.machine-os.Version}"
45.82.202007171855-0
```

Red Hat Internal Links:
[OpenShift Release page](https://openshift-release.apps.ci.l2s4.p1.openshiftapps.com/releasestream/4-stable/release/4.5.3)
=> [45.82.202007171855-0]((https://releases-rhcos-art.cloud.privileged.psi.redhat.com/?release=45.82.202007171855-0&stream=releases%2Frhcos-4.5#45.82.202007171855-0))
=> [OS Content](https://releases-rhcos-art.cloud.privileged.psi.redhat.com/contents.html?stream=releases%2Frhcos-4.5&release=45.82.202007171855-0)


### Problems with OpenShift 4.5.x

**NVidia does not provide a suitable CoreOS driver image.**

