---
title: NTP
linktitle: NTP
weight: 27100
description: Configure & test NTP
---
# NTP Server

## Usefull chrony commands

```bash
chronyc -a makestep
chronyc tracking
chronyc sources
```

## MachineConfig

!!! warning
    If you apply the machine config, all nodes will reboot one after the other.

```bash
chronybase64=$(cat << EOF | base64 -w 0
server <NTPSERVER> iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
)

oc apply -f - << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 50-worker-chrony
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${chronybase64}
        filesystem: root
        mode: 0644
        path: /etc/chrony.conf
EOF


oc apply -f - << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 50-master-chrony
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${chronybase64}
        filesystem: root
        mode: 0644
        path: /etc/chrony.conf
EOF
```