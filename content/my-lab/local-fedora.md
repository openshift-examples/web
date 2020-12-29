# My local fedora VM - with VirtualBox

## Install VirtualBox guest tools

```
dnf -y update kernel*
dnf -y install gcc kernel-devel kernel-headers dkms make bzip2 perl libxcrypt-compat
```

Attach VirtualBoxGuestAdditions ISO
```
mkdir /media/VirtualBoxGuestAdditions
mount -r /dev/cdrom /media/VirtualBoxGuestAdditions
```

Build
```
export KERN_DIR=/usr/src/kernels/$(uname -r )
cd /media/VirtualBoxGuestAdditions
./VBoxLinuxAdditions.run
reboot
```


## Setup Podman remote

Source https://www.redhat.com/sysadmin/podman-clients-macos-windows

#### On Fedora as root

Sadly I had some problems to run with podman.socket: Durring a long running build I got `Error: unexpected EOF` :-(

```bash
dnf -y install podman
systemctl --now podman.socket

podman --remote info
```

#### On MacOs

##### Install podman remote
```
cd ~/bin/

export PODMAN_VERSION=$(ssh -q fedora podman version -f json | jq -r '.Client.Version')
curl -L -O https://github.com/containers/podman/releases/download/v${PODMAN_VERSION}/podman-remote-release-darwin.zip
unzip podman-remote-release-darwin.zip podman

```
##### Setup connection

```bash
podman system connection add --identity ~/.ssh/id_ed25519 --port 1984 fedora root@127.0.0.1
```