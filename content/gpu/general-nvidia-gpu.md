# General OpenShift & GPU Nodes

# Know-Issues

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

