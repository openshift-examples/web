---
title: Networking
linktitle: Networking
weight: 14100
description: TBD
---
# Networking

## Create bridge on main interface

All nodes on which the configuration is executed are restarted.

```yaml
oc apply -f - <<EOF
apiVersion: nmstate.io/v1alpha1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br1-ens3-policy-workers
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ""
  desiredState:
    interfaces:
      - name: br1
        description: Linux bridge with ens3 as a port
        type: linux-bridge
        state: up
        ipv4:
          enabled: true
          dhcp: true
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: ens3
EOF
```

## Create Network Attachment Definition

```yaml
cat << EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: tuning-bridge-fixed
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br1
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "br1",
    "plugins": [
      {
        "type": "cnv-bridge",
        "bridge": "br1"
      },
      {
        "type": "cnv-tuning"
      }
    ]
  }'
EOF
```

## Debugging purpose

#### Create br1 via nmcli

```bash
nmcli con show --active
nmcli con add type bridge ifname br1 con-name br1
nmcli con add type bridge-slave ifname ens3 master br1
nmcli con modify br1 bridge.stp no
nmcli con down 'Wired connection 1'
nmcli con up br1
nmcli con mod br1 connection.autoconnect yes
nmcli con mod 'Wired connection 1' connection.autoconnect no
```


```bash
[root@compute-0 ~]# nmcli con show
NAME                UUID                                  TYPE      DEVICE
br1                 2ae82518-2ff3-4d49-b95c-fc8fbf029d48  bridge    br1
bridge-slave-ens3   faac459f-ce51-4ce9-8616-ea9d23aff675  ethernet  ens3
Wired connection 1  e158d160-1743-3b00-9f67-258849993562  ethernet  --
[root@compute-0 ~]# nmcli -f bridge con show br1
bridge.mac-address:                     --
bridge.stp:                             no
bridge.priority:                        32768
bridge.forward-delay:                   15
bridge.hello-time:                      2
bridge.max-age:                         20
bridge.ageing-time:                     300
bridge.group-forward-mask:              0
bridge.multicast-snooping:              yes
bridge.vlan-filtering:                  no
bridge.vlan-default-pvid:               1
bridge.vlans:                           --
[root@compute-0 ~]# ip a show dev ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br1 state UP group default qlen 1000
    link/ether 52:54:00:a8:34:0d brd ff:ff:ff:ff:ff:ff
[root@compute-0 ~]# ip a show dev br1
17: br1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 52:54:00:a8:34:0d brd ff:ff:ff:ff:ff:ff
    inet 192.168.52.13/24 brd 192.168.52.255 scope global dynamic noprefixroute br1
       valid_lft 3523sec preferred_lft 3523sec
    inet6 fe80::70f0:71c5:53ea:71ee/64 scope link noprefixroute
       valid_lft forever preferred_lft forever

```


## Connection problem with `kubevirt.io/allow-pod-bridge-network-live-migration` after live migration


### HCP Cluster sendling:

```bash
oc get nodes
NAME                      STATUS   ROLES    AGE   VERSION
sendling-d0c14274-6nbvl   Ready    worker   11d   v1.27.8+4fab27b
sendling-d0c14274-sz7rb   Ready    worker   11d   v1.27.8+4fab27b
```

<details>
  <summary>Ping check details node/sendling-d0c14274-6nbvl</summary>

```bash
oc debug node/sendling-d0c14274-6nbvl
Starting pod/sendling-d0c14274-6nbvl-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.128.8.133
If you don't see a command prompt, try pressing enter.
sh-4.4# ping www.google.de
PING www.google.de (172.253.62.94) 56(84) bytes of data.
64 bytes from bc-in-f94.1e100.net (172.253.62.94): icmp_seq=1 ttl=99 time=112 ms
64 bytes from bc-in-f94.1e100.net (172.253.62.94): icmp_seq=2 ttl=99 time=98.3 ms
^C
--- www.google.de ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 98.310/105.047/111.785/6.745 ms
sh-4.4# exit
exit

Removing debug pod ...
```
</details>

<details>
  <summary>Ping check details node/sendling-d0c14274-sz7rb</summary>

```bash
$ oc debug node/sendling-d0c14274-sz7rb
Starting pod/sendling-d0c14274-sz7rb-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.131.9.28
If you don't see a command prompt, try pressing enter.
sh-4.4# ping www.google.de
PING www.google.de (172.253.62.94) 56(84) bytes of data.
```
</details>


* Node sendling-d0c14274-**6nbvl** - Ping google ✅
* Node sendling-d0c14274-**sz7rb** - Ping google ❌


```bash

$ oc get pods -l kubevirt.io=virt-launcher -o wide -n rbohne-hcp-sendling
NAME                                          READY   STATUS      RESTARTS   AGE     IP             NODE                 NOMINATED NODE   READINESS GATES
virt-launcher-sendling-d0c14274-6nbvl-pb6zd   1/1     Running     0          6d2h    10.128.8.133   inf8                 <none>           1/1
virt-launcher-sendling-d0c14274-sz7rb-cw5vj   1/1     Running     0          3d20h   10.131.9.28    ucs-blade-server-1   <none>           1/1
virt-launcher-sendling-d0c14274-sz7rb-mbmv8   0/1     Completed   0          3d20h   10.131.9.28    ucs-blade-server-3   <none>           1/1
virt-launcher-sendling-d0c14274-sz7rb-nb25r   0/1     Completed   0          6d2h    10.131.9.28    ucs-blade-server-1   <none>           1/1
$
```

#### Checkout node routing:

Host subnets:
``` bash
$ oc get nodes -o custom-columns="NODE:.metadata.name,node-subnets:.metadata.annotations.k8s\.ovn\.org/node-subnets"
NODE                 node-subnets
...
inf8                 {"default":["10.131.8.0/21"]}
ucs-blade-server-1   {"default":["10.131.0.0/21"]}
ucs-blade-server-3   {"default":["10.130.8.0/21"]}
...

$ oc get pods -n openshift-ovn-kubernetes -o wide -l  app=ovnkube-node
NAME                 READY   STATUS    RESTARTS       AGE    IP             NODE                 NOMINATED NODE   READINESS GATES
...
ovnkube-node-9xt5n   8/8     Running   8              2d7h   10.32.96.101   ucs-blade-server-1   <none>           <none>
ovnkube-node-hhsx5   8/8     Running   8              2d7h   10.32.96.8     inf8                 <none>           <none>
ovnkube-node-qx9bh   8/8     Running   9 (2d6h ago)   2d7h   10.32.96.103   ucs-blade-server-3   <none>           <none>
...

$ oc exec -n openshift-ovn-kubernetes -c ovn-controller ovnkube-node-9xt5n -- ovn-nbctl lr-route-list ovn_cluster_router
IPv4 Routes
Route Table <main>:
             10.128.8.133                100.88.0.9 dst-ip
             10.129.8.107              10.129.8.107 dst-ip rtos-ucs-blade-server-1 ecmp
             10.129.8.107                100.88.0.8 dst-ip ecmp
             10.130.10.29              10.130.10.29 dst-ip rtos-ucs-blade-server-1
              10.131.8.41               10.131.8.41 dst-ip rtos-ucs-blade-server-1
              10.131.9.28               10.131.9.28 dst-ip rtos-ucs-blade-server-1 ecmp
              10.131.9.28                100.88.0.8 dst-ip ecmp
              10.131.9.44               10.131.9.44 dst-ip rtos-ucs-blade-server-1
               100.64.0.2                100.88.0.2 dst-ip
               100.64.0.3                100.88.0.3 dst-ip
               100.64.0.4                100.88.0.4 dst-ip
               100.64.0.5                100.64.0.5 dst-ip
               100.64.0.6                100.88.0.6 dst-ip
               100.64.0.8                100.88.0.8 dst-ip
               100.64.0.9                100.88.0.9 dst-ip
              100.64.0.10               100.88.0.10 dst-ip
            10.128.0.0/21                100.88.0.2 dst-ip
            10.128.8.0/21                100.88.0.6 dst-ip
           10.128.16.0/21               100.88.0.10 dst-ip
            10.129.0.0/21                100.88.0.3 dst-ip
            10.130.0.0/21                100.88.0.4 dst-ip
            10.130.8.0/21                100.88.0.8 dst-ip
            10.131.8.0/21                100.88.0.9 dst-ip
            10.128.0.0/14                100.64.0.5 src-ip

$ oc exec -n openshift-ovn-kubernetes -c ovn-controller ovnkube-node-hhsx5   -- ovn-nbctl lr-route-list ovn_cluster_router
IPv4 Routes
Route Table <main>:
             10.128.8.133              10.128.8.133 dst-ip rtos-inf8
             10.129.8.107                100.88.0.5 dst-ip ecmp
             10.129.8.107                100.88.0.8 dst-ip ecmp
             10.130.10.29                100.88.0.5 dst-ip
              10.131.8.41                100.88.0.5 dst-ip
              10.131.9.28                100.88.0.5 dst-ip ecmp
              10.131.9.28                100.88.0.8 dst-ip ecmp
              10.131.9.44                100.88.0.5 dst-ip
               100.64.0.2                100.88.0.2 dst-ip
               100.64.0.3                100.88.0.3 dst-ip
               100.64.0.4                100.88.0.4 dst-ip
               100.64.0.5                100.88.0.5 dst-ip
               100.64.0.6                100.88.0.6 dst-ip
               100.64.0.8                100.88.0.8 dst-ip
               100.64.0.9                100.64.0.9 dst-ip
              100.64.0.10               100.88.0.10 dst-ip
            10.128.0.0/21                100.88.0.2 dst-ip
            10.128.8.0/21                100.88.0.6 dst-ip
           10.128.16.0/21               100.88.0.10 dst-ip
            10.129.0.0/21                100.88.0.3 dst-ip
            10.130.0.0/21                100.88.0.4 dst-ip
            10.130.8.0/21                100.88.0.8 dst-ip
            10.131.0.0/21                100.88.0.5 dst-ip
            10.128.0.0/14                100.64.0.9 src-ip
$

$ oc exec -n openshift-ovn-kubernetes -c ovn-controller ovnkube-node-qx9bh -- ovn-nbctl lr-route-list ovn_cluster_router
IPv4 Routes
Route Table <main>:
             10.128.8.133                100.88.0.9 dst-ip
             10.129.8.107                100.88.0.5 dst-ip
             10.130.10.29                100.88.0.5 dst-ip
              10.131.8.41                100.88.0.5 dst-ip
              10.131.9.28                100.88.0.5 dst-ip
              10.131.9.44                100.88.0.5 dst-ip
               100.64.0.2                100.88.0.2 dst-ip
               100.64.0.3                100.88.0.3 dst-ip
               100.64.0.4                100.88.0.4 dst-ip
               100.64.0.5                100.88.0.5 dst-ip
               100.64.0.6                100.88.0.6 dst-ip
               100.64.0.8                100.64.0.8 dst-ip
               100.64.0.9                100.88.0.9 dst-ip
              100.64.0.10               100.88.0.10 dst-ip
            10.128.0.0/21                100.88.0.2 dst-ip
            10.128.8.0/21                100.88.0.6 dst-ip
           10.128.16.0/21               100.88.0.10 dst-ip
            10.129.0.0/21                100.88.0.3 dst-ip
            10.130.0.0/21                100.88.0.4 dst-ip
            10.131.0.0/21                100.88.0.5 dst-ip
            10.131.8.0/21                100.88.0.9 dst-ip
            10.128.0.0/14                100.64.0.8 src-ip


```



