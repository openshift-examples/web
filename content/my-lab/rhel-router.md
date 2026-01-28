---
title: Routing with RHEL
linktitle: Routing with RHEL
description: Routing with RHEL
tags: ['rhel']
---

- [RHEL9 Router Installation](#rhel9-router-installation)
  - [`subscription-manager` Setup](#subscription-manager-setup)
  - [RHEL9 Router Installation - Network](#rhel9-router-installation---network)
  - [Enable IP Forwarding](#enable-ip-forwarding)
  - [Configure the Firewall](#configure-the-firewall)
  - [Setup DHCP Server](#setup-dhcp-server)

## RHEL9 Router Installation

- Installed basic RHEL9 VM on vSphere
  - set hostname
  - configure network
  - select installation source and destination
  - add a new user
    - set passwords

### `subscription-manager` Setup

If not already done during installation:

```code
subscription-manager register --org="" --activationkey=""
```

Checkt the repos:

```code
dnf repolist
Updating Subscription Management repositories.
repo id                                                                                   repo name
rhel-9-for-x86_64-appstream-rpms                                                          Red Hat Enterprise Linux 9 for x86_64 - AppStream (RPMs)
rhel-9-for-x86_64-baseos-rpms                                                             Red Hat Enterprise Linux 9 for x86_64 - BaseOS (RPMs)
```

- needed packages post-install:

```code
dnf install -y \
  dnsmasq \
  firewalld \
  tcpdump \
  bind-utils \
  vim
```

### RHEL9 Router Installation - Network

VM got configured with three vNICs. Each assigned to a specific Distributed Port-Group in vSphere:

```code
ip -br a

lo               UNKNOWN        127.0.0.1/8 ::1/128
ens33            UP             10.32.111.8/20 2620:52:0:2060:250:56ff:fe88:71f7/64 fe80::250:56ff:fe88:71f7/64
ens34            UP             192.168.202.10/24 fe80::2e60:26f7:eca5:3311/64
ens35            UP             192.168.204.10/24 fe80::4659:fe20:d534:9e48/64
```

`ens33` is connected to a DHCP network and has already got an IP assigned.

Network 2 and 3 will be static.

```code
nmcli con add type ethernet ifname ens34 con-name lan2 \
  ipv4.method manual ipv4.addresses 192.168.202.10/24
```

```code
nmcli con add type ethernet ifname ens35 con-name lan3 \
  ipv4.method manual ipv4.addresses 192.168.204.10/24
```

Activate ncs:

```code
nmcli con up lan2 && nmcli con up lan3
```

### Enable IP Forwarding

Enable IP Forwarding (Mandatory):

```code
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-router.conf \
sysctl --system
```

### Configure the Firewall

Configure Firewall and NAT (firewalld):

RHEL 9 uses nftables via firewalld.

```code
firewall-cmd --permanent --zone=external --add-interface=ens33
firewall-cmd --permanent --zone=internal --add-interface=ens34
firewall-cmd --permanent --zone=internal --add-interface=ens35
```

Enable Masquerading on WAN:

```code
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --permanent --zone=internal --add-masquerade
```

Allow Forwarding Between Zones:

```code
firewall-cmd --permanent --zone=internal --add-forward
```

Configure Policies accordingly:

```code
sudo firewall-cmd --permanent --new-policy=internal-external
sudo firewall-cmd --permanent --policy=internal-external --set-target=ACCEPT
sudo firewall-cmd --permanent --policy=internal-external --add-masquerade
sudo firewall-cmd --permanent --policy=internal-external --add-ingress-zone=internal
sudo firewall-cmd --permanent --policy=internal-external --add-egress-zone=external
sudo firewall-cmd --reload
```

```code
firewall-cmd --reload
```

### Setup DHCP Server

Install and Configure DHCP (dnsmasq). `dnsmasq` is lightweight and ideal for this role.

```code
dnf install -y dnsmasq
```

Configuration

Edit `/etc/dnsmasq.d/router.conf`:

```code
# Network 2
interface=ens34
dhcp-range=ens34,192.168.202.100,192.168.202.150,12h
dhcp-option=ens34,option:router,192.168.202.10
dhcp-option=ens34,option:dns-server,10.32.96.1

# Network 3
interface=ens35
dhcp-range=ens35,192.168.204.100,192.168.204.150,12h
dhcp-option=ens35,option:router,192.168.204.10
dhcp-option=ens35,option:dns-server,10.32.96.1
```

Start and Enable:

```code
systemctl enable --now dnsmasq
```

The leases can be read using `tail -f /var/lib/dnsmasq/dnsmasq.leases`.

Firewall: Allow DHCP Traffic:

```code
firewall-cmd --permanent --zone=internal --add-service=dhcp
firewall-cmd --reload
```
