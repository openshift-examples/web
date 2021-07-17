---
title: MachineConfig
linktitle: MachineConfig
description: Some infos about MachineConfig
tags:
  - MachineConfig
  - MCO
---

# Machine Config

## Force Machine Config

Inspired by <https://bugzilla.redhat.com/show_bug.cgi?id=1766513>


```bash
oc debug node/worker0 -- chroot /host touch /run/machine-config-daemon-force
```

## Pause rebooting

```bash
oc patch --type=merge --patch='{"spec":{"paused":true}}' machineconfigpool/master
```
