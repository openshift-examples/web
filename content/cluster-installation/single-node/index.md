---
title: Single node installation
linktitle: Single Node (SNO)
description: Dual Stack (IPv6 + IPv4) Single Node installation
tags:
  - SNO
  - IPv6
---

# Some information

## Install tools

```bash
curl -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.8.2/openshift-install-linux-4.8.2.tar.gz
tar xzvf openshift-install-linux-4.8.2.tar.gz openshift-install
sudo install -m 655 -o root -g root openshift-install /usr/local/bin/
rm openshift-install-linux-4.8.2.tar.gz  openshift-install

curl -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.8.2/openshift-client-linux-4.8.2.tar.gz
tar xzvf openshift-client-linux-4.8.2.tar.gz oc kubectl
sudo install -m 655 -o root -g root {kubectl,oc} /usr/local/bin/
rm openshift-client-linux-4.8.2.tar.gz oc kubectl

curl -L -o coreos-installer https://mirror.openshift.com/pub/openshift-v4/clients/coreos-installer/latest/coreos-installer_amd64
sudo install -m 655 -o root -g root coreos-installer /usr/local/bin/
rm coreos-installer

curl -L -o butane https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane-amd64
sudo install -m 655 -o root -g root butane /usr/local/bin/
rm butane

```

## Installation


```yaml
mkdir skull
cat > skull/install-config.yaml <<EOF
apiVersion: v1
baseDomain: egmating.bohne.io   # <===  Add your base domain
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 1
metadata:
  name: skull                     # <===  Add your name
networking:
  machineNetwork:
  - cidr: 192.168.66.0/24
  - cidr: fd00:c0a8:42::/64       # <===
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  - cidr: fd00:10:128::/56        # <=== IPv6 Dual-Stack setup
    hostPrefix: 64                # <=== IPv6 Dual-Stack setup
  networkType: OVNKubernetes      # <=== Changed to OVNKubernetes because of IPv6 Dual-Stack
  serviceNetwork:
  - 172.30.0.0/16
  - fd00:172:16::/112             # <=== IPv6 Dual-Stack setup
platform:
  none: {}
bootstrapInPlace:                 # <===
  installationDisk: /dev/nvme0n1  # <===
fips: false
pullSecret: '{"auths":{"cloud...}}}'
sshKey: 'ssh-ed25519 AAAA...'
EOF
```

```bash
$ openshift-install --dir skull/ create single-node-ignition-config
INFO Consuming Install Config from target directory
WARNING Making control-plane schedulable by setting MastersSchedulable to true for Scheduler cluster settings
INFO Single-Node-Ignition-Config created in: skull and skull/auth
```

cat > dhcpv6.rcc <<EOF
variant: rhcos
version: 0.1.0
ignition:
  config:
    merge:
      - local: bootstrap-in-place-for-live-iso.ign
storage:
  files:
    - path: /etc/NetworkManager/conf.d/01-ipv6.conf
      contents:
        source: data:,%5Bconnection%5D%0Aipv6.dhcp-iaid%3Dmac%0Aipv6.dhcp-duid%3Dll
      mode: 420
      user:
        name: root
      overwrite: true
EOF


butane \
  --files-dir skull/ \
  --output iso.ign \
  dhcpv6.rcc

curl -L -O https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.8/4.8.2/rhcos-live.x86_64.iso

coreos-installer iso ignition embed --ignition-file iso.ign  -o skull.iso rhcos-live.x86_64.iso

sudo dd if=skull.iso of=/dev/sda bs=1M status=progress
```