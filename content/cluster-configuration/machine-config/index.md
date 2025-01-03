---
title: MachineConfig
linktitle: MachineConfig
description: Some infos about MachineConfig
tags: ['MachineConfig', 'MCO']
---

# Machine Config

Create MachineConfig objects that modify files, systemd unit files, and other operating system features running on OpenShift Container Platform nodes. OpenShift Container Platform supports Ignition specification version 3.2. All new machine configs you create going forward should be based on Ignition specification version 3.2.

## Force Machine Config

Inspired by <https://bugzilla.redhat.com/show_bug.cgi?id=1766513>

```bash
oc debug node/worker0 -- chroot /host touch /run/machine-config-daemon-force
```

## Pause rebooting

```bash
oc patch --type=merge --patch='{"spec":{"paused":true}}' machineconfigpool/master
```
