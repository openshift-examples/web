# Hetzner Lab notes


rsync --progress -e 'ssh -p23' --recursive <local_directory> <username>@<username>.your-storagebox.de:<target_directory>

rsync --progress -e 'ssh -p23' --recursive u221214-sub4@u221214-sub4.your-storagebox.de:homer/root/hetzner-ocp4 /root/


rsync --progress -e 'ssh -p23' --recursive u221214-sub4@u221214-sub4.your-storagebox.de:homer/images /var/lib/libvirt/images
## Resources

https://docs.hetzner.com/robot/storage-box/access/access-ssh-rsync-borg


