




[core@morty-master-2-private ~]$ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
nvme1n1     259:0    0   477G  0 disk
nvme0n1     259:1    0   477G  0 disk
├─nvme0n1p1 259:2    0     1M  0 part
├─nvme0n1p2 259:3    0   127M  0 part
├─nvme0n1p3 259:4    0   384M  0 part
│ └─md126     9:126  0   384M  0 raid1 /boot
└─nvme0n1p4 259:5    0 476.4G  0 part
  └─md127     9:127  0 476.3G  0 raid1 /sysroot
[core@morty-master-2-private ~]$ cat /proc/mdstat
Personalities : [raid1]
md126 : active raid1 nvme0n1p3[0]
      393152 blocks super 1.0 [2/1] [U_]

md127 : active raid1 nvme0n1p4[0]
      499450176 blocks super 1.2 [2/1] [U_]
      bitmap: 4/4 pages [16KB], 65536KB chunk

unused devices: <none>
[core@morty-master-2-private ~]$



[root@morty-master-2-private ~]# sfdisk -d -uS /dev/nvme0n1  | sfdisk -L -uS /dev/nvme1n1
sfdisk: --Linux option is unnecessary and deprecated
Checking that no-one is using this disk right now ... OK

Disk /dev/nvme1n1: 477 GiB, 512110190592 bytes, 1000215216 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Created a new GPT disklabel (GUID: A603A5D9-6FC7-4EB4-B73C-94000AF99299).
/dev/nvme1n1p1: Created a new partition 1 of type 'BIOS boot' and of size 1 MiB.
/dev/nvme1n1p2: Created a new partition 2 of type 'EFI System' and of size 127 MiB.
/dev/nvme1n1p3: Created a new partition 3 of type 'Linux filesystem' and of size 384 MiB.
/dev/nvme1n1p4: Created a new partition 4 of type 'Linux filesystem' and of size 476.4 GiB.
/dev/nvme1n1p5: Done.

New situation:
Disklabel type: gpt
Disk identifier: A603A5D9-6FC7-4EB4-B73C-94000AF99299

Device           Start        End   Sectors   Size Type
/dev/nvme1n1p1    2048       4095      2048     1M BIOS boot
/dev/nvme1n1p2    4096     264191    260096   127M EFI System
/dev/nvme1n1p3  264192    1050623    786432   384M Linux filesystem
/dev/nvme1n1p4 1050624 1000215182 999164559 476.4G Linux filesystem

The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

[root@morty-master-2-private ~]# lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
nvme1n1     259:0    0   477G  0 disk
|-nvme1n1p1 259:6    0     1M  0 part
|-nvme1n1p2 259:7    0   127M  0 part
|-nvme1n1p3 259:8    0   384M  0 part
`-nvme1n1p4 259:9    0 476.4G  0 part
nvme0n1     259:1    0   477G  0 disk
|-nvme0n1p1 259:2    0     1M  0 part
|-nvme0n1p2 259:3    0   127M  0 part
|-nvme0n1p3 259:4    0   384M  0 part
| `-md126     9:126  0   384M  0 raid1 /boot
`-nvme0n1p4 259:5    0 476.4G  0 part
  `-md127     9:127  0 476.3G  0 raid1 /sysroot
[root@morty-master-2-private ~]#

[root@morty-master-2-private ~]# mdadm --manage /dev/md126 --add /dev/nvme1n1p3
mdadm: added /dev/nvme1n1p3

[root@morty-master-2-private ~]# mdadm --manage /dev/md127 --add /dev/nvme1n1p4
mdadm: added /dev/nvme1n1p4
[root@morty-master-2-private ~]# cat /proc/mdstat
Personalities : [raid1]
md126 : active raid1 nvme1n1p3[2] nvme0n1p3[0]
      393152 blocks super 1.0 [2/2] [UU]

md127 : active raid1 nvme1n1p4[2] nvme0n1p4[0]
      499450176 blocks super 1.2 [2/1] [U_]
      [>....................]  recovery =  0.0% (402048/499450176) finish=20.6min speed=402048K/sec
      bitmap: 4/4 pages [16KB], 65536KB chunk

unused devices: <none>
[root@morty-master-2-private ~]#


Boot loader?

[root@morty-master-2-private ~]# grub2-install /dev/nvme1n1
Installing for i386-pc platform.
grub2-install: error: cannot delete `/boot/grub2/i386-pc/syslinuxcfg.mod': Read-only file system.
[root@morty-master-2-private ~]# mount -o remount,rw /boot/
[root@morty-master-2-private ~]# grub2-install /dev/nvme1n1
Installing for i386-pc platform.
Installation finished. No error reported.
[root@morty-master-2-private ~]# mount -o remount,ro /boot/

