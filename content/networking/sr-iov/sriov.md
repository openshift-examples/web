


https://github.com/openshift/app-netutil/tree/master/samples/dpdk_app/sriov



```
oc get sriovnetworknodestates.sriovnetwork.openshift.io/storm5-10g.ocp5.stormshift.coe.muc.redhat.com -o yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodeState
metadata:
  creationTimestamp: "2022-02-04T15:47:10Z"
  generation: 2
  name: storm5-10g.ocp5.stormshift.coe.muc.redhat.com
  namespace: openshift-sriov-network-operator
  ownerReferences:
  - apiVersion: sriovnetwork.openshift.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: SriovNetworkNodePolicy
    name: default
    uid: 28a1d113-c809-4e49-9ae8-1c315b548375
  resourceVersion: "1415300823"
  uid: 12ca11b3-30b5-4b17-b219-257d023c8d49
spec:
  dpConfigVersion: "1415276305"
  interfaces:
  - mtu: 1500
    name: eno4
    numVfs: 7
    pciAddress: "0000:01:00.3"
    vfGroups:
    - deviceType: vfio-pci
      mtu: 1500
      policyName: storm5
      resourceName: storm5
      vfRange: 0-6
status:
  interfaces:
  - deviceID: "1521"
    driver: igb
    linkSpeed: 1000 Mb/s
    linkType: ETH
    mac: 24:6e:96:5a:64:64
    mtu: 1500
    name: eno1
    pciAddress: "0000:01:00.0"
    totalvfs: 7
    vendor: "8086"
  - deviceID: "1521"
    driver: igb
    linkSpeed: 1000 Mb/s
    linkType: ETH
    mac: 24:6e:96:5a:64:65
    mtu: 1500
    name: eno2
    pciAddress: "0000:01:00.1"
    totalvfs: 7
    vendor: "8086"
  - deviceID: "1521"
    driver: igb
    linkSpeed: 1000 Mb/s
    linkType: ETH
    mac: 24:6e:96:5a:64:66
    mtu: 1500
    name: eno3
    pciAddress: "0000:01:00.2"
    totalvfs: 7
    vendor: "8086"
  - Vfs:
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:10.3"
      vendor: "8086"
      vfID: 0
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:10.7"
      vendor: "8086"
      vfID: 1
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:11.3"
      vendor: "8086"
      vfID: 2
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:11.7"
      vendor: "8086"
      vfID: 3
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:12.3"
      vendor: "8086"
      vfID: 4
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:12.7"
      vendor: "8086"
      vfID: 5
    - deviceID: "1520"
      driver: vfio-pci
      pciAddress: "0000:01:13.3"
      vendor: "8086"
      vfID: 6
    deviceID: "1521"
    driver: igb
    linkSpeed: 1000 Mb/s
    linkType: ETH
    mac: 24:6e:96:5a:64:67
    mtu: 1500
    name: eno4
    numVfs: 7
    pciAddress: "0000:01:00.3"
    totalvfs: 7
    vendor: "8086"
  - deviceID: "1528"
    driver: ixgbe
    linkSpeed: 10000 Mb/s
    linkType: ETH
    mac: a0:36:9f:e5:14:bc
    mtu: 9000
    name: enp132s0f0
    pciAddress: 0000:84:00.0
    totalvfs: 63
    vendor: "8086"
  - deviceID: "1528"
    driver: ixgbe
    linkSpeed: 10000 Mb/s
    linkType: ETH
    mac: a0:36:9f:e5:14:bc
    mtu: 9000
    name: enp132s0f1
    pciAddress: 0000:84:00.1
    totalvfs: 63
    vendor: "8086"
  syncStatus: Succeeded
  ```


```
oc apply -f SriovNetworkNodePolicy.yaml
Error from server (vendor/device 8086/1521 is not supported): error when creating "SriovNetworkNodePolicy.yaml": admission webhook "operator-webhook.sriovnetwork.openshift.io" denied the request: vendor/device 8086/1521 is not supported
```

 => Disable webhook:
```
oc patch sriovoperatorconfig default --type=merge \
  -n openshift-sriov-network-operator \
  --patch '{ "spec": { "enableOperatorWebhook": false } }'
```

```
sh-4.4# ethtool -i eno3
driver: igb
version: 4.18.0-305.30.1.el8_4.x86_64
firmware-version: 1.67, 0x80000faa, 19.5.12
expansion-rom-version:
bus-info: 0000:01:00.2
supports-statistics: yes
supports-test: yes
supports-eeprom-access: yes
supports-register-dump: yes
supports-priv-flags: yes

sh-4.4# ip link show dev eno3
5: eno3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 24:6e:96:5a:64:66 brd ff:ff:ff:ff:ff:ff
    vf 0     link/ether 0a:3f:85:3d:a9:5d brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    vf 1     link/ether 3a:10:db:21:c2:9f brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    vf 2     link/ether 8e:f4:5f:5c:09:52 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    vf 3     link/ether 5e:a1:54:68:99:2c brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    vf 4     link/ether 96:a8:0d:82:35:3c brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    vf 5     link/ether ba:15:a0:26:56:66 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    vf 6     link/ether 6a:10:12:1c:e7:da brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
sh-4.4# ip link set eno3 vf 0 state enable
RTNETLINK answers: Operation not supported
sh-4.4#




```




oc new-build --name=dpdk-app-centos \
  --to-docker=true \
  --context-dir=samples/dpdk_app/dpdk-app-centos/ \
  https://github.com/openshift/app-netutil.git





## DPDK ready

 * <https://access.redhat.com/solutions/5688941>

https://www.youtube.com/watch?v=wbL0ap9U4G4
https://docs.google.com/presentation/d/1cGGHuzxJakFCfYVSpxpMKGKXB8JsgUYZGo7UN6Vjr8c/edit#slide=id.g1110007820d_0_558
https://docs.openshift.com/container-platform/4.9/scalability_and_performance/cnf-create-performance-profiles.html


Message:               failed to find MCP with the node selector that matches labels "kubernetes.io/hostname=storm5-10g.ocp5.stormshift.coe.muc.redhat.com"

oc label node storm5-10g.ocp5.stormshift.coe.muc.redhat.com node-role.kubernetes.io/dpdk=
oc apply -f MCP-dpdk.yaml
oc apply -f PerformanceProfile-dpdk-ready.yaml



oc adm must-gather --image=registry.redhat.io/openshift4/performance-addon-operator-must-gather-rhel8:v4.9 --dest-dir=must-gather


