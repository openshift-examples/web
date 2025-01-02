---
title: How to adjust the an RHEL CoreOS ISO
linktitle: Adjust RHCOS.ISO
weight: 1900
description: TBD
tags: ['rhcos', 'coreos']
render_macros: false
---
# How to adjust the an RHEL CoreOS ISO

Prerequisites

* [Red Hat CoreOS ISO](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/)
* [Latest coreos-installer](https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/coreos-installer/latest/)

## Prepare auto-install USB-Sticks including worker igntion

### Get worker ignition from running cluster

or use that one created from `openshift-install`

```bash
oc get -n openshift-machine-api \
  secrets/worker-user-data \
  -o go-template="{{ .data.userData | base64decode }}" \
  > worker.ign
```

### Create own rhcos iso

```bash
coreos-installer iso customize \
  --dest-device /dev/sda \
  --dest-ignition worker.ign \
  -o ready-to-install-at-sda.iso \
  rhcos-live.x86_64.iso
```

Option: double check ignition:

```bash
coreos-installer iso ignition show ready-to-install-at-sda.iso
```

### Prepare usb stick

```bash
dd if=ready-to-install-at-sda.iso of=/dev/$USB_DISK status=progress
```
