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