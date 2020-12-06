---
title: How to adjust the an RHEL CoreOS ISO
linktitle: Adjust RHCOS.ISO
weight: 1900
description: TBD
tags:
  - rhcos
---
# How to adjust the an RHEL CoreOS ISO

 * Download ISO from [rhcos-4.5.6-x86_64-installer.x86_64.iso](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.5/4.5.6/rhcos-4.5.6-x86_64-installer.x86_64.iso)

Run commands:
```bash

mount rhcos-4.5.6-x86_64-installer.x86_64.iso /mnt/
mkdir /tmp/rhcos
rsync -a /mnt/* /tmp/rhcos/
cd /tmp/rhcos
```
## Edit isolinux/isolinux.cfg

Example
```
label linux
  menu label ^$HOSTNAME
  kernel /images/vmlinuz
  append initrd=/images/initramfs.img nomodeset rd.neednet=1 coreos.inst=yes ip=$IP::$GW:$NM:$HOSTNAME.example.com:ens192:none nameserver=4.4.4.4 nameserver=8.8.8.8 coreos.inst.install_dev=sda coreos.inst.image_url=http://10.40.201.78:8080/rhcos-4.5.6-x86_64-metal.x86_64.raw.gz coreos.inst.ignition_url=http://10.40.201.78:8080/$HOSTNAME.ign
```

## Build ISO
```bash
genisoimage -U -A "RHCOS-x86_64" -V "RHCOS-x86_64" \
  -volset "RHCOS-x86_64" \
  -J -joliet-long -r -v -T -x ./lost+found \
  -o /tmp/rhcos-4.5.6-x86_64-installer-custom.x86_64.iso \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 \
  -boot-info-table -eltorito-alt-boot \
  -e images/efiboot.img -no-emul-boot .
```